import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'appointment_store.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  static const Color _gold = Color(0xFFD7A84B);
  static const Color _card = Color(0xFF1D1D1D);
  static const Uuid _uuid = Uuid();

  final List<_ServiceOption> _services = const [
    _ServiceOption('Corte', '45 min', 'R\$ 45'),
    _ServiceOption('Barba', '30 min', 'R\$ 35'),
    _ServiceOption('Corte + Barba', '1h 15 min', 'R\$ 70'),
  ];

  final List<String> _barbers = const ['Carlos', 'Rafael', 'Bruno'];
  final List<String> _times = const [
    '09:00',
    '10:00',
    '11:00',
    '13:30',
    '14:30',
    '15:30',
    '17:00',
    '18:00',
  ];

  int _serviceIndex = 0;
  int _barberIndex = 0;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _saving = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Escolha o dia',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha um horário para continuar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_saving) return;
    setState(() => _saving = true);

    final service = _services[_serviceIndex];
    final barber = _barbers[_barberIndex];
    final time = _selectedTime!;
    final normalizedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final now = DateTime.now();

    final appointment = Appointment(
      id: _uuid.v4(),
      service: service.name,
      duration: service.duration,
      price: service.price,
      barber: barber,
      dateIso: normalizedDate.toIso8601String(),
      time: time,
      createdAtIso: now.toIso8601String(),
    );

    try {
      await AppointmentStore.add(appointment);
    } on AppointmentConflictException {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esse horário acabou de ser reservado. Escolha outro horário.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppointmentStore.cloudEnabled
                ? 'Não foi possível sincronizar o agendamento com a nuvem.'
                : 'Não foi possível salvar o agendamento.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    final date = _formatDate(_selectedDate);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: _gold),
            SizedBox(width: 10),
            Expanded(child: Text('Agendamento confirmado')),
          ],
        ),
        content: Text(
          '${service.name}\n$barber • $date às $time\n${service.price}',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedService = _services[_serviceIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agendar horário',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monte seu atendimento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppointmentStore.cloudEnabled
                    ? 'Agenda sincronizada: escolha serviço, barbeiro, dia e horário.'
                    : 'Escolha serviço, barbeiro, dia e horário.',
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
              ),
              const SizedBox(height: 26),
              _sectionTitle('1', 'Serviço'),
              const SizedBox(height: 12),
              ...List.generate(_services.length, (index) {
                final service = _services[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ChoiceTile(
                    selected: _serviceIndex == index,
                    title: service.name,
                    subtitle: service.duration,
                    trailing: service.price,
                    onTap: () => setState(() => _serviceIndex = index),
                  ),
                );
              }),
              const SizedBox(height: 18),
              _sectionTitle('2', 'Barbeiro'),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _barbers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final selected = _barberIndex == index;
                    return ChoiceChip(
                      selected: selected,
                      label: Text(_barbers[index]),
                      avatar: Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: selected ? Colors.black : _gold,
                      ),
                      onSelected: (_) => setState(() => _barberIndex = index),
                      selectedColor: _gold,
                      backgroundColor: _card,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: selected ? _gold : Colors.white12,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              _sectionTitle('3', 'Data'),
              const SizedBox(height: 12),
              Material(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickDate,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: _gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _sectionTitle('4', 'Horário'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _times.map((time) {
                  final selected = _selectedTime == time;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(time),
                    onSelected: (_) => setState(() => _selectedTime = time),
                    selectedColor: _gold,
                    backgroundColor: _card,
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    side: BorderSide(
                      color: selected ? _gold : Colors.white12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF242015),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF4C3B1D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${selectedService.name} • ${selectedService.price}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_barbers[_barberIndex]} • ${_formatDate(_selectedDate)}${_selectedTime == null ? '' : ' • $_selectedTime'}',
                      style: const TextStyle(color: Color(0xFFBDBDBD)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _confirmBooking,
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving
                        ? (AppointmentStore.cloudEnabled
                            ? 'SINCRONIZANDO...'
                            : 'SALVANDO...')
                        : 'CONFIRMAR AGENDAMENTO',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String number, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _gold,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ServiceOption {
  const _ServiceOption(this.name, this.duration, this.price);

  final String name;
  final String duration;
  final String price;
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD7A84B);

    return Material(
      color: selected ? const Color(0xFF292216) : const Color(0xFF1D1D1D),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? gold : Colors.white12),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? gold : Colors.white38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
              ),
              Text(
                trailing,
                style: const TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
