DateTime parseDateTime(dynamic value, {DateTime? fallback}) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ??
        fallback ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value != null) {
    try {
      final dynamic date = value;
      final converted = date.toDate();
      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Firestore Timestamp is supported through dynamic to avoid model-layer package coupling.
    }
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}

String readString(Map<String, dynamic> json, String key,
    {String fallback = ''}) {
  final value = json[key];
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

String? readNullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int readInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double readDouble(Map<String, dynamic> json, String key,
    {double fallback = 0}) {
  final value = json[key];
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool readBool(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return fallback;
}

List<String> readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) {
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  return const [];
}

List<Map<String, dynamic>> readMapList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}

Map<String, dynamic> mapFromDynamic(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}
