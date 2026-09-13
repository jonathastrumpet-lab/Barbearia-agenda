import 'package:flutter/material.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  static const _gold = Color(0xFFD7A84B);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Barbeiros')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Equipe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('As fotos poderão ser escolhidas pela Galeria ou Câmera e salvas na nuvem.', style: TextStyle(color: Colors.white60, fontSize: 15)),
            const SizedBox(height: 22),
            for (final name in const ['Carlos', 'Rafael', 'Bruno']) ...[
              _BarberCard(name: name),
              const SizedBox(height: 14),
            ],
          ],
        ),
      );
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1D1D1D), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: Row(children: [
          const CircleAvatar(radius: 31, backgroundColor: Color(0xFF2B2418), child: Icon(Icons.person_rounded, color: TeamPage._gold, size: 34)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Barbeiro', style: TextStyle(color: Colors.white54))])),
          IconButton.filledTonal(
            tooltip: 'Trocar foto',
            onPressed: () => _showPhotoOptions(context, name),
            icon: const Icon(Icons.photo_camera_outlined),
          ),
        ]),
      );

  void _showPhotoOptions(BuildContext context, String name) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trocar foto de $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Galeria'), onTap: () => _comingSoon(sheetContext)),
            ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Câmera'), onTap: () => _comingSoon(sheetContext)),
            ListTile(leading: const Icon(Icons.close), title: const Text('Cancelar'), onTap: () => Navigator.pop(sheetContext)),
          ]),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleção e envio da foto serão ativados ao conectar o armazenamento na nuvem.')));
  }
}
