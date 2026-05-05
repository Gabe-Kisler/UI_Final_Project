import 'package:flutter/widgets.dart';

import 'services/app_controller.dart';

class ShiftSyncScope extends InheritedNotifier<AppController> {
  const ShiftSyncScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShiftSyncScope>();
    assert(scope != null, 'ShiftSyncScope not found in widget tree.');
    return scope!.notifier!;
  }
}
