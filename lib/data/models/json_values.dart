Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object.');
  return Map<String, dynamic>.from(value);
}

int jsonInt(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : fallback;

double jsonDouble(Object? value) => value is num ? value.toDouble() : 0;

String? jsonString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value;
}
