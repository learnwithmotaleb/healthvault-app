/// Europe/Athens wall-clock helpers (EET UTC+2 / EEST UTC+3).
///
/// The API keeps provider slots, reminder times and "today" in Greek time,
/// so the app converts explicitly instead of relying on the phone timezone.
/// DST: from the last Sunday of March 01:00 UTC to the last Sunday of
/// October 01:00 UTC (EU rule).
class AthensTime {
  static DateTime _lastSunday(int year, int month) {
    final lastDay = DateTime.utc(year, month + 1, 0);
    return lastDay.subtract(Duration(days: lastDay.weekday % 7));
  }

  /// Offset of Athens from UTC at the given UTC instant.
  static Duration offsetAt(DateTime utc) {
    final u = utc.toUtc();
    final start = _lastSunday(u.year, 3).add(const Duration(hours: 1));
    final end = _lastSunday(u.year, 10).add(const Duration(hours: 1));
    final dst = !u.isBefore(start) && u.isBefore(end);
    return Duration(hours: dst ? 3 : 2);
  }

  /// Wall-clock time in Athens for a UTC instant (returned as a UTC-flagged
  /// DateTime whose fields are the Athens fields).
  static DateTime fromUtc(DateTime utc) {
    final u = utc.toUtc();
    return u.add(offsetAt(u));
  }

  /// Athens "now" (fields = Greek wall clock).
  static DateTime now() => fromUtc(DateTime.now().toUtc());

  /// UTC instant for an Athens wall-clock date + time.
  static DateTime toUtc(int year, int month, int day, int hour, int minute) {
    final naive = DateTime.utc(year, month, day, hour, minute);
    // Try the standard offset first, then verify (handles DST edges).
    var guess = naive.subtract(const Duration(hours: 2));
    final off = offsetAt(guess);
    guess = naive.subtract(off);
    if (offsetAt(guess) != off) guess = naive.subtract(offsetAt(guess));
    return guess;
  }

  /// "HH:mm" → minutes since midnight.
  static int minutesOf(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return 0;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  static String hhmm(int minutes) =>
      "${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}";

  /// True when the phone is not on Greek time (so labels should say "Greek time").
  static bool get deviceDiffers => DateTime.now().timeZoneOffset != offsetAt(DateTime.now().toUtc());
}
