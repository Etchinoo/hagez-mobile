/// Mirrors the Prisma `BusinessCategory` enum (prisma/schema.prisma on the API).
enum BusinessCategory {
  restaurant,
  salon,
  court,
  gamingCafe,
  medical,
  carWash;

  static BusinessCategory fromJson(String value) => switch (value) {
        'restaurant' => BusinessCategory.restaurant,
        'salon' => BusinessCategory.salon,
        'court' => BusinessCategory.court,
        'gaming_cafe' => BusinessCategory.gamingCafe,
        'medical' => BusinessCategory.medical,
        'car_wash' => BusinessCategory.carWash,
        _ => throw ArgumentError('Unknown BusinessCategory: $value'),
      };

  String toJson() => switch (this) {
        BusinessCategory.restaurant => 'restaurant',
        BusinessCategory.salon => 'salon',
        BusinessCategory.court => 'court',
        BusinessCategory.gamingCafe => 'gaming_cafe',
        BusinessCategory.medical => 'medical',
        BusinessCategory.carWash => 'car_wash',
      };
}

/// Mirrors the Prisma `BookingStatus` enum.
enum BookingStatus {
  pendingPayment,
  confirmed,
  completed,
  cancelledByConsumer,
  cancelledByBusiness,
  noShow,
  disputed,
  expired;

  static BookingStatus fromJson(String value) => switch (value) {
        'pending_payment' => BookingStatus.pendingPayment,
        'confirmed' => BookingStatus.confirmed,
        'completed' => BookingStatus.completed,
        'cancelled_by_consumer' => BookingStatus.cancelledByConsumer,
        'cancelled_by_business' => BookingStatus.cancelledByBusiness,
        'no_show' => BookingStatus.noShow,
        'disputed' => BookingStatus.disputed,
        'expired' => BookingStatus.expired,
        _ => throw ArgumentError('Unknown BookingStatus: $value'),
      };
}
