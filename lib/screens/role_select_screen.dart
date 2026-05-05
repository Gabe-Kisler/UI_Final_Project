import 'package:flutter/widgets.dart';

import 'auth/auth_gate.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthGate();
}
