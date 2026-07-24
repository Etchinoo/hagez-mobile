import 'business_category.dart';

class BookingSlotSummary {
  final DateTime startTime;
  final DateTime endTime;

  const BookingSlotSummary({required this.startTime, required this.endTime});

  factory BookingSlotSummary.fromJson(Map<String, dynamic> json) => BookingSlotSummary(
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
      );
}

class BookingBusinessSummary {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String district;
  final BusinessCategory category;

  const BookingBusinessSummary({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.district,
    required this.category,
  });

  factory BookingBusinessSummary.fromJson(Map<String, dynamic> json) => BookingBusinessSummary(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String,
        nameEn: json['name_en'] as String?,
        district: json['district'] as String,
        category: BusinessCategory.fromJson(json['category'] as String),
      );
}

/// Covers both the GET /bookings list-item shape and the GET /bookings/:id
/// detail shape (payments/review/status_logs are ignored here for the MVP
/// screens — add as needed when the booking-detail screen needs them).
class Booking {
  final String id;
  final String bookingRef;
  final BookingStatus status;
  final int partySize;
  final String businessId;
  final BookingBusinessSummary? business;
  final BookingSlotSummary? slot;
  final double depositAmount;
  final double platformFee;
  final DateTime createdAt;

  // Gaming-specific (nullable — only present for gaming_cafe bookings)
  final String? stationType;
  final String? genrePreference;

  const Booking({
    required this.id,
    required this.bookingRef,
    required this.status,
    required this.partySize,
    required this.businessId,
    this.business,
    this.slot,
    required this.depositAmount,
    required this.platformFee,
    required this.createdAt,
    this.stationType,
    this.genrePreference,
  });

  double get totalAmount => depositAmount + platformFee;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        bookingRef: json['booking_ref'] as String,
        status: BookingStatus.fromJson(json['status'] as String),
        partySize: json['party_size'] as int? ?? 1,
        businessId: json['business_id'] as String,
        business: json['business'] != null
            ? BookingBusinessSummary.fromJson(json['business'] as Map<String, dynamic>)
            : null,
        slot: json['slot'] != null
            ? BookingSlotSummary.fromJson(json['slot'] as Map<String, dynamic>)
            : null,
        depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0,
        platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        stationType: json['station_type'] as String?,
        genrePreference: json['genre_preference'] as String?,
      );
}
