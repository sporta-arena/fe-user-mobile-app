import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/xendit_config.dart';

class XenditService {
  // Headers untuk API request
  static Map<String, String> get _headers => {
    'Authorization': 'Basic ${base64Encode(utf8.encode('${XenditConfig.apiKey}:'))}',
    'Content-Type': 'application/json',
  };

  // Generate UUID untuk external ID
  static String _generateExternalId() {
    return 'sporta-${const Uuid().v4()}';
  }

  // 1. Create QRIS Payment
  static Future<Map<String, dynamic>?> createQRISPayment({
    required int amount,
    required String description,
    String? customerName,
    String? customerEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${XenditConfig.baseUrl}/qr_codes'),
        headers: _headers,
        body: jsonEncode({
          'external_id': _generateExternalId(),
          'type': 'DYNAMIC',
          'callback_url': XenditConfig.callbackUrl,
          'amount': amount,
          'description': description,
          'currency': 'IDR',
          'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          'customer': {
            'given_names': customerName ?? 'Customer',
            'email': customerEmail ?? 'customer@example.com',
          },
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('QRIS Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('QRIS Exception: $e');
      return null;
    }
  }

  // 2. Create Virtual Account
  static Future<Map<String, dynamic>?> createVirtualAccount({
    required int amount,
    required String bankCode, // BCA, BNI, BRI, MANDIRI, PERMATA
    required String description,
    String? customerName,
    String? customerEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${XenditConfig.baseUrl}/virtual_accounts'),
        headers: _headers,
        body: jsonEncode({
          'external_id': _generateExternalId(),
          'bank_code': bankCode,
          'name': customerName ?? 'Customer Sporta',
          'expected_amount': amount,
          'description': description,
          'currency': 'IDR',
          'expiration_date': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          'customer': {
            'given_names': customerName ?? 'Customer',
            'email': customerEmail ?? 'customer@example.com',
          },
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('VA Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('VA Exception: $e');
      return null;
    }
  }

  // 3. Create Retail Outlet Payment (Alfamart/Indomaret)
  static Future<Map<String, dynamic>?> createRetailPayment({
    required int amount,
    required String retailOutletName, // ALFAMART, INDOMARET
    required String description,
    String? customerName,
    String? customerEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${XenditConfig.baseUrl}/fixed_payment_code'),
        headers: _headers,
        body: jsonEncode({
          'external_id': _generateExternalId(),
          'retail_outlet_name': retailOutletName,
          'name': customerName ?? 'Customer Sporta',
          'expected_amount': amount,
          'description': description,
          'currency': 'IDR',
          'expiration_date': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          'customer': {
            'given_names': customerName ?? 'Customer',
            'email': customerEmail ?? 'customer@example.com',
          },
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Retail Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Retail Exception: $e');
      return null;
    }
  }

  // 4. Create Credit Card Payment
  static Future<Map<String, dynamic>?> createCreditCardPayment({
    required int amount,
    required String description,
    String? customerName,
    String? customerEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${XenditConfig.baseUrl}/invoices'),
        headers: _headers,
        body: jsonEncode({
          'external_id': _generateExternalId(),
          'amount': amount,
          'description': description,
          'currency': 'IDR',
          'invoice_duration': 86400, // 24 hours
          'customer': {
            'given_names': customerName ?? 'Customer',
            'email': customerEmail ?? 'customer@example.com',
          },
          'payment_methods': ['CREDIT_CARD'],
          'success_redirect_url': XenditConfig.successRedirectUrl,
          'failure_redirect_url': XenditConfig.failureRedirectUrl,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Credit Card Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Credit Card Exception: $e');
      return null;
    }
  }

  // 5. Check Payment Status
  static Future<Map<String, dynamic>?> checkPaymentStatus(String paymentId, String paymentType) async {
    try {
      String endpoint;
      switch (paymentType) {
        case 'qris':
          endpoint = '/qr_codes/$paymentId';
          break;
        case 'va':
          endpoint = '/virtual_accounts/$paymentId';
          break;
        case 'retail':
          endpoint = '/fixed_payment_code/$paymentId';
          break;
        case 'invoice':
          endpoint = '/invoices/$paymentId';
          break;
        default:
          return null;
      }

      final response = await http.get(
        Uri.parse('${XenditConfig.baseUrl}$endpoint'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Status Check Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Status Check Exception: $e');
      return null;
    }
  }

  // 6. Get Available Banks for Virtual Account
  static List<Map<String, String>> getAvailableBanks() {
    return [
      {'code': 'BCA', 'name': 'Bank Central Asia', 'fee': '4000'},
      {'code': 'BNI', 'name': 'Bank Negara Indonesia', 'fee': '4000'},
      {'code': 'BRI', 'name': 'Bank Rakyat Indonesia', 'fee': '4000'},
      {'code': 'MANDIRI', 'name': 'Bank Mandiri', 'fee': '4000'},
      {'code': 'PERMATA', 'name': 'Bank Permata', 'fee': '4000'},
    ];
  }

  // 7. Get Available Retail Outlets
  static List<Map<String, String>> getAvailableRetailOutlets() {
    return [
      {'code': 'ALFAMART', 'name': 'Alfamart', 'fee': '2500'},
      {'code': 'INDOMARET', 'name': 'Indomaret', 'fee': '2500'},
    ];
  }

  // 8. Format Currency
  static String formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    )}";
  }
}