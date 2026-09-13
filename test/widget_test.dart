import 'package:barbearia_agenda/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe login seguro antes de abrir a agenda', (tester) async {
    await tester.pumpWidget(const BarbeariaAgendaApp());
    await tester.pumpAndSettle();

    expect(find.text('Entrar na Barbearia Agenda'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('Criar conta da barbearia'), findsOneWidget);
  });
}
