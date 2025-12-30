class XenditConfig {
  // Development API Key
  static const String developmentApiKey = 'xnd_development_TgdLGRyiTqQPAMKnrt9BBjmE8lNt5zJ8LLeosvDO5gzbKjuQTnQHQqEuX2wl7';
  
  // Production API Key (akan diisi saat production)
  static const String productionApiKey = '';
  
  // Base URL
  static const String baseUrl = 'https://api.xendit.co';
  
  // Environment check
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  
  // Get current API key based on environment
  static String get apiKey => isProduction ? productionApiKey : developmentApiKey;
  
  // Callback URLs (ganti dengan URL aplikasi Anda)
  static const String callbackUrl = 'https://your-app.com/xendit-callback';
  static const String successRedirectUrl = 'https://your-app.com/payment-success';
  static const String failureRedirectUrl = 'https://your-app.com/payment-failed';
  
  // Payment method configurations
  static const Map<String, Map<String, dynamic>> paymentMethods = {
    'qris': {
      'name': 'QRIS',
      'fee': 1500,
      'type': 'flat',
      'description': 'Gopay, OVO, Dana, ShopeePay',
    },
    'va_bca': {
      'name': 'Virtual Account BCA',
      'fee': 4000,
      'type': 'flat',
      'bankCode': 'BCA',
    },
    'va_bni': {
      'name': 'Virtual Account BNI',
      'fee': 4000,
      'type': 'flat',
      'bankCode': 'BNI',
    },
    'va_bri': {
      'name': 'Virtual Account BRI',
      'fee': 4000,
      'type': 'flat',
      'bankCode': 'BRI',
    },
    'va_mandiri': {
      'name': 'Virtual Account Mandiri',
      'fee': 4000,
      'type': 'flat',
      'bankCode': 'MANDIRI',
    },
    'va_permata': {
      'name': 'Virtual Account Permata',
      'fee': 4000,
      'type': 'flat',
      'bankCode': 'PERMATA',
    },
    'alfamart': {
      'name': 'Alfamart',
      'fee': 2500,
      'type': 'flat',
      'retailCode': 'ALFAMART',
    },
    'indomaret': {
      'name': 'Indomaret',
      'fee': 2500,
      'type': 'flat',
      'retailCode': 'INDOMARET',
    },
    'credit_card': {
      'name': 'Credit Card',
      'fee': 2.9, // percentage
      'type': 'percentage',
      'fixedFee': 2000,
    },
  };
}