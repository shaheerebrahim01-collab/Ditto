import 'package:flutter/material.dart';

import 'bookings_screen.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';

// Bottom-nav shell shown to Role.RENTAL_SHOP accounts instead of
// TailorShell: Dashboard / Bookings / Inventory.
class RentalShopShell extends StatefulWidget {
  const RentalShopShell({super.key});

  @override
  State<RentalShopShell> createState() => _RentalShopShellState();
}

class _RentalShopShellState extends State<RentalShopShell> {
  int _index = 0;

  static const _screens = [
    RentalShopDashboardScreen(),
    RentalShopBookingsScreen(),
    RentalShopInventoryScreen(),
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
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Inventory',
          ),
        ],
      ),
    );
  }
}
