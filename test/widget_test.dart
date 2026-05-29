import 'package:flutter_test/flutter_test.dart';
import 'package:notes_v1/main.dart';

void main() {
  testWidgets('Notes app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    expect(find.text('Notes V1'), findsOneWidget);
  });
}
