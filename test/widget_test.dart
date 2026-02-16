import 'package:flutter_test/flutter_test.dart';
import 'package:medecininterface/main.dart';

void main() {
  testWidgets('MEDAIChain app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MEDAIChainApp());
    expect(find.text('MEDAIChain'), findsOneWidget);
  });
}
