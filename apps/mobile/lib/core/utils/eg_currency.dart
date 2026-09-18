import 'package:intl/intl.dart';

/// Single EGP formatting/parsing utility (Q-012, BR-REPORT-004).
///
/// Display format is pinned across the app: Western digits, thousands
/// separators, two decimals, Arabic label — e.g. `1,250.50 ج.م`.
/// Calculations always use numeric values; formatting is display-only.
class EgCurrency {
  const EgCurrency._();

  static final NumberFormat _format = NumberFormat('#,##0.00', 'en_US');
  static const String symbolAr = 'ج.م';

  /// Formats [amount] for display, e.g. `1,250.50 ج.م`.
  static String format(num amount) => '${_format.format(amount)} $symbolAr';

  /// Formats [amount] without the label for compact layouts (e.g. list rows
  /// that already show context).
  static String formatAmount(num amount) => _format.format(amount);

  /// Parses a machine-readable numeric string (no label, no separators).
  static num parse(String value) => num.parse(value);
}
