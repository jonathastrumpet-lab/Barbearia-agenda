import 'package:flutter/material.dart';
import 'appointment_store.dart';

class PlatformAdminPage extends StatelessWidget {
  const PlatformAdminPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!AppointmentStore.isPlatformAdmin) {
      return const Scaffold(body: Center(child: Text('Acesso não autorizado.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Administração Geral')),
      body: const SafeArea(child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AGENDA HUB', style: TextStyle(color: Color(0xFFD7A84B), fontWeight: FontWeight.w900, letterSpacing: 2)),
          SizedBox(height: 12),
          Text('Painel Geral', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          SizedBox(height: 10),
          Text('Área exclusiva do Administrador Geral. Assinaturas, limites e permissões serão gerenciados aqui.', style: TextStyle(color: Colors.white60)),
        ]),
      )),
    );
  }
}
