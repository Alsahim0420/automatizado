import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'meeting_service.dart';
import 'theme/app_colors.dart';
import 'ui/meeting_outcome_presenter.dart';
import 'widgets/glass_card.dart';
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

    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final text = _spokenText.trim();
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: const Color(0xFF1E293B),
          content: const Text(
            'No se captó texto. Habla cerca del micrófono e inténtalo de nuevo.',
          ),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white70,
            onPressed: () {},
          ),
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
      presentMeetingOutcome(
        context,
        response,
        setState: setState,
        setError: (e) => _error = e,
        setResult: (r) => _result = r,
      );
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Voz',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Dictado inteligente',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Un solo botón: pulsa para grabar, pulsa otra vez y se envía solo a n8n.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                Center(
                  child: Column(
                    children: [
                      _buildMicHero(),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _statusLabel,
                          key: ValueKey(_statusLabel),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transcripción',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          _isListening || _isSubmitting ? null : _clearAll,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Limpiar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
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
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _spokenText.isEmpty
                              ? 'Habla con naturalidad: horarios, correos, nombres…'
                              : _spokenText,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                            color: _spokenText.isEmpty
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            InfoCard(
              title: 'No se pudo enviar',
              content: _error!,
              color: cs.error,
              icon: Icons.cloud_off_rounded,
            ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            InfoCard(
              title: 'Respuesta del workflow',
              content: _result!,
              color: AppColors.primary,
              icon: Icons.data_object_rounded,
            ),
          ],
          const SizedBox(height: 8),
          const InfoCard(
            title: 'Webhook',
            content:
                'Configura la URL de producción de n8n en el código (MeetingService).',
            color: AppColors.primary,
            icon: Icons.link_rounded,
          ),
        ],
      ),
    );
  }

  String get _statusLabel {
    if (_isSubmitting) return 'Enviando solicitud…';
    if (_isListening) return 'Escuchando — toca de nuevo para enviar';
    if (!_speechAvailable) return 'Voz no disponible en este dispositivo';
    return 'Toca el anillo para empezar';
  }

  Widget _buildMicHero() {
    final listening = _isListening;
    final disabled = _isSubmitting || !_speechAvailable;
    final baseColor = listening ? const Color(0xFFEF4444) : AppColors.primary;
    final icon = listening ? Icons.stop_rounded : Icons.mic_rounded;

    Widget core = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : _onMicTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: disabled && !listening
                ? null
                : (listening
                    ? const LinearGradient(
                        colors: [Color(0xFFF87171), Color(0xFFEF4444)],
                      )
                    : AppColors.heroAccent),
            color: disabled && !listening ? const Color(0xFFE2E8F0) : null,
            boxShadow: [
              if (!disabled || listening)
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
            ],
          ),
          child: Icon(
            icon,
            size: 48,
            color:
                disabled && !listening ? const Color(0xFF94A3B8) : Colors.white,
          ),
        ),
      ),
    );

    if (listening) {
      core = ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.05).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: core,
      );
    }

    return Semantics(
      button: true,
      label: listening ? 'Detener y enviar' : 'Empezar a grabar',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: listening
                ? const Color(0xFFF87171).withValues(alpha: 0.45)
                : AppColors.primary.withValues(alpha: 0.25),
            width: listening ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppColors.primary.withValues(alpha: listening ? 0.2 : 0.12),
              blurRadius: listening ? 32 : 20,
              spreadRadius: listening ? 2 : 0,
            ),
          ],
        ),
        child: core,
      ),
    );
  }
}
