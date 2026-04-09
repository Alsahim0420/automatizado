import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/meeting_response.dart';

class MeetingService {
  static const String _webhookUrl =
      'https://panmecar.app.n8n.cloud/webhook/d60d60b1-cc57-4aa3-b07c-6af900f5d6e3';

  Future<MeetingResponse> sendMeetingRequest(String message) async {
    final response = await http.post(
      Uri.parse(_webhookUrl),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo procesar la solicitud. Código ${response.statusCode}: ${response.body}',
      );
    }

    return MeetingResponse.fromWebhookBody(response.body);
  }
}
