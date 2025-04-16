class Translations {
  static const Map<String, Map<String, String>> _translations = {
    'en-gb': {
      'welcome': 'Welcome to CloudKey',
      'bookings': 'Bookings',
      'digital_key': 'Digital Key',
      'car_rental': 'Car Rental',
      'hotel_services': 'Hotel Services',
      'profile': 'Profile',
      'notifications': 'Notifications',
      'sign_out': 'Sign Out',
      'no_bookings': 'No bookings found. Please make a booking first.',
      'error_fetching_booking': 'Error fetching recent booking',
      'check_in': 'Check In',
      'check_out': 'Check Out',
      'digital_key_active': 'Active',
      'digital_key_inactive': 'Inactive',
      'digital_key_status': 'Digital Key Status',
      'check_in_success': 'Check-In Successful! Digital Key Generated.',
      'check_out_success': 'Check-Out Successful!',
      'no_digital_key': 'No digital key available. Please check in first.',
      'nfc_not_available': 'NFC is not available on this device.',
      'guest': 'Guest',
    },
    'ar': {
      'welcome': 'مرحبًا بكم في CloudKey',
      'bookings': 'الحجوزات',
      'digital_key': 'المفتاح الرقمي',
      'car_rental': 'تأجير السيارات',
      'hotel_services': 'خدمات الفندق',
      'profile': 'الملف الشخصي',
      'notifications': 'الإشعارات',
      'sign_out': 'تسجيل الخروج',
      'no_bookings': 'لم يتم العثور على حجوزات. يرجى إجراء حجز أولاً.',
      'error_fetching_booking': 'خطأ في جلب الحجز الأخير',
      'check_in': 'تسجيل الدخول',
      'check_out': 'تسجيل الخروج',
      'digital_key_active': 'نشط',
      'digital_key_inactive': 'غير نشط',
      'digital_key_status': 'حالة المفتاح الرقمي',
      'check_in_success': 'تم تسجيل الدخول بنجاح! تم إنشاء المفتاح الرقمي.',
      'check_out_success': 'تم تسجيل الخروج بنجاح!',
      'no_digital_key': 'لا يوجد مفتاح رقمي متاح. يرجى تسجيل الدخول أولاً.',
      'nfc_not_available': 'NFC غير متاح على هذا الجهاز.',
      'guest': 'ضيف',
    },
  };

  static String translate(String key, String locale) {
    return _translations[locale]?[key] ?? key;
  }
}