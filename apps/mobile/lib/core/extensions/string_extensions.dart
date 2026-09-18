/// Shared extension helpers for the Presentation layer.
library;

extension MoneyTextExtension on String {
  /// Strips thousands separators before numeric parsing.
  String stripThousandsSeparators() => replaceAll(',', '');
}
