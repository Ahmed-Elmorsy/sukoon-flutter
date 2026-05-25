import 'package:flutter_test/flutter_test.dart';
import 'package:skoon/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SkoonApp());
    expect(find.text('Skoon'), findsOneWidget);
  });
}
