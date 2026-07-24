// ============================================================
// HAGEZ — Consumer-facing copy (Arabic primary, English secondary).
// Ported from the previous Expo app's i18n/{ar,en}.ts, rebranded from the
// legacy "Super Reservation" name to Hagez / حاجز.
//
// Simple nested-map approach (no ARB/intl codegen) — fast to wire up for an
// early-stage app. Access via: AppStrings.of(locale).common.loading
// ============================================================

class CommonStrings {
  const CommonStrings({
    required this.appName,
    required this.loading,
    required this.error,
    required this.retry,
    required this.confirm,
    required this.cancel,
    required this.save,
    required this.back,
    required this.close,
    required this.next,
    required this.egp,
    required this.viewAll,
  });
  final String appName, loading, error, retry, confirm, cancel, save, back, close, next, egp, viewAll;
}

class AuthStrings {
  const AuthStrings({
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.enterPhone,
    required this.phonePlaceholder,
    required this.sendOtp,
    required this.enterOtp,
    required this.otpSentTo,
    required this.otpPlaceholder,
    required this.verifyOtp,
    required this.resendOtp,
    required this.invalidOtp,
    required this.loginWithGoogle,
    required this.byProceeding,
    required this.termsOfService,
    required this.and,
    required this.privacyPolicy,
    required this.logout,
  });
  final String welcomeTitle,
      welcomeSubtitle,
      enterPhone,
      phonePlaceholder,
      sendOtp,
      enterOtp,
      otpSentTo,
      otpPlaceholder,
      verifyOtp,
      resendOtp,
      invalidOtp,
      loginWithGoogle,
      byProceeding,
      termsOfService,
      and,
      privacyPolicy,
      logout;

  String resendIn(int seconds) => and == 'and' ? 'Resend in ${seconds}s' : 'إعادة الإرسال خلال $seconds ثانية';
}

class HomeStrings {
  const HomeStrings({
    required this.greeting,
    required this.searchPlaceholder,
    required this.categories,
    required this.featuredTitle,
    required this.nearbyTitle,
    required this.noResults,
    required this.tryAdjustingFilters,
    required this.newBadge,
    required this.categoryLabel,
    required this.districtLabel,
    required this.ratingLabel,
    required this.allLabel,
    required this.clearFilters,
  });
  final String greeting,
      searchPlaceholder,
      featuredTitle,
      nearbyTitle,
      noResults,
      tryAdjustingFilters,
      newBadge,
      categoryLabel,
      districtLabel,
      ratingLabel,
      allLabel,
      clearFilters;
  final Map<String, String> categories; // keys: restaurant, salon, court, gaming_cafe, car_wash
}

class BusinessStrings {
  const BusinessStrings({
    required this.reviews,
    required this.noReviews,
    required this.bookNow,
    required this.viewAvailability,
    required this.about,
    required this.location,
    required this.staff,
    required this.anyStaff,
    required this.newBadge,
    required this.courts,
    required this.stations,
    required this.nextAvailableSlots,
    required this.notFound,
  });
  final String reviews,
      noReviews,
      bookNow,
      viewAvailability,
      about,
      location,
      staff,
      anyStaff,
      newBadge,
      courts,
      stations,
      nextAvailableSlots,
      notFound;

  String reviewsCount(int count) => noReviews.contains('yet') ? '$count reviews' : '$count تقييم';
}

class BookingSummaryStrings {
  const BookingSummaryStrings({
    required this.title,
    required this.deposit,
    required this.platformFee,
    required this.total,
  });
  final String title, deposit, platformFee, total;

  String depositNote(int hours) => deposit.contains('Refund')
      ? 'Deposit fully refunded if cancelled $hours+ hours before'
      : 'العربون يُسترد بالكامل عند الإلغاء قبل $hours ساعة';
}

class BookingConfirmedStrings {
  const BookingConfirmedStrings({
    required this.title,
    required this.subtitle,
    required this.bookingRef,
    required this.viewBookings,
    required this.backHome,
  });
  final String title, subtitle, bookingRef, viewBookings, backHome;
}

class BookingPaymentStrings {
  const BookingPaymentStrings({
    required this.title,
    required this.card,
    required this.instapay,
    required this.fawry,
    required this.vodafone,
    required this.meeza,
    required this.payNow,
  });
  final String title, card, instapay, fawry, vodafone, meeza, payNow;
}

