import 'package:flutter/material.dart';

import '../models/meeting_response.dart';

/// Éxito (`success: true`) → Snackbar con [MeetingResponse.successUserMessage].
/// Fallo explícito (`success: false`) → [setError] con mensaje o JSON.
/// Sin campo `success` → [setResult] con JSON para depuración.
void presentMeetingOutcome(
  BuildContext context,
  MeetingResponse response, {
  required void Function(VoidCallback fn) setState,
  required void Function(String? error) setError,
  required void Function(String? result) setResult,
}) {
  if (response.isSuccess) {
    setState(() {
      setError(null);
      setResult(null);
    });
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: const Color(0xFF059669),
        content: Text(response.successUserMessage),
      ),
    );
    return;
  }

  if (response.isFailure) {
    setState(() {
      setResult(null);
      setError(response.failureUserMessage ?? response.toJsonPretty());
    });
    return;
  }

  setState(() {
    setError(null);
    setResult(response.toJsonPretty());
  });
}
