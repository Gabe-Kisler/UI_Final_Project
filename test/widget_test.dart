import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftsync/firebase_options.dart';
import 'package:shiftsync/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') {
        rethrow;
      }
    }
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShiftSyncApp());
    expect(find.text('ShiftSync'), findsOneWidget);
  });
}
