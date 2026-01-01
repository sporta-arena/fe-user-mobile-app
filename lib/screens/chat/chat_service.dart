import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_models.dart';

class ChatService {
  // Get messages for a specific booking
  static Future<List<Message>> getMessages(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/bookings/$bookingId/messages'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> messages = data['data'] ?? [];
        return messages.map((m) => Message.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Send a message
  static Future<Message?> sendMessage(int bookingId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/bookings/$bookingId/messages'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
          'type': 'text',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Message.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get partner contact info for a booking
  static Future<PartnerContact?> getPartnerContact(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/bookings/$bookingId/partner'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PartnerContact.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
