import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/decorative_background.dart';
import '../models/apartment.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../services/notification_poller.dart';
import 'my_apartments_screen.dart';
import 'search_filter_screen.dart';
import 'publish_apartment_screen.dart';
import 'apartment_detail_screen.dart';
import 'user_management_screen.dart';
import 'notifications_screen.dart';
import 'owner_contracts_screen.dart';
import 'payments/payments_screen.dart';
import 'admin_refunds_screen.dart';
import 'admin_verification_screen.dart';
import 'payments/payments_webhooks_screen.dart';


class DashboardScreen extends StatefulWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Apartment>> _apartmentsFuture;
  final _poller = NotificationPoller.instance;

  @override
  void initState() {
    super.initState();
    _apartmentsFuture = _loadApartments();
    _poller.addListener(_onNotifChange);
  }

  @override
  void dispose() {
    _poller.removeListener(_onNotifChange);
    super.dispose();
  }

  void _onNotifChange() {
    if (mounted) setState(() {});
  }

  Future<List<Apartment>> _loadApartments() async {
    try {
      final res = await ApiService.getApartments(AuthSession.instance.token);
      if (res['status'] == 200) {
        final list = res['body'] as List<dynamic>;
        final apts = list.map((j) => Apartment.fromJson(j as Map<String, dynamic>)).toList();
        apts.sort((a, b) => a.title.compareTo(b.title));
        return apts;
      }
    } catch (_) {}
    return [];
  }

  String get role => widget.role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _refresh,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: DecorativeBackground(
        showTopLeftBubble: true,
        showBottomRightBubble: false,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Greeting Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      ),
                      child: const Center(
                        child: Text('👤', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back! 👋',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AuthSession.instance.name.isEmpty
                                ? 'Welcome'
                                : AuthSession.instance.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                        _poller.refresh();
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                color: AppTheme.textDark, size: 22),
                          ),
                          if (_poller.unreadCount > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                child: Text(
                                  _poller.unreadCount > 9 ? '9+' : '${_poller.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Stats Cards (driven by real API data)
                FutureBuilder<List<Apartment>>(
                  future: _apartmentsFuture,
                  builder: (context, snap) {
                    final apts = snap.data ?? [];
                    if (role == 'owner') return _buildOwnerStats(apts);
                    if (role == 'admin') return _buildAdminStats(apts);
                    return _buildTenantStats(apts);
                  },
                ),
                const SizedBox(height: 24),
                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                if (role == 'owner') _buildOwnerActions(context),
                if (role == 'renter') _buildTenantActions(context),
                if (role == 'admin') _buildAdminActions(context),
                const SizedBox(height: 24),
                // Recent Listings
                const Text(
                  'Recent Listings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Apartment>>(
                  future: _apartmentsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final apts = snap.data ?? [];
                    if (apts.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.apartment_outlined, size: 48, color: AppTheme.lightGrey),
                              SizedBox(height: 12),
                              Text('No apartments yet', style: TextStyle(color: AppTheme.textGrey, fontSize: 15)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: apts
                          .take(3)
                          .map((apt) => _buildApartmentPreview(context, apt))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _apartmentsFuture = _loadApartments();
    });
    await _apartmentsFuture;
    _poller.refresh();
  }

  Widget _buildOwnerStats(List<Apartment> apts) {
    final total = apts.length.toString();
    final rented = apts.where((a) => a.status == 'rented').length.toString();
    final available = apts.where((a) => a.status == 'available' || a.status == 'open').length.toString();
    return Row(
      children: [
        Expanded(child: _buildStatCard('🏠', total, 'Total\nApartments')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('✅', rented, 'Currently\nRented')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('📋', available, 'Available\nNow')),
      ],
    );
  }

  Widget _buildTenantStats(List<Apartment> apts) {
    final listings = apts.where((a) => a.status == 'available' || a.status == 'open').length.toString();
    return Row(
      children: [
        Expanded(child: _buildStatCard('🔍', listings, 'Available\nListings')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('❤️', '0', 'Saved\nPlaces')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('📝', '0', 'Active\nApplications')),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                Icons.add_circle_outline,
                'Publish New',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PublishApartmentScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                Icons.apartment_outlined,
                'My Apartments',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyApartmentsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                Icons.payment,
                'Payments',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                Icons.notifications_outlined,
                'Notifications',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminStats(List<Apartment> apts) {
    final total     = apts.length.toString();
    final available = apts.where((a) => a.status == 'available' || a.status == 'open').length.toString();
    final rented    = apts.where((a) => a.status == 'rented').length.toString();
    return Row(
      children: [
        Expanded(child: _buildStatCard('🏠', total,     'Total\nListings')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('✅', available, 'Available\nNow')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('📋', rented,    'Currently\nRented')),
      ],
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                Icons.apartment_outlined,
                'All Listings',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyApartmentsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                Icons.description_outlined,
                'Contracts',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OwnerContractsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                Icons.people_outlined,
                'Manage Users',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UserManagementScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                Icons.add_circle_outline,
                'Add Listing',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PublishApartmentScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                Icons.money_off,
                'Refund Requests',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminRefundsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                Icons.notifications_outlined,
                'Notifications',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                Icons.verified_user_outlined,
                'Verification Hub',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                Icons.webhook,
                'Webhooks Sim',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentsWebhooksScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTenantActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                Icons.search,
                'Search Apartments',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                Icons.payment,
                'Payments',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                Icons.notifications_outlined,
                'Notifications',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApartmentPreview(BuildContext context, Apartment apt) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ApartmentDetailScreen(
              apartment: apt,
              isOwnerView: role == 'owner' || role == 'admin',
            ),
          ),
        );
        if (changed == true) _refresh();
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail placeholder
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.bubblePurple.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🏠', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apt.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        apt.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'EGP ${apt.pricePerMonth.toStringAsFixed(0)}/mo',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: apt.status == 'available'
                  ? AppTheme.bubbleGreen.withValues(alpha: 0.5)
                  : AppTheme.bubblePurple.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              apt.status == 'available' ? 'Available' : 'Rented',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: apt.status == 'available'
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF5C3D99),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

