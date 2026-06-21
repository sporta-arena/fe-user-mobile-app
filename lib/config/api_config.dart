class ApiConfig {
  // Staging URL - API Staging Sportago
  static const String stagingUrl = 'https://api.staging.sportago.id';

  // Production URL
  static const String productionUrl = 'https://api.sportago.id';

  // Local development URL
  static const String localUrl = 'http://localhost:8088';

  // Android Emulator URL (10.0.2.2 = localhost dari emulator)
  static const String androidEmulatorUrl = 'http://10.0.2.2:8088';

  // Environment check
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');

  // PILIH SATU:
  // - 'staging' = Staging Server (api.staging.sportago.id)
  // - 'production' = Production Server (api.sportago.id)
  // - 'ios' = iOS Simulator (localhost)
  // - 'android' = Android Emulator (10.0.2.2)
  //
  // Default 'staging'. Bisa di-override saat run tanpa edit file, mis:
  //   flutter run --dart-define=DEV_MODE=ios
  // start.sh otomatis mengisi ini sesuai device (ios/android) untuk pakai BE lokal.
  static String devMode =
      const String.fromEnvironment('DEV_MODE', defaultValue: 'staging');

  // Get host URL (without /api/v1)
  static String get hostUrl {
    if (isProduction) {
      return productionUrl;
    }
    switch (devMode) {
      case 'staging':
        return stagingUrl;
      case 'production':
        return productionUrl;
      case 'ios':
        return localUrl;
      case 'android':
        return androidEmulatorUrl;
      default:
        return stagingUrl;
    }
  }

  // API base URL (with /api/v1 prefix)
  static String get apiUrl => '$hostUrl/api/v1';

  // ============================================================
  // AUTH ENDPOINTS
  // ============================================================
  static String get loginUrl => '$apiUrl/login';
  static String get registerUrl => '$apiUrl/register';
  static String get partnerRegisterUrl => '$apiUrl/partner/register';
  static String get managementLoginUrl => '$apiUrl/management/login';
  static String get verifyOtpUrl => '$apiUrl/verify-otp';
  static String get resendOtpUrl => '$apiUrl/resend-otp';
  static String get forgotPasswordUrl => '$apiUrl/forgot-password';
  static String get verifyResetOtpUrl => '$apiUrl/verify-reset-otp';
  static String get resetPasswordUrl => '$apiUrl/reset-password';
  static String get userUrl => '$apiUrl/user';
  static String get logoutUrl => '$apiUrl/logout';
  static String get logoutAllUrl => '$apiUrl/logout-all';

  // ============================================================
  // VENUES (PUBLIC)
  // ============================================================
  static String get venuesUrl => '$apiUrl/venues';
  static String venueDetailUrl(int id) => '$apiUrl/venues/$id';
  static String venueFieldsUrl(int venueId) => '$apiUrl/venues/$venueId/fields';
  static String fieldDetailUrl(int venueId, int fieldId) => '$apiUrl/venues/$venueId/fields/$fieldId';
  static String venueReviewsUrl(int venueId) => '$apiUrl/venues/$venueId/reviews';

  // ============================================================
  // VENUES (PARTNER)
  // ============================================================
  static String get myVenuesUrl => '$apiUrl/my-venues';
  static String myVenueDetailUrl(int id) => '$apiUrl/my-venues/$id';
  static String myVenueFieldsUrl(int venueId) => '$apiUrl/venues/$venueId/my-fields';

  // ============================================================
  // VENUE ONBOARDING (PARTNER)
  // ============================================================
  static String venueOnboardingStatusUrl(int venueId) => '$apiUrl/venues/$venueId/onboarding/status';
  static String venueOnboardingCreateUrl(int venueId) => '$apiUrl/venues/$venueId/onboarding/create';
  static String venueOnboardingRefreshUrl(int venueId) => '$apiUrl/venues/$venueId/onboarding/refresh';
  static String venueOnboardingSimulateUrl(int venueId) => '$apiUrl/venues/$venueId/onboarding/simulate';
  static String venueOnboardingSimulateVerifyUrl(int venueId) => '$apiUrl/venues/$venueId/onboarding/simulate-verify';

  // ============================================================
  // VENUES (ADMIN)
  // ============================================================
  static String get adminVenuesUrl => '$apiUrl/admin/venues';
  static String adminVenueDetailUrl(int id) => '$apiUrl/admin/venues/$id';
  static String adminVenueStatusUrl(int id) => '$apiUrl/admin/venues/$id/status';
  static String adminVenueFieldsUrl(int venueId) => '$apiUrl/admin/venues/$venueId/fields';

  // ============================================================
  // FIELDS (PARTNER)
  // ============================================================
  static String createFieldUrl(int venueId) => '$apiUrl/venues/$venueId/fields';
  static String updateFieldUrl(int venueId, int fieldId) => '$apiUrl/venues/$venueId/fields/$fieldId';
  static String deleteFieldUrl(int venueId, int fieldId) => '$apiUrl/venues/$venueId/fields/$fieldId';

  // ============================================================
  // VENUE SCHEDULE EXCEPTIONS (PARTNER)
  // ============================================================
  static String venueScheduleExceptionsUrl(int venueId) => '$apiUrl/venues/$venueId/schedule-exceptions';
  static String venueScheduleExceptionDetailUrl(int venueId, int exceptionId) =>
      '$apiUrl/venues/$venueId/schedule-exceptions/$exceptionId';

  // ============================================================
  // FIELD SCHEDULES (PARTNER)
  // ============================================================
  static String fieldSchedulesUrl(int venueId, int fieldId) =>
      '$apiUrl/venues/$venueId/fields/$fieldId/schedules';
  static String fieldScheduleDetailUrl(int venueId, int fieldId, int scheduleId) =>
      '$apiUrl/venues/$venueId/fields/$fieldId/schedules/$scheduleId';

  // ============================================================
  // FIELD PRICING RULES (PARTNER)
  // ============================================================
  static String fieldPricingRulesUrl(int venueId, int fieldId) =>
      '$apiUrl/venues/$venueId/fields/$fieldId/pricing-rules';
  static String fieldPricingRuleDetailUrl(int venueId, int fieldId, int ruleId) =>
      '$apiUrl/venues/$venueId/fields/$fieldId/pricing-rules/$ruleId';

  // ============================================================
  // BOOKINGS (CUSTOMER)
  // ============================================================
  static String availableSlotsUrl(int fieldId) => '$apiUrl/fields/$fieldId/available-slots';
  static String get bookingsUrl => '$apiUrl/bookings';
  static String bookingDetailUrl(int id) => '$apiUrl/bookings/$id';
  static String cancelBookingUrl(int id) => '$apiUrl/bookings/$id/cancel';
  static String simulatePaymentUrl(int id) => '$apiUrl/bookings/$id/simulate-payment';
  static String refundPreviewUrl(int id) => '$apiUrl/bookings/$id/refund-preview';
  static String refundPolicyUrl(int bookingId) => '$apiUrl/bookings/$bookingId/refund-policy';
  static String canReviewBookingUrl(int id) => '$apiUrl/bookings/$id/can-review';

  // ============================================================
  // WITHDRAWALS (CUSTOMER)
  // ============================================================
  static String get withdrawalBalanceUrl => '$apiUrl/withdrawals/balance';
  static String get withdrawalEligibleBookingsUrl => '$apiUrl/withdrawals/eligible-bookings';
  static String get withdrawalBanksUrl => '$apiUrl/withdrawals/banks';
  static String get withdrawalsUrl => '$apiUrl/withdrawals';
  static String withdrawalDetailUrl(int id) => '$apiUrl/withdrawals/$id';
  static String withdrawalSimulateProcessUrl(int id) => '$apiUrl/withdrawals/$id/simulate-process';

  // ============================================================
  // BOOKINGS (PARTNER)
  // ============================================================
  static String get partnerBookingsUrl => '$apiUrl/partner/bookings';
  static String partnerBookingDetailUrl(int id) => '$apiUrl/partner/bookings/$id';
  static String get partnerCheckInUrl => '$apiUrl/partner/bookings/check-in';
  static String venueScheduleUrl(int venueId) => '$apiUrl/partner/venues/$venueId/schedule';

  // ============================================================
  // REVIEWS
  // ============================================================
  static String get reviewsUrl => '$apiUrl/reviews';
  static String get myReviewsUrl => '$apiUrl/my-reviews';
  static String get partnerReviewsUrl => '$apiUrl/partner/reviews';
  static String reviewReplyUrl(int reviewId) => '$apiUrl/reviews/$reviewId/reply';

  // ============================================================
  // FINANCIAL & ANALYTICS (PARTNER)
  // ============================================================
  static String get partnerFinancialReportUrl => '$apiUrl/partner/financial-report';
  static String get partnerAnalyticsUrl => '$apiUrl/partner/analytics';

  // ============================================================
  // ANALYTICS (ADMIN)
  // ============================================================
  static String get adminAnalyticsUrl => '$apiUrl/admin/analytics';

  // ============================================================
  // ROLES & PERMISSIONS (ADMIN)
  // ============================================================
  static String get rolesUrl => '$apiUrl/roles';
  static String roleDetailUrl(int id) => '$apiUrl/roles/$id';
  static String get rolesAssignUrl => '$apiUrl/roles/assign';
  static String get rolesRemoveUrl => '$apiUrl/roles/remove';
  static String get permissionsUrl => '$apiUrl/permissions';
  static String permissionDetailUrl(int id) => '$apiUrl/permissions/$id';
  static String get permissionsAssignUrl => '$apiUrl/permissions/assign';
  static String get permissionsRemoveUrl => '$apiUrl/permissions/remove';

  // ============================================================
  // USERS (ADMIN)
  // ============================================================
  static String get usersUrl => '$apiUrl/users';
  static String userDetailUrl(int id) => '$apiUrl/users/$id';
  static String userRolesUrl(int id) => '$apiUrl/users/$id/roles';

  // ============================================================
  // WEBHOOKS (Not versioned)
  // ============================================================
  static String get xenditWebhookUrl => '$hostUrl/api/webhooks/xendit';

  // ============================================================
  // FIELD TYPES
  // ============================================================
  static String get fieldTypesUrl => '$apiUrl/field-types';

  // ============================================================
  // REFUNDS
  // ============================================================
  static String get refundsUrl => '$apiUrl/refunds';
  static String refundDetailUrl(int id) => '$apiUrl/refunds/$id';
  static String requestRefundUrl(int bookingId) => '$apiUrl/bookings/$bookingId/refund';

  // ============================================================
  // CHAT
  // ============================================================
  static String get baseUrl => apiUrl;

  // ============================================================
  // HEALTH CHECK
  // ============================================================
  static String get healthCheckUrl => '$hostUrl/up';

  // ============================================================
  // HEADERS
  // ============================================================
  static Map<String, String> get defaultHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> multipartHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
