import 'package:intl/intl.dart';

class SufraDateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  static String toDateKey(DateTime dateTime) => _dateFormat.format(dateTime);

  static String toDateTimeString(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime);

  static DateTime startOfDay(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  /// Move by calendar dates, not elapsed24h across daylight-saving changes.
  static DateTime shiftDays(DateTime dateTime, int days) => dateTime.isUtc
      ? DateTime.utc(dateTime.year, dateTime.month, dateTime.day + days)
      : DateTime(dateTime.year, dateTime.month, dateTime.day + days);

  static DateTime endOfDay(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
}
