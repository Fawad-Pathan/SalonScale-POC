import 'dart:math';

import '../../catalogue/models/salon_product.dart';
import '../models/detected_product.dart';
import '../models/scan_analysis_result.dart';

class ProductMatch {
  const ProductMatch({
    required this.product,
    required this.score,
    required this.reasons,
  });

  final SalonProduct product;
  final double score;
  final List<String> reasons;
}

class ProductMatcher {
  const ProductMatcher();

  ScanAnalysisResult refineAnalysis(
      ScanAnalysisResult result, List<SalonProduct> catalogue) {
    final warnings = [...result.warnings];
    final identifiable = <DetectedProduct>[];
    var skippedLowInformation = 0;
    for (final detected in result.detectedProducts) {
      if (_hasEnoughProductIdentity(detected)) {
        identifiable.add(detected);
      } else {
        skippedLowInformation++;
      }
    }
    if (skippedLowInformation > 0) {
      warnings.add(
        'Skipped $skippedLowInformation low-information detection(s) without a readable product identity.',
      );
    }

    final refined = identifiable.map((detected) {
      final match = findBestMatch(detected, catalogue);
      final productWarnings = [...detected.warnings];
      if (detected.recognitionConfidence < 0.6) {
        productWarnings
            .add('Low recognition confidence. Review before saving.');
      }
      if (match == null || match.score < 0.52) {
        productWarnings.add('No confident catalogue match found.');
        return detected.copyWith(
          clearMatchedProductId: true,
          catalogueMatchConfidence:
              min(detected.catalogueMatchConfidence, match?.score ?? 0),
          matchStatus: 'unmatched',
          warnings: productWarnings,
        );
      }
      final matchStatus =
          match.score >= 0.72 && detected.recognitionConfidence >= 0.62
              ? 'matched'
              : 'needs_review';
      if (matchStatus == 'needs_review') {
        productWarnings.add('Suggested catalogue match needs manual review.');
      }
      final normalizedName = _normalize(detected.detectedName);
      return detected.copyWith(
        matchedProductId: match.product.id,
        detectedName: detected.detectedName.isEmpty ||
                _genericProductNames.contains(normalizedName)
            ? match.product.name
            : detected.detectedName,
        brand: detected.brand.isEmpty ? match.product.brand : detected.brand,
        category: detected.category.isEmpty
            ? match.product.category
            : detected.category,
        packagingType: detected.packagingType.isEmpty
            ? match.product.packagingType
            : detected.packagingType,
        shadeCode: detected.shadeCode.isEmpty
            ? match.product.shadeCode
            : detected.shadeCode,
        catalogueMatchConfidence:
            _clamp01((detected.catalogueMatchConfidence + match.score) / 2),
        matchStatus: matchStatus,
        warnings: productWarnings,
      );
    }).toList();

    return result.copyWith(
      warnings: warnings,
      detectedProducts: mergeDuplicateDetections(refined),
    );
  }

  ProductMatch? findBestMatch(
      DetectedProduct detected, List<SalonProduct> catalogue) {
    ProductMatch? best;
    for (final product in catalogue) {
      final scored = _score(detected, product);
      if (best == null || scored.score > best.score) {
        best = scored;
      }
    }
    return best;
  }

  List<DetectedProduct> mergeDuplicateDetections(
      List<DetectedProduct> detections) {
    final merged = <String, DetectedProduct>{};
    for (final detection in detections) {
      final key = detection.matchedProductId?.isNotEmpty == true
          ? 'product:${detection.matchedProductId}'
          : 'visual:${_normalize(detection.brand)}:${_normalize(detection.detectedName)}:${_normalizeShade(detection.shadeCode)}:${_normalize(detection.packagingType)}';
      final existing = merged[key];
      if (existing == null) {
        merged[key] = detection;
      } else {
        merged[key] = existing.copyWith(
          quantity: existing.quantity + detection.quantity,
          recognitionConfidence: max(
              existing.recognitionConfidence, detection.recognitionConfidence),
          catalogueMatchConfidence: max(existing.catalogueMatchConfidence,
              detection.catalogueMatchConfidence),
          notes: [existing.notes, detection.notes]
              .where((note) => note.trim().isNotEmpty)
              .join(' '),
          warnings: {...existing.warnings, ...detection.warnings}.toList(),
        );
      }
    }
    return merged.values.toList();
  }

