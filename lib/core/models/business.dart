import 'business_category.dart';
import 'slot.dart';

/// A resource belonging to a business — staff (salon), court (court),
/// station (gaming_cafe), or bay (car_wash). Shape from GET /businesses/:id.
class BusinessResource {
  final String id;
  final String nameAr;
  final String? nameEn;
  final int capacity;
  final List<String> specialisations;

  const BusinessResource({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.capacity,
    required this.specialisations,
  });

  factory BusinessResource.fromJson(Map<String, dynamic> json) => BusinessResource(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String,
        nameEn: json['name_en'] as String?,
        capacity: json['capacity'] as int? ?? 1,
        specialisations: (json['specialisations'] as List?)?.cast<String>() ?? const [],
      );
}

/// Combined model for both the search-list item shape (GET /search/businesses)
/// and the detail shape (GET /businesses/:id) — detail-only fields are
/// nullable and populated only when fetched via [Business.detail].
class Business {
  final String id;
  final String nameAr;
  final String? nameEn;
  final BusinessCategory category;
  final String district;
  final double? ratingAvg; // null when is_new
  final int reviewCount;
  final bool isNew;
  final List<String> photos;

  // Detail-only fields
  final String? descriptionAr;
  final String? descriptionEn;
  final double? lat;
  final double? lng;
  final List<BusinessResource>? resources; // staff/courts/stations/bays, category-specific
  final Map<String, dynamic>? categoryConfig; // gaming_config/court_config/car_wash_config
  final List<Slot>? nextAvailableSlots;

  const Business({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.category,
    required this.district,
    this.ratingAvg,
    required this.reviewCount,
    required this.isNew,
    required this.photos,
    this.descriptionAr,
    this.descriptionEn,
    this.lat,
    this.lng,
    this.resources,
    this.categoryConfig,
    this.nextAvailableSlots,
  });

  factory Business.fromListJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String,
        nameEn: json['name_en'] as String?,
        category: BusinessCategory.fromJson(json['category'] as String),
        district: json['district'] as String,
        ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int? ?? 0,
        isNew: json['is_new'] as bool? ?? false,
        photos: (json['photos'] as List?)?.cast<String>() ?? const [],
      );

  factory Business.fromDetailJson(Map<String, dynamic> json) {
    final category = BusinessCategory.fromJson(json['category'] as String);
    final resourcesKey = switch (category) {
      BusinessCategory.salon => 'staff',
      BusinessCategory.court => 'courts',
      BusinessCategory.gamingCafe => 'stations',
      BusinessCategory.carWash => 'bays',
      _ => null,
    };
    final configKey = switch (category) {
      BusinessCategory.court => 'court_config',
      BusinessCategory.gamingCafe => 'gaming_config',
      BusinessCategory.carWash => 'car_wash_config',
      _ => null,
    };

    return Business(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String?,
      category: category,
      district: json['district'] as String,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int? ?? 0,
      isNew: json['is_new'] as bool? ?? false,
      photos: (json['photos'] as List?)?.cast<String>() ?? const [],
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      lat: (json['location']?['lat'] as num?)?.toDouble(),
      lng: (json['location']?['lng'] as num?)?.toDouble(),
      resources: resourcesKey != null
          ? ((json[resourcesKey] as List?) ?? const [])
              .map((r) => BusinessResource.fromJson(r as Map<String, dynamic>))
              .toList()
          : const [],
      categoryConfig: configKey != null ? json[configKey] as Map<String, dynamic>? : null,
      nextAvailableSlots: ((json['next_available_slots'] as List?) ?? const [])
          .map((s) => Slot.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
