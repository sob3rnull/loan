import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _moneyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '',
    decimalDigits: 2,
  );

  static final DateFormat _shortDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _inputDateFormat = DateFormat('yyyy-MM-dd');

  static String money(double value) => _moneyFormat.format(value).trim();

  static String shortDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }
    return _shortDateFormat.format(DateTime.parse(value));
  }

  static String dateTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }
    return _dateTimeFormat.format(DateTime.parse(value).toLocal());
  }

  static String inputDate(DateTime date) => _inputDateFormat.format(date);
}
