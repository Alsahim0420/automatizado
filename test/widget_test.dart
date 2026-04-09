import 'package:flutter_test/flutter_test.dart';

import 'package:meeting_assistant_app/meeting_assistant_app.dart';

void main() {
  testWidgets('Muestra pestañas de formulario y voz', (WidgetTester tester) async {
    await tester.pumpWidget(const MeetingAssistantApp());

    expect(find.text('Asistente de reuniones'), findsOneWidget);
    expect(find.text('Formulario'), findsOneWidget);
    expect(find.text('Voz'), findsOneWidget);
  });
}
