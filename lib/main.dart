import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/role_select_screen.dart';

void main() {
  runApp(const ShiftSyncApp());
}

class ShiftSyncApp extends StatelessWidget {
  const ShiftSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftSync',
      theme: AppTheme.darkTheme,
      home: const RoleSelectScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
