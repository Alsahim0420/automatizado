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

  /// `true` si el JSON trae `success: true` (bool o string).
  bool get isSuccess {
    final v = data['success'];
    if (v is bool) return v;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1';
    }
    return false;
  }

  /// Hay respuesta explícita de error (`success: false`).
  bool get isFailure =>
      data.containsKey('success') && !isSuccess;

  /// Texto para Snackbar cuando fue exitoso.
  String get successUserMessage {
    final m = data['message'];
    if (m is String && m.trim().isNotEmpty) return m.trim();
    return 'Reunión creada correctamente';
  }

  /// Mensaje de error legible si `success` es false.
  String? get failureUserMessage {
    if (!isFailure) return null;
    final m = data['message'];
    if (m is String && m.trim().isNotEmpty) return m.trim();
    return null;
  }
}