  bool _hasEnoughProductIdentity(DetectedProduct detected) {
    final brand = _normalize(detected.brand);
    final name = _normalize(detected.detectedName);
    if (name.isEmpty || _unknownIdentityValues.contains(name)) {
      return false;
    }

    final warningText = _normalize(
      '${detected.notes} ${detected.warnings.join(' ')}',
    );
    final textLooksUnreadable = warningText.contains('label unreadable') ||
        warningText.contains('text unreadable') ||
        warningText.contains('brand unreadable') ||
        warningText.contains('no readable text');

    if (_isGenericDescription(name)) {
      return false;
    }

    final matchedProductId = detected.matchedProductId?.trim();
    if (matchedProductId != null && matchedProductId.isNotEmpty) {
      return true;
    }

    if (_isKnownIdentityValue(brand)) {
      return !textLooksUnreadable || detected.recognitionConfidence >= 0.58;
    }

    final meaningfulTokens = name
        .split(' ')
        .where((token) => token.isNotEmpty)
        .where((token) => !_genericIdentityTokens.contains(token))
        .toList();
    if (meaningfulTokens.length >= 2) {
      return !textLooksUnreadable || detected.recognitionConfidence >= 0.72;
    }

    if (meaningfulTokens.length == 1 &&
        meaningfulTokens.single.length >= 4 &&
        detected.recognitionConfidence >= 0.72) {
      return !textLooksUnreadable;
    }

    return false;
  }

  bool _isGenericDescription(String normalizedName) {
    if (_genericProductNames.contains(normalizedName)) {
      return true;
    }

    final tokens = normalizedName
        .split(' ')
        .where((token) => token.isNotEmpty)
        .where((token) => !_connectorTokens.contains(token))
        .toList();
    if (tokens.isEmpty) {
      return true;
    }

    final genericCount =
        tokens.where((token) => _genericIdentityTokens.contains(token)).length;
    if (genericCount == tokens.length) {
      return true;
    }

    final hasContainerWord =
        tokens.any((token) => _containerIdentityTokens.contains(token));
    final hasOnlyAppearanceWords = tokens.every((token) =>
        _genericIdentityTokens.contains(token) ||
        _appearanceIdentityTokens.contains(token));
    return hasContainerWord && hasOnlyAppearanceWords;
  }

  ProductMatch _score(DetectedProduct detected, SalonProduct product) {
    var score = 0.0;
    final reasons = <String>[];
    final detectedShade = _normalizeShade(detected.shadeCode);
    final productShade = _normalizeShade(product.shadeCode);
    final detectedBrand = _normalize(detected.brand);
    final productBrand = _normalize(product.brand);
    final detectedPackage = _normalize(detected.packagingType);
    final productPackage = _normalize(product.packagingType);

    if (detected.matchedProductId != null &&
        detected.matchedProductId == product.id) {
      score += 0.42;
      reasons.add('AI supplied exact product id');
    }

    final nameScore = _similarity(
        _normalize(detected.detectedName), _normalize(product.name));
    score += nameScore * 0.22;
    if (nameScore > 0.74) {
      reasons.add('similar name');
    }

    final aliasScore = product.aliases
        .map((alias) =>
            _similarity(_normalize(detected.detectedName), _normalize(alias)))
        .fold<double>(0, (best, score) => max(best, score));
    score += aliasScore * 0.16;
    if (aliasScore > 0.74) {
      reasons.add('alias match');
    }

    if (detectedBrand.isNotEmpty && detectedBrand == productBrand) {
      score += 0.14;
      reasons.add('brand match');
    }

    if (detectedPackage.isNotEmpty && detectedPackage == productPackage) {
      score += 0.10;
      reasons.add('packaging match');
    }

    if (detectedShade.isNotEmpty && productShade.isNotEmpty) {
      if (detectedShade == productShade) {
        score += 0.30;
        reasons.add('shade code match');
      } else {
        score -= 0.24;
        reasons.add('shade code mismatch');
      }
    }

    if (_normalize(detected.category).isNotEmpty &&
        _normalize(detected.category) == _normalize(product.category)) {
      score += 0.06;
      reasons.add('category match');
    }

    return ProductMatch(
        product: product, score: _clamp01(score), reasons: reasons);
  }

