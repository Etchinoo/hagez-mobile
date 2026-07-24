class Slot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int availableCapacity;
  final double depositAmount;
  final double effectiveDeposit;
  final String? pricingBadgeAr;

  const Slot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.availableCapacity,
    required this.depositAmount,
    required this.effectiveDeposit,
    this.pricingBadgeAr,
  });

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        id: json['id'] as String,
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        availableCapacity: json['available_capacity'] as int? ?? 0,
        depositAmount: (json['deposit_amount'] as num).toDouble(),
        effectiveDeposit: (json['effective_deposit'] as num?)?.toDouble() ??
            (json['deposit_amount'] as num).toDouble(),
        pricingBadgeAr: json['pricing_badge_ar'] as String?,
      );
}
