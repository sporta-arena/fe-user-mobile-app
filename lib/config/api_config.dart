class ApiConfig {
  // Ngrok URL - Ganti ini setiap kali ngrok restart
  static const String ngrokUrl = 'https://unobviated-prefixable-gerardo.ngrok-free.dev';

  // Local development URL
  static const String localUrl = 'http://localhost:8088';

  // Production URL (ganti dengan URL production nanti)
  static const String productionUrl = 'https://api.sporta.id';

  // Environment check
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');

  // Use ngrok for development (mobile device testing)
  static bool useNgrok = true;

  // Get base URL
  static String get baseUrl {
    if (isProduction) {
      return productionUrl;
    }
    return useNgrok ? ngrokUrl : localUrl;
  }

  // API base URL (with /api prefix)
  static String get apiUrl => '$baseUrl/api';

  // Endpoints
  static String get loginUrl => '$apiUrl/login';
  static String get registerUrl => '$apiUrl/register';
  static String get logoutUrl => '$apiUrl/logout';
  static String get logoutAllUrl => '$apiUrl/logout-all';
  static String get userUrl => '$apiUrl/user';

  // Venues
  static String get venuesUrl => '$apiUrl/venues';
  static String get myVenuesUrl => '$apiUrl/my-venues';
  static String venueDetailUrl(int id) => '$apiUrl/venues/$id';
  static String venueFieldsUrl(int venueId) => '$apiUrl/venues/$venueId/fields';

  // Fields
  static String fieldDetailUrl(int venueId, int fieldId) => '$apiUrl/venues/$venueId/fields/$fieldId';
  static String availableSlotsUrl(int fieldId) => '$apiUrl/fields/$fieldId/available-slots';

  // Bookings
  static String get bookingsUrl => '$apiUrl/bookings';
  static String bookingDetailUrl(int id) => '$apiUrl/bookings/$id';
  static String cancelBookingUrl(int id) => '$apiUrl/bookings/$id/cancel';
  static String simulatePaymentUrl(int id) => '$apiUrl/bookings/$id/simulate-payment';

  // Partner
  static String get partnerBookingsUrl => '$apiUrl/partner/bookings';
  static String partnerBookingDetailUrl(int id) => '$apiUrl/partner/bookings/$id';
  static String venueScheduleUrl(int venueId) => '$apiUrl/partner/venues/$venueId/schedule';

  // Admin
  static String get adminVenuesUrl => '$apiUrl/admin/venues';
  static String adminVenueDetailUrl(int id) => '$apiUrl/admin/venues/$id';
  static String adminVenueStatusUrl(int id) => '$apiUrl/admin/venues/$id/status';

  // Roles & Permissions (Admin)
  static String get rolesUrl => '$apiUrl/roles';
  static String get permissionsUrl => '$apiUrl/permissions';

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true', // Skip ngrok warning page
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> multipartHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
    'ngrok-skip-browser-warning': 'true',
  };
}
