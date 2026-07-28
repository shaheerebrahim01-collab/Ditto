import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../measurement_visits/measurement_requests_screen.dart';
import '../orders/tailor_orders_screen.dart';
import '../portfolio/portfolio_screen.dart';

// Bottom-nav shell shown once authenticated: Dashboard / Orders / Requests / Portfolio.
class TailorShell extends StatefulWidget {
  const TailorShell({super.key});

  @override
  State<TailorShell> createState() => _TailorShellState();
}

class _TailorShellState extends State<TailorShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TailorOrdersScreen(),
    MeasurementRequestsScreen(),
    PortfolioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_paste_search_outlined),
            selectedIcon: Icon(Icons.content_paste_search),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Portfolio',
          ),
        ],
      ),
    );
  }
}
