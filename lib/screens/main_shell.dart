import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_poller.dart';
import 'dashboard_screen.dart';
import 'my_apartments_screen.dart';
import 'search_filter_screen.dart';
import 'tenant_profile_screen.dart';
import 'owner_profile_screen.dart';
import 'owner_contracts_screen.dart';
import 'tenant_applications_screen.dart';
import 'user_management_screen.dart';

class MainShell extends StatefulWidget {
  final String role;

  const MainShell({super.key, required this.role});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _ownerPages;
  late final List<Widget> _tenantPages;
  late final List<Widget> _adminPages;

  @override
  void initState() {
    super.initState();
    NotificationPoller.instance.start();
    _ownerPages = [
      DashboardScreen(role: widget.role),
      const MyApartmentsScreen(),
      const OwnerContractsScreen(),
      const OwnerProfileScreen(),
    ];
    _tenantPages = [
      DashboardScreen(role: widget.role),
      const SearchFilterScreen(),
      const TenantApplicationsScreen(),
      TenantProfileScreen(role: widget.role),
    ];
    _adminPages = [
      DashboardScreen(role: widget.role),
      const MyApartmentsScreen(),
      const UserManagementScreen(),
      const OwnerContractsScreen(),
      TenantProfileScreen(role: widget.role),
    ];
  }

  @override
  void dispose() {
    NotificationPoller.instance.stop();
    super.dispose();
  }

  List<Widget> get _pages {
    if (widget.role == 'owner') return _ownerPages;
    if (widget.role == 'admin') return _adminPages;
    return _tenantPages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE8ECF4), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widget.role == 'owner'
                  ? [
                      _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                      _buildNavItem(Icons.apartment_outlined, Icons.apartment, 'Apartments', 1),
                      _buildNavItem(Icons.description_outlined, Icons.description, 'Contracts', 2),
                      _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
                    ]
                  : widget.role == 'admin'
                  ? [
                      _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                      _buildNavItem(Icons.list_alt_outlined, Icons.list_alt, 'Listings', 1),
                      _buildNavItem(Icons.people_outline, Icons.people, 'Users', 2),
                      _buildNavItem(Icons.description_outlined, Icons.description, 'Contracts', 3),
                      _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 4),
                    ]
                  : [
                      _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                      _buildNavItem(Icons.search_outlined, Icons.search, 'Search', 1),
                      _buildNavItem(Icons.file_copy_outlined, Icons.file_copy, 'Applications', 2),
                      _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryBlue : AppTheme.grey,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppTheme.primaryBlue : AppTheme.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

