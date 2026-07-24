class HagezUser {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String languagePref; // 'ar' | 'en'
  final String? profilePhotoUrl;

  const HagezUser({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    required this.languagePref,
    this.profilePhotoUrl,
  });

  factory HagezUser.fromJson(Map<String, dynamic> json) => HagezUser(
        id: json['id'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        fullName: json['full_name'] as String,
        languagePref: json['language_pref'] as String? ?? 'ar',
        profilePhotoUrl: json['profile_photo_url'] as String?,
      );
}
