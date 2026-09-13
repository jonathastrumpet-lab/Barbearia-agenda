import 'package:barbearia_agenda/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe a tela inicial profissional da barbearia', (tester) async {
    await tester.pumpWidget(const BarbeariaAgendaApp());

    expect(find.text('Barbearia Agenda'), findsOneWidget);
    expect(find.text('Agendar horário'), findsOneWidget);
    expect(find.text('Meus agendamentos'), findsOneWidget);
    expect(find.text('Serviços'), findsOneWidget);
    expect(find.text('Barbeiros'), findsOneWidget);
  });
}
