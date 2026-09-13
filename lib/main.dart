import 'package:flutter/material.dart';

import 'appointment_store.dart';
import 'appointments_page.dart';
import 'booking_page.dart';
import 'schedule_settings_page.dart';
import 'team_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppointmentStore.initializeCloud();
  runApp(const BarbeariaAgendaApp());
}

class BarbeariaAgendaApp extends StatelessWidget {
  const BarbeariaAgendaApp({super.key});

  static const _background = Color(0xFF111111);
  static const _surface = Color(0xFF1B1B1B);
  static const _gold = Color(0xFFD7A84B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbearia Agenda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme.dark(
          primary: _gold,
          secondary: _gold,
          surface: _surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _gold = Color(0xFFD7A84B);
  static const _card = Color(0xFF1D1D1D);

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              const SizedBox(height: 26),
              _hero(context),
              const SizedBox(height: 28),
              const Text(
                'O que você deseja fazer?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.08,
                children: [
                  _HomeActionCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Agendar horário',
                    subtitle: 'Escolha serviço, barbeiro e horário',
                    highlighted: true,
                    onTap: () => _open(context, const BookingPage()),
                  ),
                  _HomeActionCard(
                    icon: Icons.event_available_rounded,
                    title: 'Meus agendamentos',
                    subtitle: 'Veja seus próximos horários',
                    onTap: () => _open(context, const AppointmentsPage()),
                  ),
                  _HomeActionCard(
                    icon: Icons.schedule_rounded,
                    title: 'Horários',
                    subtitle: 'Configure funcionamento e equipe',
                    onTap: () => _open(context, const ScheduleSettingsPage()),
                  ),
                  _HomeActionCard(
                    icon: Icons.groups_2_rounded,
                    title: 'Barbeiros',
                    subtitle: 'Equipe e fotos dos profissionais',
                    onTap: () => _open(context, const TeamPage()),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: _gold, size: 27),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atendimento com hora marcada',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Escolha o melhor horário para você.',
                            style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return const Row(
      children: [
        _Logo(),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BARBEARIA',
                style: TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Barbearia Agenda',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Icon(Icons.account_circle_outlined, color: Colors.white70, size: 30),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2317), Color(0xFF171717)],
        ),
        border: Border.all(color: const Color(0xFF3A3224)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SEU VISUAL, SEU HORÁRIO',
            style: TextStyle(
              color: _gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hora de renovar\no visual?',
            style: TextStyle(
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Agende seu atendimento em poucos passos.',
            style: TextStyle(color: Color(0xFFC4C4C4), fontSize: 15),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _open(context, const BookingPage()),
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text(
                'AGENDAR AGORA',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFD7A84B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.content_cut_rounded, color: Colors.black, size: 28),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFF282115) : const Color(0xFF1D1D1D),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted ? const Color(0xFF5A4522) : Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7A84B).withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFFD7A84B), size: 24),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9D9D9D),
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
