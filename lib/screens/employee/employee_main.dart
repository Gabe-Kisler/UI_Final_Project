import 'package:flutter/material.dart';
import 'employee_home.dart';
import 'employee_schedule.dart';
import 'employee_pay.dart';

class EmployeeMain extends StatefulWidget {
  const EmployeeMain({super.key});

  @override
  State<EmployeeMain> createState() => _EmployeeMainState();
}

class _EmployeeMainState extends State<EmployeeMain> {
  int _selectedIndex = 0;

  static const _screens = [
    EmployeeHome(),
    EmployeeSchedule(),
    EmployeePay(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money),
            label: 'Pay',
          ),
        ],
      ),
    );
  }
}
