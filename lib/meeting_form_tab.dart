import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'meeting_service.dart';
import 'theme/app_colors.dart';
import 'ui/meeting_outcome_presenter.dart';
import 'widgets/glass_card.dart';
import 'widgets/info_card.dart';

class MeetingFormTab extends StatefulWidget {
  const MeetingFormTab({
    super.key,
    required this.service,
  });

  final MeetingService service;

  @override
  State<MeetingFormTab> createState() => _MeetingFormTabState();
}

class _MeetingFormTabState extends State<MeetingFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '60');

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  String? _result;
  String? _error;

  static const _iconColor = Color(0xFF94A3B8);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (result == null) return;
    setState(() {
      _selectedDate = result;
    });
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (result == null) return;
    setState(() {
      _selectedTime = result;
    });
  }

  String _buildPromptFromForm() {
    final date = _selectedDate!;
    final time = _selectedTime!;
    final dateText = DateFormat('yyyy-MM-dd').format(date);
    final timeText = _formatTime24(time);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final minutes = _durationController.text.trim();
    final description = _descriptionController.text.trim();

    final base =
        'Cuádrame una reunión con $name, correo $email, el $dateText a las $timeText, por $minutes minutos';

    if (description.isEmpty) return '$base.';
    return '$base. Tema: $description.';
  }

  String _formatTime24(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      setState(() {
        _error = 'Selecciona fecha y hora para continuar.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _result = null;
    });

    try {
      final prompt = _buildPromptFromForm();
      final response = await widget.service.sendMeetingRequest(prompt);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: GlassCard(
        child: Form(
          key: _formKey,
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Manual',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Nueva reunión',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completa los datos; la app construye el mensaje y lo envía a tu workflow de n8n.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la persona',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: _iconColor),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre de la persona.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.alternate_email_rounded, color: _iconColor),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el correo.';
                  }
                  final email = value.trim();
                  final valid =
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                  if (!valid) return 'Ingresa un correo válido.';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Fecha y hora',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DateTimeChip(
                      icon: Icons.calendar_month_rounded,
                      label: _selectedDate == null
                          ? 'Fecha'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTimeChip(
                      icon: Icons.schedule_rounded,
                      label: _selectedTime == null
                          ? 'Hora'
                          : _selectedTime!.format(context),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duración (minutos)',
                  prefixIcon: Icon(Icons.timelapse_rounded, color: _iconColor),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la duración.';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa una duración válida.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Tema o descripción',
                  hintText: 'Opcional — agenda, enlaces, notas…',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.short_text_rounded, color: _iconColor),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              _GradientCta(
                onPressed: _isSubmitting ? null : _submit,
                isLoading: _isSubmitting,
                label: _isSubmitting ? 'Enviando…' : 'Agendar reunión',
              ),
              const SizedBox(height: 22),
              if (_error != null)
                InfoCard(
                  title: 'Algo salió mal',
                  content: _error!,
                  color: cs.error,
                  icon: Icons.error_outline_rounded,
                ),
              if (_result != null) ...[
                const SizedBox(height: 12),
                InfoCard(
                  title: 'Respuesta del workflow',
                  content: _result!,
                  color: AppColors.primary,
                  icon: Icons.data_object_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeChip extends StatelessWidget {
  const _DateTimeChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _MeetingFormTabState._iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onPressed == null;

    return AnimatedOpacity(
      opacity: disabled && !isLoading ? 0.55 : 1,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled && !isLoading ? null : AppColors.ctaGradient,
          color: disabled && !isLoading ? const Color(0xFFE2E8F0) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!disabled || isLoading)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.38),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
