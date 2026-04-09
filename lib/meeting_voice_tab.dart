import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'meeting_service.dart';
import 'widgets/info_card.dart';

class MeetingVoiceTab extends StatefulWidget {
  const MeetingVoiceTab({
    super.key,
    required this.service,
  });

  final MeetingService service;

  @override
  State<MeetingVoiceTab> createState() => _MeetingVoiceTabState();
}

class _MeetingVoiceTabState extends State<MeetingVoiceTab>
    with SingleTickerProviderStateMixin {
  late final stt.SpeechToText _speech;
  late final AnimationController _pulseController;

  bool _speechAvailable = false;
  bool _isListening = false;
  String _spokenText = '';

  bool _isSubmitting = false;
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize();
    if (!mounted) return;
    setState(() {
      _speechAvailable = available;
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      setState(() {
        _error =
            'El reconocimiento de voz no está disponible en este dispositivo.';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    await _speech.listen(
      localeId: 'es_CO',
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _spokenText = result.recognizedWords;
        });
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
      ),
    );

    if (!mounted) return;
    setState(() {
      _isListening = true;
    });
    _pulseController.repeat(reverse: true);
  }

  Future<void> _stopListeningAndSend() async {
    _pulseController.stop();
    _pulseController.reset();
    await _speech.stop();
    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    // Dar tiempo a que llegue el resultado final del motor de voz.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final text = _spokenText.trim();
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text('No se captó texto. Habla cerca del micrófono e inténtalo de nuevo.'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
      return;
    }

    await _submit(text);
  }

  Future<void> _onMicTap() async {
    if (_isSubmitting) return;

    if (_isListening) {
      await _stopListeningAndSend();
      return;
    }

    await _startListening();
  }

  Future<void> _submit(String text) async {
    setState(() {
      _isSubmitting = true;
      _error = null;
      _result = null;
    });

    try {
      final response = await widget.service.sendMeetingRequest(text);
      if (!mounted) return;
      setState(() {
        _result = response.toJsonPretty();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearAll() {
    setState(() {
      _spokenText = '';
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Instrucción por voz',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pulsa el micrófono, dicta la reunión y vuelve a pulsar para enviar automáticamente a n8n.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  _buildMicButton(theme, cs),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _statusLabel,
                      key: ValueKey(_statusLabel),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Vista previa',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: _isSubmitting
                      ? Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Enviando a tu workflow…',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _spokenText.isEmpty
                              ? 'El texto reconocido aparecerá aquí mientras hablas.'
                              : _spokenText,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.4,
                            color: _spokenText.isEmpty
                                ? cs.onSurfaceVariant
                                : cs.onSurface,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isListening || _isSubmitting ? null : _clearAll,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Limpiar'),
              ),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              InfoCard(
                title: 'Error',
                content: _error!,
                color: cs.error,
              ),
            if (_result != null) ...[
              const SizedBox(height: 4),
              InfoCard(
                title: 'Respuesta del workflow',
                content: _result!,
                color: cs.tertiary,
              ),
            ],
            const SizedBox(height: 16),
            InfoCard(
              title: 'Consejo',
              content:
                  'Asegúrate de que la URL del webhook en la app apunte a tu n8n en producción.',
              color: cs.primary,
            ),
          ],
        ),
      ),
    );
  }

  String get _statusLabel {
    if (_isSubmitting) return 'Enviando solicitud…';
    if (_isListening) return 'Escuchando… toca de nuevo para enviar';
    if (!_speechAvailable) return 'Voz no disponible en este dispositivo';
    return 'Toca el micrófono para empezar';
  }

  Widget _buildMicButton(ThemeData theme, ColorScheme cs) {
    final listening = _isListening;
    final disabled = _isSubmitting || !_speechAvailable;

    final baseColor = listening ? cs.error : cs.primary;
    final icon = listening ? Icons.stop_rounded : Icons.mic_rounded;

    Widget button = Material(
      elevation: listening ? 8 : 4,
      shadowColor: baseColor.withValues(alpha: 0.45),
      color: disabled && !listening ? cs.surfaceContainerHighest : baseColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : _onMicTap,
        child: SizedBox(
          width: 112,
          height: 112,
          child: Icon(
            icon,
            size: 52,
            color: disabled && !listening
                ? cs.onSurfaceVariant
                : (listening ? cs.onError : cs.onPrimary),
          ),
        ),
      ),
    );

    if (listening) {
      button = ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.06).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: button,
      );
    }

    return Semantics(
      button: true,
      label: listening
          ? 'Detener y enviar instrucción'
          : 'Empezar a grabar instrucción por voz',
      child: button,
    );
  }
}