  double _similarity(String left, String right) {
    if (left.isEmpty || right.isEmpty) {
      return 0;
    }
    if (left == right) {
      return 1;
    }
    final distance = _levenshtein(left, right);
    return 1 - distance / max(left.length, right.length);
  }

  int _levenshtein(String left, String right) {
    final matrix = List.generate(
        left.length + 1, (_) => List<int>.filled(right.length + 1, 0));
    for (var i = 0; i <= left.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= right.length; j++) {
      matrix[0][j] = j;
    }
    for (var i = 1; i <= left.length; i++) {
      for (var j = 1; j <= right.length; j++) {
        final cost = left[i - 1] == right[j - 1] ? 0 : 1;
        matrix[i][j] = min(
          min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost,
        );
      }
    }
    return matrix[left.length][right.length];
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizeShade(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '');
  }

  bool _isKnownIdentityValue(String value) {
    return value.isNotEmpty && !_unknownIdentityValues.contains(value);
  }

  double _clamp01(double value) => value.clamp(0, 1).toDouble();

  static const _unknownIdentityValues = {
    'unknown',
    'unclear',
    'unreadable',
    'not visible',
    'none',
    'n a',
    'na',
  };

  static const _genericProductNames = {
    'red can',
    'white can',
    'black can',
    'silver can',
    'green can',
    'blue can',
    'yellow can',
    'red bottle',
    'white bottle',
    'black bottle',
    'clear bottle',
    'dropper bottle',
    'white dropper bottle',
    'serum bottle',
    'plastic bottle',
    'tube',
    'bottle',
    'can',
    'box',
    'jar',
    'carton',
    'packet',
    'package',
    'container',
  };

  static const _genericIdentityTokens = {
    'red',
    'white',
    'black',
    'silver',
    'green',
    'blue',
    'yellow',
    'orange',
    'purple',
    'pink',
    'clear',
    'transparent',
    'small',
    'large',
    'tall',
    'short',
    'plastic',
    'glass',
    'metal',
    'paper',
    'dropper',
    'pump',
    'spray',
    'cap',
    'lid',
    'label',
    'bottle',
    'can',
    'box',
    'tube',
    'jar',
    'carton',
    'packet',
    'package',
    'container',
    'product',
    'item',
  };

  static const _connectorTokens = {
    'a',
    'an',
    'and',
    'or',
    'of',
    'with',
    'for',
    'the',
  };

  static const _appearanceIdentityTokens = {
    'red',
    'white',
    'black',
    'silver',
    'green',
    'blue',
    'yellow',
    'orange',
    'purple',
    'pink',
    'clear',
    'transparent',
    'small',
    'large',
    'tall',
    'short',
    'plastic',
    'glass',
    'metal',
    'paper',
  };

  static const _containerIdentityTokens = {
    'dropper',
    'pump',
    'spray',
    'cap',
    'lid',
    'label',
    'bottle',
    'can',
    'box',
    'tube',
    'jar',
    'carton',
    'packet',
    'package',
    'container',
    'product',
    'item',
  };
}
