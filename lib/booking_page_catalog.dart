import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'appointment_store.dart';
import 'barber_store.dart';
import 'service_store.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  static const _gold = Color(0xFFD7A84B);
  static const _card = Color(0xFF1D1D1D);
  static const _uuid = Uuid();

  final List<String> _times = const [
    '09:00', '10:00', '11:00', '13:30', '14:30', '15:30', '17:00', '18:00',
  ];

  List<ServiceRecord> _services = const [];
  List<BarberRecord> _barbers = const [];
  int _serviceIndex = 0;
  int _barberIndex = 0;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  Set<String> _occupiedTimes = <String>{};
  bool _loadingCatalog = true;
  bool _loadingAvailability = false;
  bool _saving = false;
  int _availabilityRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loadingCatalog = true);
    try {
      final results = await Future.wait<dynamic>([
        ServiceStore.loadActive(),
        BarberStore.loadActive(),
      ]);
      if (!mounted) return;
      setState(() {
        _services = results[0] as List<ServiceRecord>;
        _barbers = results[1] as List<BarberRecord>;
        _serviceIndex = 0;
        _barberIndex = 0;
        _selectedTime = null;
        _loadingCatalog = false;
      });
      if (_barbers.isNotEmpty) await _refreshAvailability();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _services = const [];
        _barbers = const [];
        _loadingCatalog = false;
        _loadingAvailability = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os serviços e profissionais deste estabelecimento.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _dateIso() => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ).toIso8601String();

  Future<void> _refreshAvailability() async {
    if (_barbers.isEmpty || _barberIndex >= _barbers.length) {
      if (mounted) setState(() => _occupiedTimes = <String>{});
      return;
    }
    final request = ++_availabilityRequest;
    setState(() => _loadingAvailability = true);
    try {
      final rows = await AppointmentStore.client
          .from('appointments')
          .select('time')
          .eq('barbershop_id', AppointmentStore.shopId!)
          .eq('barber', _barbers[_barberIndex].name)
          .eq('date_iso', _dateIso())
          .eq('status', 'scheduled');
      final occupied = (rows as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['time']?.toString())
          .whereType<String>()
          .toSet();
      if (!mounted || request != _availabilityRequest) return;
      setState(() {
        _occupiedTimes = occupied;
        if (_selectedTime != null && occupied.contains(_selectedTime)) {
          _selectedTime = null;
        }
        _loadingAvailability = false;
      });
    } catch (_) {
      if (!mounted || request != _availabilityRequest) return;
      setState(() {
        _occupiedTimes = <String>{};
        _loadingAvailability = false;
      });
    }
  }

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
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _selectedTime = null;
    });
    await _refreshAvailability();
  }

  Future<void> _confirmBooking() async {
    if (_services.isEmpty) {
      _message('Este estabelecimento ainda não possui serviços ativos.');
      return;
    }
    if (_barbers.isEmpty) {
      _message('Este estabelecimento ainda não possui profissionais ativos.');
      return;
    }
    if (_selectedTime == null) {
      _message('Escolha um horário para continuar.');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);

    final service = _services[_serviceIndex];
    final barber = _barbers[_barberIndex].name;
    final time = _selectedTime!;
    final appointment = Appointment(
      id: _uuid.v4(),
      service: service.name,
      duration: service.formattedDuration,
      price: service.formattedPrice,
      barber: barber,
      dateIso: _dateIso(),
      time: time,
      createdAtIso: DateTime.now().toIso8601String(),
    );

    try {
      await AppointmentStore.add(appointment);
    } on AppointmentConflictException {
      if (!mounted) return;
      setState(() => _saving = false);
      await _refreshAvailability();
      if (mounted) _message('Esse horário acabou de ser reservado. Escolha outro horário.');
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('Não foi possível sincronizar o agendamento com a nuvem.');
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Text('Agendamento confirmado'),
        content: Text(
          '${service.name}\n$barber • ${_formatDate(_selectedDate)} às $time\n${service.formattedPrice} • ${service.formattedDuration}',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final selectedService = _services.isEmpty ? null : _services[_serviceIndex];
    final selectedBarber = _barbers.isEmpty ? null : _barbers[_barberIndex];
    final blocked = _loadingCatalog || _services.isEmpty || _barbers.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Agendar horário', style: TextStyle(fontWeight: FontWeight.w800))),
      body: RefreshIndicator(
        onRefresh: _loadCatalog,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monte seu atendimento', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Escolha serviço, profissional, dia e horário.', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 26),
              _title('1', 'Serviço', _loadingCatalog),
              const SizedBox(height: 12),
              if (!_loadingCatalog && _services.isEmpty)
                _empty('Nenhum serviço ativo neste estabelecimento no momento.')
              else
                for (var i = 0; i < _services.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChoiceTile(
                      selected: _serviceIndex == i,
                      title: _services[i].name,
                      subtitle: _services[i].formattedDuration,
                      trailing: _services[i].formattedPrice,
                      onTap: () => setState(() => _serviceIndex = i),
                    ),
                  ),
              const SizedBox(height: 18),
              _title('2', 'Profissional', _loadingCatalog),
              const SizedBox(height: 12),
              if (!_loadingCatalog && _barbers.isEmpty)
                _empty('Nenhum profissional ativo neste estabelecimento no momento.')
              else if (_barbers.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _barbers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final selected = _barberIndex == i;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(_barbers[i].name),
                        onSelected: (_) {
                          setState(() {
                            _barberIndex = i;
                            _selectedTime = null;
                          });
                          _refreshAvailability();
                        },
                        selectedColor: _gold,
                        backgroundColor: _card,
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 28),
              _title('3', 'Data', false),
              const SizedBox(height: 12),
              Material(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: blocked ? null : _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: _gold),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w800))),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _title('4', 'Horário', _loadingAvailability),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _times.map((time) {
                  final occupied = _occupiedTimes.contains(time);
                  final selected = _selectedTime == time;
                  final disabled = blocked || occupied || _loadingAvailability;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(occupied ? '$time • Reservado' : time),
                    onSelected: disabled ? null : (_) => setState(() => _selectedTime = time),
                    selectedColor: _gold,
                    backgroundColor: _card,
                    disabledColor: occupied ? Colors.redAccent.withValues(alpha: .12) : Colors.white10,
                    labelStyle: TextStyle(
                      color: occupied ? Colors.redAccent : selected ? Colors.black : disabled ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    side: BorderSide(
                      color: occupied ? Colors.redAccent.withValues(alpha: .65) : selected ? _gold : Colors.white12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF242015),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF4C3B1D)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Resumo', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text(
                    selectedService == null
                        ? 'Nenhum serviço selecionável'
                        : '${selectedService.name} • ${selectedService.formattedPrice} • ${selectedService.formattedDuration}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    selectedBarber == null
                        ? 'Nenhum profissional selecionável'
                        : '${selectedBarber.name} • ${_formatDate(_selectedDate)}${_selectedTime == null ? '' : ' • $_selectedTime'}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving || blocked ? null : _confirmBooking,
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'SINCRONIZANDO...' : 'CONFIRMAR AGENDAMENTO', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String number, String title, bool loading) => Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
          child: Text(number, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        if (loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      ]);

  Widget _empty(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
        child: Text(text, style: const TextStyle(color: Colors.white60)),
      );
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
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFF292216) : const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? _BookingPageState._gold : Colors.white12),
            ),
            child: Row(children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? _BookingPageState._gold : Colors.white38),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white60)),
              ])),
              Text(trailing, style: const TextStyle(color: _BookingPageState._gold, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      );
}
