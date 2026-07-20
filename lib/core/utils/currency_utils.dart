String formatMoney(double amount, {String currency = 'INR'}) {
  if (currency == 'INR') {
    return '₹${amount.toStringAsFixed(0)}';
  }
  return '$currency ${amount.toStringAsFixed(2)}';
}
