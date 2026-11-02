class CheckResult {
  const CheckResult({required this.available});

  final bool available;

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    final available = json['available'];
    if (available is! bool) {
      throw const FormatException('Missing v5 availability boolean.');
    }
    return CheckResult(available: available);
  }
}
