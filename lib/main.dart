import 'package:flutter/material.dart';

void main() {
  runApp(const BarbeariaAgendaApp());
}

class BarbeariaAgendaApp extends StatelessWidget {
  const BarbeariaAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbearia Agenda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black87),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barbearia Agenda'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_cut, size: 72),
            SizedBox(height: 16),
            Text(
              'Agenda da Barbearia',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Projeto inicial configurado com sucesso.'),
          ],
        ),
      ),
    );
  }
}
