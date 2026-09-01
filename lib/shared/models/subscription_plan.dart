/// Subscription SKU used by the paywall and payment screens.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.periodLabel,
    required this.pricePerMonthLabel,
    required this.billingLabel,
    required this.displayName,
    required this.subtotalLabel,
    required this.taxLabel,
    required this.totalLabel,
    this.bestValue = false,
  });

  final String id;
  final String name;
  final String periodLabel;
  final String pricePerMonthLabel;
  final String billingLabel;
  final String displayName;
  final String subtotalLabel;
  final String taxLabel;
  final String totalLabel;
  final bool bestValue;
}
