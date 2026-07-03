import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/utils/money_format.dart';

void main() {
  group('MoneyFormat', () {
    test('format returns currency and two decimal places', () {
      expect(
        MoneyFormat.format(amountCents: 1500, currency: 'BRL'),
        'BRL 15.00',
      );
    });

    test('formatWithSymbol uses BRL symbol', () {
      expect(
        MoneyFormat.formatWithSymbol(amountCents: 250, currency: 'BRL'),
        'R\$ 2.50',
      );
    });

    test('symbolFor maps known currencies', () {
      expect(MoneyFormat.symbolFor('EUR'), '€');
      expect(MoneyFormat.symbolFor('USD'), '\$');
      expect(MoneyFormat.symbolFor('XYZ'), 'XYZ');
    });
  });
}
