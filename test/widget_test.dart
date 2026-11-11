import 'package:flutter_test/flutter_test.dart';
import 'package:phishguard/main.dart';

void main() {
  testWidgets('shows the PhishGuard home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PhishGuardApp());
    expect(find.text('PhishGuard'), findsOneWidget);
    expect(find.text('Analyse'), findsOneWidget);
  });
}