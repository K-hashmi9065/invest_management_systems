import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('dd-MMM-yyyy');
  static final DateFormat _displayWithTime = DateFormat('dd-MMM-yyyy hh:mm a');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-ddTHH:mm:ss');

  static String formatDate(DateTime date) {
    return _displayFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _displayWithTime.format(date);
  }

  static String toIso(DateTime date) {
    return _isoFormat.format(date);
  }

  static DateTime parseIso(String isoString) {
    return DateTime.parse(isoString);
  }
}
