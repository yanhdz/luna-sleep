import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  static String durationLong(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  static String timestamp(DateTime dt) =>
      DateFormat('h:mm a').format(dt);

  static String dateShort(DateTime dt) =>
      DateFormat('MMM d').format(dt);

  static String dateFull(DateTime dt) =>
      DateFormat('EEEE, MMMM d').format(dt);

  static String dateTime(DateTime dt) =>
      DateFormat('MMM d · h:mm a').format(dt);

  static String decibels(double db) =>
      '${db.abs().toStringAsFixed(0)} dB';

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }
}
