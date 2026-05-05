import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ShiftSyncApp());
}

class ShiftSyncApp extends StatefulWidget {
  const ShiftSyncApp({super.key});

  @override
  State<ShiftSyncApp> createState() => _ShiftSyncAppState();
}

class _ShiftSyncAppState extends State<ShiftSyncApp> {
  final AppController _controller = AppController();

  @override
  Widget build(BuildContext context) {
    return ShiftSyncScope(
      controller: _controller,
      child: MaterialApp(
        title: 'ShiftSync',
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
