import 'package:flutter_test/flutter_test.dart';
import 'package:medecininterface/main.dart';

void main() {
  testWidgets('MEDAIChain app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MEDAIChainApp());

    // Verify that the login screen is displayed.
    expect(find.text('MEDAIChain'), findsOneWidget);
  });
}
