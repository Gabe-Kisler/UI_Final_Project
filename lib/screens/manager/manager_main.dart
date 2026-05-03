import 'package:flutter/material.dart';
import 'manager_home.dart';
import 'manager_schedule.dart';
import 'manager_employees.dart';
import 'manager_analytics.dart';

class ManagerMain extends StatefulWidget {
  const ManagerMain({super.key});

  @override
  State<ManagerMain> createState() => _ManagerMainState();
}

class _ManagerMainState extends State<ManagerMain> {
  int _selectedIndex = 0;

  static const _screens = [
    ManagerHome(),
    ManagerSchedule(),
    ManagerEmployees(),
    ManagerAnalytics(),
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
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

