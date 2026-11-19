
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      backgroundColor: Colors.white,

      // =========================================================
      // CURRENT SCREEN
      // =========================================================
      body: child,

      // =========================================================
      // CUSTOM BOTTOM NAVIGATION
      // =========================================================
      bottomNavigationBar: _buildBottomNavigation(
        context,
        selectedIndex,
      ),
    );
  }

  // =============================================================
  // BOTTOM NAVIGATION
  // =============================================================

  Widget _buildBottomNavigation(
    BuildContext context,
    int selectedIndex,
  ) {
    return Container(
      width: double.infinity,
      height: 81,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE1E6ED),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // =====================================================
          // HOME
          // =====================================================

          _buildBottomNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () {
              if (selectedIndex != 0) {
                context.go('/home');
              }
            },
          ),

          // =====================================================
          // RIDES
          // =====================================================

          _buildBottomNavItem(
            icon: Icons.directions_car_rounded,
            label: 'Rides',
            selected: selectedIndex == 1,
            onTap: () {
              if (selectedIndex != 1) {
                context.go('/events');
              }
            },
          ),

          // =====================================================
          // ACCOUNT
          // =====================================================

          _buildBottomNavItem(
            icon: Icons.person_rounded,
            label: 'Account',
            selected: selectedIndex == 2,
            onTap: () {
              if (selectedIndex != 2) {
                context.go('/profile');
              }
            },
          ),
        ],
      ),
    );
  }

  // =============================================================
  // NAVIGATION ITEM
  // =============================================================

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2685DD).withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF2685DD),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2685DD),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // DETERMINE SELECTED TAB
  // =============================================================

  int _getSelectedIndex(BuildContext context) {
    //final String location = GoRouterState.of(context).uri.toString();
    final String location = GoRouterState.of(context).location;

    if (location.startsWith('/home')) {
      return 0;
    }

    if (location.startsWith('/events')) {
      return 1;
    }

    if (location.startsWith('/profile')) {
      return 2;
    }

    // Default to Home
    return 0;
  }
}