import 'package:barbearia_agenda/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe a tela inicial da barbearia', (tester) async {
    await tester.pumpWidget(const BarbeariaAgendaApp());

    expect(find.text('Barbearia Agenda'), findsOneWidget);
    expect(find.text('Agenda da Barbearia'), findsOneWidget);
  });
}
