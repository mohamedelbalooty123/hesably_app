import 'package:flutter_test/flutter_test.dart';
import 'package:hesably/core/utils/eg_currency.dart';

void main() {
  group('EgCurrency', () {
    test('formats whole amounts with separators, decimals and label', () {
      expect(EgCurrency.format(1250), '1,250.00 ج.م');
    });

    test('formats decimal amounts with two places', () {
      expect(EgCurrency.format(1250.5), '1,250.50 ج.م');
    });

    test('formats without label for compact layouts', () {
      expect(EgCurrency.formatAmount(1250.5), '1,250.50');
    });

    test('parses machine-readable numerics', () {
      expect(EgCurrency.parse('1250.50'), 1250.50);
    });
  });
}
