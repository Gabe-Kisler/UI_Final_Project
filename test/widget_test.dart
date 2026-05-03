import 'package:flutter_test/flutter_test.dart';
import 'package:shiftsync/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShiftSyncApp());
    expect(find.text('ShiftSync'), findsOneWidget);
  });
}
