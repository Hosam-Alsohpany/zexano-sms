class SmsThrottleInterval {
  final Duration duration;

  const SmsThrottleInterval._(this.duration);

  static const Duration minDuration = Duration.zero;
  static const Duration maxDuration = Duration(seconds: 60);

  static SmsThrottleInterval? create(Duration input) {
    if (input < minDuration || input > maxDuration) return null;
    return SmsThrottleInterval._(input);
  }

  static SmsThrottleInterval fromSeconds(int seconds) {
    final clamped = seconds.clamp(minDuration.inSeconds, maxDuration.inSeconds);
    return SmsThrottleInterval._(Duration(seconds: clamped));
  }

  int get inSeconds => duration.inSeconds;

  static bool isValid(Duration input) {
    return input >= minDuration && input <= maxDuration;
  }

  static bool isValidSeconds(int seconds) {
    return seconds >= minDuration.inSeconds && seconds <= maxDuration.inSeconds;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SmsThrottleInterval && other.duration == duration);

  @override
  int get hashCode => duration.hashCode;

  @override
  String toString() => 'SmsThrottleInterval(${duration.inSeconds}s)';
}
