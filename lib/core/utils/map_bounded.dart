import 'dart:math';

Future<List<R>> mapBounded<T, R>(
  Iterable<T> values,
  int concurrency,
  Future<R> Function(T value) convert,
) async {
  if (concurrency < 1) {
    throw ArgumentError.value(concurrency, 'concurrency', 'Must be positive.');
  }
  final input = values.toList(growable: false);
  final results = List<R?>.filled(input.length, null);
  var next = 0;

  Future<void> work() async {
    while (next < input.length) {
      final index = next++;
      results[index] = await convert(input[index]);
    }
  }

  await Future.wait([
    for (var i = 0; i < min(concurrency, input.length); i++) work(),
  ]);
  return results.cast<R>();
}
