String formatMoney({
  required int minorUnits,
  String currency = 'INR',
}) {
  final double major = minorUnits / 100;
  if (currency.toUpperCase() == 'INR') {
    final String formatted = major.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return '₹${major.toStringAsFixed(0)}';
    }
    return '₹$formatted';
  }
  return '$currency ${major.toStringAsFixed(2)}';
}
