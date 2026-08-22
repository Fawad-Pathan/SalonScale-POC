import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/scan_product_result.dart';

class ProductWebImage {
  const ProductWebImage({
    required this.imageUrl,
    required this.sourceLabel,
  });

  final String imageUrl;
  final String sourceLabel;
}

class ProductImageLookupService {
  ProductImageLookupService({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : client = client ?? http.Client();

  final http.Client client;
  final Duration timeout;

  static const _headers = {
    'User-Agent':
        'SalonScalePoC/0.1 (local Flutter inventory scanner; product image lookup)',
    'Accept': 'application/json',
  };

  Future<ProductWebImage?> lookup(ScanProductResult product) async {
    final queries = _queriesFor(product);
    for (final query in queries) {
      final openFacts = await _lookupOpenFacts(query);
      if (openFacts != null) {
        return openFacts;
      }
    }
    for (final query in queries) {
      final wiki = await _lookupWikimedia(query);
      if (wiki != null) {
        return wiki;
      }
    }
    return null;
  }

  List<String> _queriesFor(ScanProductResult product) {
    final name = product.confirmedName.trim();
    final brand = product.brand.trim();
    final queries = <String>[
      if (brand.isNotEmpty && !name.toLowerCase().contains(brand.toLowerCase()))
        '$brand $name',
      name,
    ];
    return queries
        .where((query) => query.trim().length > 2)
        .map((query) => query.replaceAll(RegExp(r'\s+'), ' ').trim())
        .toSet()
        .toList();
  }

  Future<ProductWebImage?> _lookupOpenFacts(String query) async {
    const hosts = [
      ('Open Beauty Facts', 'world.openbeautyfacts.org'),
      ('Open Food Facts', 'world.openfoodfacts.org'),
      ('Open Products Facts', 'world.openproductsfacts.org'),
    ];

    for (final (sourceLabel, host) in hosts) {
      final uri = Uri.https(host, '/cgi/search.pl', {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '5',
        'fields':
            'product_name,brands,image_front_url,image_url,image_front_small_url,image_small_url',
      });
      try {
        final response =
            await client.get(uri, headers: _headers).timeout(timeout);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          continue;
        }
        final products = decoded['products'];
        if (products is! List) {
          continue;
        }
        for (final item in products) {
          if (item is! Map) {
            continue;
          }
          final imageUrl = _readFirstUrl(item, const [
            'image_front_url',
            'image_url',
            'image_front_small_url',
            'image_small_url',
          ]);
          if (imageUrl != null) {
            return ProductWebImage(
              imageUrl: imageUrl,
              sourceLabel: sourceLabel,
            );
          }
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<ProductWebImage?> _lookupWikimedia(String query) async {
    try {
      final searchUri = Uri.https('en.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'list': 'search',
        'srsearch': query,
        'srlimit': '1',
        'origin': '*',
      });
      final search =
          await client.get(searchUri, headers: _headers).timeout(timeout);
      if (search.statusCode < 200 || search.statusCode >= 300) {
        return null;
      }
      final searchDecoded = jsonDecode(search.body);
      if (searchDecoded is! Map) {
        return null;
      }
      final results = (searchDecoded['query'] as Map?)?['search'];
      if (results is! List || results.isEmpty || results.first is! Map) {
        return null;
      }
      final title = (results.first as Map)['title']?.toString().trim();
      if (title == null || title.isEmpty) {
        return null;
      }

      final summaryUri = Uri.https(
        'en.wikipedia.org',
        '/api/rest_v1/page/summary/${Uri.encodeComponent(title)}',
      );
      final summary =
          await client.get(summaryUri, headers: _headers).timeout(timeout);
      if (summary.statusCode < 200 || summary.statusCode >= 300) {
        return null;
      }
      final summaryDecoded = jsonDecode(summary.body);
      if (summaryDecoded is! Map) {
        return null;
      }
      final thumbnail = summaryDecoded['thumbnail'];
      final original = summaryDecoded['originalimage'];
      final imageUrl = _readFirstUrl(
        {
          if (thumbnail is Map) 'thumbnail': thumbnail['source'],
          if (original is Map) 'original': original['source'],
        },
        const ['thumbnail', 'original'],
      );
      if (imageUrl == null) {
        return null;
      }
      return ProductWebImage(
        imageUrl: imageUrl,
        sourceLabel: 'Wikimedia',
      );
    } catch (_) {
      return null;
    }
  }

  String? _readFirstUrl(Map item, List<String> keys) {
    for (final key in keys) {
      final value = item[key]?.toString().trim();
      if (value != null &&
          (value.startsWith('https://') || value.startsWith('http://'))) {
        return value;
      }
    }
    return null;
  }
}
