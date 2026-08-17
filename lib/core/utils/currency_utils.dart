String formatMoney(num amount, {String currency = 'INR'}) {
  final value = amount.toDouble().toStringAsFixed(2);
  if (currency == 'INR') return '₹$value';
  return '$currency $value';
}