class BookingStrings {
  const BookingStrings({
    required this.checkoutTitle,
    required this.selectDate,
    required this.selectTime,
    required this.partySize,
    required this.specialRequests,
    required this.specialRequestsPlaceholder,
    required this.noSlotsAvailable,
    required this.confirmCta,
    required this.slotHeld,
    required this.minutes,
    required this.slotExpired,
    required this.summary,
    required this.payment,
    required this.confirmed,
  });
  final String checkoutTitle,
      selectDate,
      selectTime,
      partySize,
      specialRequests,
      specialRequestsPlaceholder,
      noSlotsAvailable,
      confirmCta,
      slotHeld,
      minutes,
      slotExpired;
  final BookingSummaryStrings summary;
  final BookingPaymentStrings payment;
  final BookingConfirmedStrings confirmed;
}

class MyBookingsStrings {
  const MyBookingsStrings({
    required this.title,
    required this.upcoming,
    required this.past,
    required this.empty,
    required this.emptySubtitle,
    required this.statuses,
    required this.cancel,
    required this.reschedule,
    required this.review,
    required this.cancelConfirm,
    required this.cancelInsideWindow,
    required this.cancelOutsideWindow,
  });
  final String title,
      upcoming,
      past,
      empty,
      emptySubtitle,
      cancel,
      reschedule,
      review,
      cancelConfirm,
      cancelInsideWindow,
      cancelOutsideWindow;
  final Map<String, String> statuses; // keys mirror BookingStatus.toJson()-style strings
}

class ProfileStrings {
  const ProfileStrings({
    required this.title,
    required this.language,
    required this.arabic,
    required this.english,
    required this.notifications,
    required this.notificationsSubtitle,
  });
  final String title, language, arabic, english, notifications, notificationsSubtitle;
}

class ErrorStrings {
  const ErrorStrings({
    required this.network,
    required this.slotTaken,
    required this.capacityExceeded,
    required this.generic,
  });
  final String network, slotTaken, capacityExceeded, generic;
}

class AppStrings {
  const AppStrings({
    required this.common,
    required this.auth,
    required this.home,
    required this.business,
    required this.booking,
    required this.myBookings,
    required this.profile,
    required this.errors,
  });

  final CommonStrings common;
  final AuthStrings auth;
  final HomeStrings home;
  final BusinessStrings business;
  final BookingStrings booking;
  final MyBookingsStrings myBookings;
  final ProfileStrings profile;
  final ErrorStrings errors;

  static AppStrings of(String languageCode) => languageCode == 'en' ? en : ar;

