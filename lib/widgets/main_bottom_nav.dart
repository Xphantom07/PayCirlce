import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }

    if (index == 2) {
      Navigator.of(context).pushNamed(routeAddExpense);
      return;
    }

    final targetRoute = switch (index) {
      0 => routeDashboard,
      1 => routeJoinGroup,
      3 => routeTransactionHistory,
      4 => routeProfile,
      _ => routeDashboard,
    };

    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => _navigate(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_rounded),
          label: 'Groups',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline_rounded),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_rounded),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
