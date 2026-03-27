import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _moneyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '',
    decimalDigits: 2,
  );

  static final DateFormat _dayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateInputFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String money(double value) => _moneyFormat.format(value).trim();

  static String shortDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) {
      return '-';
    }
    return _dayFormat.format(DateTime.parse(isoDate));
  }

  static String dateTime(String? isoDateTime) {
    if (isoDateTime == null || isoDateTime.isEmpty) {
      return '-';
    }
    return _dateTimeFormat.format(DateTime.parse(isoDateTime).toLocal());
  }

  static String asInputDate(DateTime date) => _dateInputFormat.format(date);
}

