/// Formats monetary amounts stored as integer cents.
class MoneyFormat {
  MoneyFormat._();

  static String format({
    required int amountCents,
    required String currency,
  }) {
    final major = amountCents / 100;
    return '$currency ${major.toStringAsFixed(2)}';
  }

  static String symbolFor(String currency) {
    return switch (currency.toUpperCase()) {
      'BRL' => 'R\$',
      'EUR' => '€',
      'USD' => '\$',
      _ => currency,
    };
  }

  static String formatWithSymbol({
    required int amountCents,
    required String currency,
  }) {
    final major = amountCents / 100;
    return '${symbolFor(currency)} ${major.toStringAsFixed(2)}';
  }
}
