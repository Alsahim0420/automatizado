import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'meeting_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reunión manual',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completa los datos y la app enviará la solicitud al workflow de n8n.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la persona',
                  border: fieldBorder,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre de la persona.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: fieldBorder,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Seleccionar fecha'
                            : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? 'Seleccionar hora'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duración en minutos',
                  border: fieldBorder,
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Tema o descripción',
                  border: fieldBorder,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Enviando…' : 'Agendar reunión'),
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                InfoCard(
                  title: 'Error',
                  content: _error!,
                  color: cs.error,
                ),
              if (_result != null)
                InfoCard(
                  title: 'Respuesta del workflow',
                  content: _result!,
                  color: cs.tertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
