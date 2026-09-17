// CI validation branch for APK build - retrigger
import 'package:flutter/material.dart';

import 'appointment_store.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  static const _gold = Color(0xFFD7A84B);
  late Future<List<Appointment>> _appointments;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _appointments = AppointmentStore.load();
  }

  Future<void> _cancel(Appointment appointment) async {
    if (appointment.isCancelled) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Text('Cancelar agendamento?'),
        content: Text(
          '${appointment.service}\n${appointment.barber} • ${_formatDate(appointment.date)} às ${appointment.time}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar horário'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AppointmentStore.remove(appointment.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppointmentStore.cloudEnabled
                ? 'Não foi possível cancelar na nuvem. Tente novamente.'
                : 'Não foi possível cancelar o agendamento.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Agendamento cancelado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _clientDisplayName(Appointment appointment) {
    final name = appointment.clientName?.trim();
    if (name?.isNotEmpty == true) return name!;

    final email = appointment.clientEmail?.trim();
    if (email == 'jonathas.trumpet@gmail.com') return email!;

    return 'Cliente não identificado';
  }

  String _cancellationOrigin(Appointment appointment) {
    if (appointment.cancelledBy == 'client') return 'Cancelado pelo CLIENTE';
    if (appointment.cancelledBy == 'admin') return 'Cancelado pelo DONO/ADMIN';
    return 'Origem do cancelamento não registrada';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus agendamentos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<Appointment>>(
        future: _appointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <Appointment>[];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy_rounded, color: _gold, size: 58),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum agendamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Quando você confirmar um horário, ele aparecerá aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _appointments;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final cancelled = item.isCancelled;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1D1D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cancelled ? Colors.redAccent.withValues(alpha: 0.45) : Colors.white12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            cancelled ? Icons.event_busy_rounded : Icons.event_available_rounded,
                            color: cancelled ? Colors.redAccent : _gold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.service,
                              style: TextStyle(
                                color: cancelled ? Colors.white70 : Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                decoration: cancelled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          Text(
                            item.price,
                            style: TextStyle(
                              color: cancelled ? Colors.white54 : _gold,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_formatDate(item.date)} às ${item.time}',
                        style: TextStyle(
                          color: cancelled ? Colors.white60 : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${item.barber} • ${item.duration}',
                        style: const TextStyle(color: Color(0xFFAAAAAA)),
                      ),
                      if (AppointmentStore.isAdmin) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Cliente: ${_clientDisplayName(item)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'E-mail: ${item.clientEmail?.trim().isNotEmpty == true ? item.clientEmail : 'E-mail não identificado'}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(color: Color(0xFFAAAAAA)),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (cancelled)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CANCELADO',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _cancellationOrigin(item),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _cancel(item),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('CANCELAR AGENDAMENTO'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
