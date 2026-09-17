String formatAxisNumber(double value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();

  if (abs >= 1000000) {
    return '$sign${(abs / 1000000).toStringAsFixed(abs >= 10000000 ? 0 : 1)}M';
  }
  if (abs >= 1000) {
    return '$sign${(abs / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}K';
  }
  if (abs == abs.roundToDouble()) {
    return '$sign${abs.toInt()}';
  }
  return '$sign${abs.toStringAsFixed(2)}';
}

List<double> niceAxisTicks(double minValue, double maxValue, {int steps = 4}) {
  if (minValue == maxValue) {
    if (minValue == 0) return [0];
    return [0, minValue];
  }
  final range = maxValue - minValue;
  final step = range / steps;
  return List.generate(steps + 1, (i) => minValue + step * i);
}
