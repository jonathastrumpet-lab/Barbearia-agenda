import 'package:flutter/material.dart';
import 'appointment_store.dart';
import 'barber_store.dart';

class ScheduleBlocksPage extends StatefulWidget {
  const ScheduleBlocksPage({super.key});
  @override
  State<ScheduleBlocksPage> createState() => _ScheduleBlocksPageState();
}

class _ScheduleBlocksPageState extends State<ScheduleBlocksPage> {
  static const gold = Color(0xFFD7A84B);
  DateTime date = DateTime.now();
  int start = 900, end = 960;
  bool loading = true, saving = false;
  String? barberId;
  List<BarberRecord> barbers = [];
  List<Map<String, dynamic>> blocks = [];

  String hm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  String ds(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final shop = AppointmentStore.shopId;
    if (shop == null) return;
    setState(() => loading = true);
    try {
      barbers = await BarberStore.loadAll();
      final r = await AppointmentStore.client
          .from('schedule_blocks')
          .select('id,barber_id,block_date,start_minutes,end_minutes,reason')
          .eq('barbershop_id', shop)
          .gte('block_date', ds(DateTime.now()))
          .order('block_date')
          .order('start_minutes');
      blocks = (r as List).cast<Map<String, dynamic>>();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<int?> pickTime(int initial) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  Future<void> save() async {
    if (end <= start) {
      msg('O fim deve ser depois do início.');
      return;
    }
    setState(() => saving = true);
    try {
      // Validação no app antes do RPC: não permite criar bloqueio que
      // sobreponha qualquer agendamento ativo do mesmo profissional/data.
      // A regra de sobreposição é: blockStart < appointmentEnd &&
      // blockEnd > appointmentStart. Horários encostados (ex.: 17-18 e
      // 18-19) continuam permitidos.
      final shop = AppointmentStore.shopId;
      if (shop == null) {
        msg('Estabelecimento não selecionado.');
        return;
      }

      final selectedBarber = barberId == null
          ? null
          : barbers.where((b) => b.id == barberId).firstOrNull;
      if (barberId != null && selectedBarber == null) {
        msg('Profissional não encontrado.');
        return;
      }

      final dayStart =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final dayEnd =
          DateTime(date.year, date.month, date.day + 1).toIso8601String();

      dynamic appointmentQuery = AppointmentStore.client
          .from('appointments')
          .select('time,duration,barber')
          .eq('barbershop_id', shop)
          .eq('status', 'scheduled')
          .gte('date_iso', dayStart)
          .lt('date_iso', dayEnd);

      if (selectedBarber != null) {
        appointmentQuery = appointmentQuery.eq('barber', selectedBarber.name);
      }

      final appointmentRows = await appointmentQuery;
      final hasConflict = (appointmentRows as List<dynamic>).any((raw) {
        final row = raw as Map<String, dynamic>;
        final parts = (row['time']?.toString() ?? '').split(':');
        if (parts.length < 2) return false;
        final appointmentStart =
            int.tryParse(parts[0]) == null || int.tryParse(parts[1]) == null
                ? null
                : int.parse(parts[0]) * 60 + int.parse(parts[1]);
        if (appointmentStart == null) return false;

        // duration hoje é persistida como texto (ex.: "60 min" / "1h").
        // Extrai minutos de forma compatível com os formatos existentes.
        final durationText = row['duration']?.toString().toLowerCase() ?? '';
        int durationMinutes = 60;
        final hourMatch = RegExp(r'(\\d+)\\s*h').firstMatch(durationText);
        final minuteMatch =
            RegExp(r'(\\d+)\\s*(?:min|m)').firstMatch(durationText);
        if (hourMatch != null) {
          durationMinutes = int.parse(hourMatch.group(1)!) * 60;
          if (minuteMatch != null) {
            durationMinutes += int.parse(minuteMatch.group(1)!);
          }
        } else if (minuteMatch != null) {
          durationMinutes = int.parse(minuteMatch.group(1)!);
        } else {
          final number = RegExp(r'\\d+').firstMatch(durationText);
          if (number != null) durationMinutes = int.parse(number.group(0)!);
        }
        if (durationMinutes <= 0) durationMinutes = 60;

        final appointmentEnd = appointmentStart + durationMinutes;
        return start < appointmentEnd && end > appointmentStart;
      });

      if (hasConflict) {
        msg(
            'Não é possível bloquear este período. Já existe um agendamento ativo para este profissional.');
        return;
      }

      await AppointmentStore.client.rpc('create_schedule_block', params: {
        'p_barbershop_id': AppointmentStore.shopId,
        'p_block_date': ds(date),
        'p_start_minutes': start,
        'p_end_minutes': end,
        'p_barber_id': barberId,
        'p_reason': null,
      });
      msg('Horário bloqueado.');
      await load();
    } catch (e) {
      final s = e.toString();
      if (s.contains('EXISTING_APPOINTMENTS')) {
        msg('Já existe agendamento nesse período.');
      } else if (s.contains('OVERLAPPING_BLOCK')) {
        msg('Esse período cruza outro bloqueio.');
      } else if (s.contains('DAY_CLOSED')) {
        msg('Esse dia está fechado.');
      } else if (s.contains('OUTSIDE_BUSINESS_HOURS')) {
        msg('Bloqueio fora do horário de funcionamento.');
      } else {
        msg('Não foi possível bloquear o horário.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> remove(String id) async {
    await AppointmentStore.client.from('schedule_blocks').delete().eq('id', id);
    await load();
  }

  void msg(String x) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Bloquear horário',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text('Bloqueio parcial',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Feche apenas algumas horas sem fechar o dia inteiro.',
                      style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 18),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month, color: gold),
                      title: const Text('Data'),
                      subtitle: Text(
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
                      onTap: () async {
                        final x = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (x != null) setState(() => date = x);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: barberId,
                    decoration: const InputDecoration(labelText: 'Aplicar a'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todo o estabelecimento'),
                      ),
                      ...barbers.map((b) => DropdownMenuItem<String?>(
                            value: b.id,
                            child: Text(b.name),
                          )),
                    ],
                    onChanged: (v) => setState(() => barberId = v),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final v = await pickTime(start);
                            if (v != null) setState(() => start = v);
                          },
                          child: Text('Início  ${hm(start)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final v = await pickTime(end);
                            if (v != null) setState(() => end = v);
                          },
                          child: Text('Fim  ${hm(end)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: const Icon(Icons.block),
                    label: Text(
                      saving ? 'SALVANDO...' : 'SALVAR BLOQUEIO',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Próximos bloqueios',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  if (blocks.isEmpty)
                    const Text('Nenhum bloqueio cadastrado.',
                        style: TextStyle(color: Colors.white60)),
                  ...blocks.map((x) {
                    final bid = x['barber_id']?.toString();
                    final who = bid == null
                        ? 'Todo o estabelecimento'
                        : barbers.any((b) => b.id == bid)
                            ? barbers.firstWhere((b) => b.id == bid).name
                            : 'Profissional';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.block, color: gold),
                        title: Text(
                            "${x['block_date']} • ${hm(x['start_minutes'] as int)} às ${hm(x['end_minutes'] as int)}"),
                        subtitle: Text(who),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => remove(x['id'].toString()),
                        ),
                      ),
                    );
                  }),
                ],
              ),
      );
}