  static const ar = AppStrings(
    common: CommonStrings(
      appName: 'حاجز',
      loading: 'جاري التحميل...',
      error: 'حدث خطأ',
      retry: 'إعادة المحاولة',
      confirm: 'تأكيد',
      cancel: 'إلغاء',
      save: 'حفظ',
      back: 'رجوع',
      close: 'إغلاق',
      next: 'التالي',
      egp: 'ج.م',
      viewAll: 'عرض الكل',
    ),
    auth: AuthStrings(
      welcomeTitle: 'اتحجز في ثوانٍ',
      welcomeSubtitle: 'مطاعم، صالونات، ملاعب وأكثر — في تطبيق واحد',
      enterPhone: 'أدخل رقم هاتفك',
      phonePlaceholder: '+201XXXXXXXXX',
      sendOtp: 'إرسال الكود',
      enterOtp: 'أدخل كود التحقق',
      otpSentTo: 'أرسلنا كود التحقق إلى',
      otpPlaceholder: '000000',
      verifyOtp: 'تأكيد',
      resendOtp: 'إعادة إرسال الكود',
      invalidOtp: 'الكود غير صحيح أو منتهي الصلاحية',
      loginWithGoogle: 'الدخول بجوجل',
      byProceeding: 'بالمتابعة، أنت توافق على',
      termsOfService: 'شروط الخدمة',
      and: 'و',
      privacyPolicy: 'سياسة الخصوصية',
      logout: 'تسجيل الخروج',
    ),
    home: HomeStrings(
      greeting: 'أهلاً،',
      searchPlaceholder: 'ابحث عن مطعم، صالون...',
      categories: {
        'restaurant': 'مطاعم',
        'salon': 'صالونات',
        'court': 'ملاعب',
        'gaming_cafe': 'جيمنج',
        'car_wash': 'غسيل سيارات',
      },
      featuredTitle: 'مميزة لك',
      nearbyTitle: 'قريبة منك',
      noResults: 'لا توجد نتائج',
      tryAdjustingFilters: 'جرب تعديل الفلاتر أو تغيير المنطقة',
      newBadge: 'جديد',
      categoryLabel: 'الفئة',
      districtLabel: 'المنطقة',
      ratingLabel: 'التقييم',
      allLabel: 'الكل',
      clearFilters: 'مسح الفلاتر',
    ),
    business: BusinessStrings(
      reviews: 'تقييم',
      noReviews: 'لا توجد تقييمات بعد',
      bookNow: 'احجز الآن',
      viewAvailability: 'اعرض المواعيد',
      about: 'عن المكان',
      location: 'الموقع',
      staff: 'الفريق',
      anyStaff: 'أي متخصص',
      newBadge: 'جديد',
      courts: 'الملاعب',
      stations: 'الأجهزة',
      nextAvailableSlots: 'أقرب المواعيد المتاحة',
      notFound: 'لم يتم العثور على هذا المكان',
    ),
    booking: BookingStrings(
      checkoutTitle: 'تفاصيل الحجز',
      selectDate: 'اختر التاريخ',
      selectTime: 'اختر الموعد',
      partySize: 'عدد الأشخاص',
      specialRequests: 'طلبات خاصة (اختياري)',
      specialRequestsPlaceholder: 'أي طلبات خاصة للمكان...',
      noSlotsAvailable: 'لا توجد مواعيد متاحة في هذا اليوم',
      confirmCta: 'تأكيد الحجز',
      slotHeld: 'الموعد محجوز لك لـ',
      minutes: 'دقيقة',
      slotExpired: 'انتهى وقت الحجز. اختر موعداً آخر.',
      summary: BookingSummaryStrings(
        title: 'ملخص الحجز',
        deposit: 'عربون مسترد',
        platformFee: 'رسوم الحجز',
        total: 'الإجمالي',
      ),
      payment: BookingPaymentStrings(
        title: 'اختر طريقة الدفع',
        card: 'بطاقة بنكية',
        instapay: 'InstaPay',
        fawry: 'فوري',
        vodafone: 'فودافون كاش',
        meeza: 'ميزة',
        payNow: 'ادفع الآن',
      ),
      confirmed: BookingConfirmedStrings(
        title: 'تم تأكيد حجزك! 🎉',
        subtitle: 'شكراً لك. تم إرسال تفاصيل الحجز على واتساب.',
        bookingRef: 'رقم الحجز',
        viewBookings: 'عرض حجوزاتي',
        backHome: 'الرئيسية',
      ),
    ),
    myBookings: MyBookingsStrings(
      title: 'حجوزاتي',
      upcoming: 'القادمة',
      past: 'السابقة',
      empty: 'لا توجد حجوزات',
      emptySubtitle: 'ابحث عن مكان واحجز الآن',
      statuses: {
        'confirmed': 'مؤكد',
        'pending_payment': 'في انتظار الدفع',
        'completed': 'مكتمل',
        'cancelled_by_consumer': 'ملغي منك',
        'cancelled_by_business': 'ملغي من المكان',
        'no_show': 'غياب',
        'disputed': 'قيد المراجعة',
        'expired': 'منتهي',
      },
      cancel: 'إلغاء الحجز',
      reschedule: 'تغيير الموعد',
      review: 'اكتب تقييمك',
      cancelConfirm: 'هل أنت متأكد من إلغاء الحجز؟',
      cancelInsideWindow: 'سيتم خصم العربون لأن الإلغاء داخل فترة السياسة.',
      cancelOutsideWindow: 'سيتم استرداد العربون كاملاً خلال 3-5 أيام عمل.',
    ),
    profile: ProfileStrings(
      title: 'الملف الشخصي',
      language: 'اللغة',
      arabic: 'العربية',
      english: 'English',
      notifications: 'الإشعارات',
      notificationsSubtitle: 'تلقي إشعارات بالحجوزات والعروض',
    ),
    errors: ErrorStrings(
      network: 'تحقق من اتصالك بالإنترنت',
      slotTaken: 'هذا الموعد تم حجزه. اختر موعداً آخر.',
      capacityExceeded: 'لا تتوفر أماكن كافية لعدد ضيوفك.',
      generic: 'حدث خطأ. حاول مرة أخرى.',
    ),
  );

