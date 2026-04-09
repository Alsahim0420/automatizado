import 'dart:convert';

/// Normaliza la respuesta del webhook de n8n (cuerpo vacío, JSON objeto o otro valor).
class MeetingResponse {
  MeetingResponse._(this.data);

  final Map<String, dynamic> data;

  factory MeetingResponse.fromWebhookBody(String body) {
    if (body.trim().isEmpty) {
      return MeetingResponse._({
        'success': true,
        'message':
            'Solicitud enviada correctamente, pero el webhook no devolvió contenido.',
      });
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return MeetingResponse._(decoded);
    }

    return MeetingResponse._({
      'success': true,
      'data': decoded,
    });
  }

  String toJsonPretty() =>
      const JsonEncoder.withIndent('  ').convert(data);
}
