const double defaultHourlyRate = 2;

int hoursOrFraction(DateTime startedAt, DateTime endedAt) {
  final elapsed = endedAt.difference(startedAt);
  if (elapsed <= Duration.zero) {
    return 1;
  }
  final hours = (elapsed.inMicroseconds / Duration.microsecondsPerHour).ceil();
  return hours < 1 ? 1 : hours;
}

double billedAmount(DateTime startedAt, DateTime endedAt, double hourlyRate) {
  final rate = hourlyRate > 0 ? hourlyRate : defaultHourlyRate;
  return hoursOrFraction(startedAt, endedAt) * rate;
}

double effectiveHourlyRate(double hourlyRate) =>
    hourlyRate > 0 ? hourlyRate : defaultHourlyRate;

String formatSoles(num amount) => 'S/ ${amount.toStringAsFixed(2)}';

String formatOccupiedDuration(DateTime startedAt, [DateTime? now]) {
  var elapsed = (now ?? DateTime.now()).difference(startedAt);
  if (elapsed.isNegative) {
    elapsed = Duration.zero;
  }
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes.remainder(60);
  if (hours > 0) {
    return '$hours h $minutes min';
  }
  if (elapsed.inMinutes < 1) {
    return 'menos de 1 min';
  }
  return '$minutes min';
}

String rateLabel(double hourlyRate) =>
    '${formatSoles(effectiveHourlyRate(hourlyRate))} / hora o fracción';
