import 'package:intl/intl.dart';

class MoneyFormatter {
  MoneyFormatter._();

  static final _currency = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );
  static final _decimal = NumberFormat('#,##0.###');

  static double roundMoney(num value) {
    return (value * 100).roundToDouble() / 100;
  }

  static String money(num value) => _currency.format(value);

  static String decimal(num value) => _decimal.format(value);
}