  static const en = AppStrings(
    common: CommonStrings(
      appName: 'Hagez',
      loading: 'Loading...',
      error: 'Something went wrong',
      retry: 'Retry',
      confirm: 'Confirm',
      cancel: 'Cancel',
      save: 'Save',
      back: 'Back',
      close: 'Close',
      next: 'Next',
      egp: 'EGP',
      viewAll: 'View All',
    ),
    auth: AuthStrings(
      welcomeTitle: 'Book in seconds',
      welcomeSubtitle: 'Restaurants, salons, courts and more — one app',
      enterPhone: 'Enter your phone number',
      phonePlaceholder: '+201XXXXXXXXX',
      sendOtp: 'Send Code',
      enterOtp: 'Enter verification code',
      otpSentTo: 'We sent a code to',
      otpPlaceholder: '000000',
      verifyOtp: 'Verify',
      resendOtp: 'Resend Code',
      invalidOtp: 'Invalid or expired code',
      loginWithGoogle: 'Continue with Google',
      byProceeding: 'By proceeding, you agree to our',
      termsOfService: 'Terms of Service',
      and: 'and',
      privacyPolicy: 'Privacy Policy',
      logout: 'Logout',
    ),
    home: HomeStrings(
      greeting: 'Hello,',
      searchPlaceholder: 'Search restaurants, salons...',
      categories: {
        'restaurant': 'Restaurants',
        'salon': 'Salons',
        'court': 'Courts',
        'gaming_cafe': 'Gaming',
        'car_wash': 'Car Wash',
      },
      featuredTitle: 'Featured',
      nearbyTitle: 'Nearby',
      noResults: 'No results found',
      tryAdjustingFilters: 'Try adjusting filters or changing the district',
      newBadge: 'New',
      categoryLabel: 'Category',
      districtLabel: 'District',
      ratingLabel: 'Rating',
      allLabel: 'All',
      clearFilters: 'Clear Filters',
    ),
    business: BusinessStrings(
      reviews: 'reviews',
      noReviews: 'No reviews yet',
      bookNow: 'Book Now',
      viewAvailability: 'View Availability',
      about: 'About',
      location: 'Location',
      staff: 'Staff',
      anyStaff: 'Any specialist',
      newBadge: 'New',
      courts: 'Courts',
      stations: 'Stations',
      nextAvailableSlots: 'Next Available Slots',
      notFound: 'Business not found',
    ),
    booking: BookingStrings(
      checkoutTitle: 'Booking Details',
      selectDate: 'Select Date',
      selectTime: 'Select Time',
      partySize: 'Party Size',
      specialRequests: 'Special Requests (optional)',
      specialRequestsPlaceholder: 'Any special requests for the venue...',
      noSlotsAvailable: 'No slots available on this day',
      confirmCta: 'Confirm Booking',
      slotHeld: 'Your slot is held for',
      minutes: 'minutes',
      slotExpired: 'Your hold has expired. Please select another slot.',
      summary: BookingSummaryStrings(
        title: 'Booking Summary',
        deposit: 'Refundable Deposit',
        platformFee: 'Booking Fee',
        total: 'Total',
      ),
      payment: BookingPaymentStrings(
        title: 'Choose Payment Method',
        card: 'Card',
        instapay: 'InstaPay',
        fawry: 'Fawry',
        vodafone: 'Vodafone Cash',
        meeza: 'Meeza',
        payNow: 'Pay Now',
      ),
      confirmed: BookingConfirmedStrings(
        title: 'Booking Confirmed! 🎉',
        subtitle: 'Confirmation details sent to WhatsApp.',
        bookingRef: 'Booking Reference',
        viewBookings: 'My Bookings',
        backHome: 'Home',
      ),
    ),
    myBookings: MyBookingsStrings(
      title: 'My Bookings',
      upcoming: 'Upcoming',
      past: 'Past',
      empty: 'No bookings yet',
      emptySubtitle: 'Find a place and make your first booking',
      statuses: {
        'confirmed': 'Confirmed',
        'pending_payment': 'Awaiting Payment',
        'completed': 'Completed',
        'cancelled_by_consumer': 'Cancelled by You',
        'cancelled_by_business': 'Cancelled by Business',
        'no_show': 'No Show',
        'disputed': 'Under Review',
        'expired': 'Expired',
      },
      cancel: 'Cancel Booking',
      reschedule: 'Reschedule',
      review: 'Write a Review',
      cancelConfirm: 'Are you sure you want to cancel this booking?',
      cancelInsideWindow: 'The deposit will be forfeited — cancellation is within the policy window.',
      cancelOutsideWindow: 'The deposit will be fully refunded within 3-5 business days.',
    ),
    profile: ProfileStrings(
      title: 'Profile',
      language: 'Language',
      arabic: 'العربية',
      english: 'English',
      notifications: 'Notifications',
      notificationsSubtitle: 'Receive booking and promo notifications',
    ),
    errors: ErrorStrings(
      network: 'Check your internet connection',
      slotTaken: 'This slot has just been booked. Please pick another.',
      capacityExceeded: 'Not enough capacity for your party size.',
      generic: 'Something went wrong. Please try again.',
    ),
  );
}
