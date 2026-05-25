import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/apartment.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import 'publish_apartment_screen.dart';
import 'apartment_detail_screen.dart';

class MyApartmentsScreen extends StatefulWidget {
  const MyApartmentsScreen({super.key});

  @override
  State<MyApartmentsScreen> createState() => _MyApartmentsScreenState();
}

class _MyApartmentsScreenState extends State<MyApartmentsScreen> {
  late Future<List<Apartment>> _apartmentsFuture;

  @override
  void initState() {
    super.initState();
    _apartmentsFuture = _loadApartments();
  }

  Future<List<Apartment>> _loadApartments() async {
    try {
      final res = await ApiService.getApartments(AuthSession.instance.token);
      if (res['status'] == 200) {
        final list = res['body'] as List<dynamic>;
        final apts = list
            .map((j) => Apartment.fromJson(j as Map<String, dynamic>))
            .toList();
        apts.sort((a, b) => a.title.compareTo(b.title));
        return apts;
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: AppTheme.primaryBlue),
          label: const Text(
            'Back',
            style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
          ),
        ),
        leadingWidth: 100,
        title: const Text(
          'My Apartments',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => setState(() => _apartmentsFuture = _loadApartments()),
            icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue, size: 24),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PublishApartmentScreen()),
            ),
            icon: const Icon(Icons.add_circle_outline,
                color: AppTheme.primaryBlue, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Apartment>>(
        future: _apartmentsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final apartments = snap.data ?? [];
          if (apartments.isEmpty) return _buildEmptyState(context);
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: apartments.length,
            itemBuilder: (context, index) =>
                _buildApartmentCard(context, apartments[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏠', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            'No Apartments Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by publishing your first apartment',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PublishApartmentScreen()),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Publish Apartment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApartmentCard(BuildContext context, Apartment apt) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ApartmentDetailScreen(
              apartment: apt,
              isOwnerView: true,
            ),
          ),
        );
        if (changed == true) {
          setState(() => _apartmentsFuture = _loadApartments());
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bubblePurple.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Text('🏠', style: TextStyle(fontSize: 48)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          apt.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status badge with free spots
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: apt.isFull
                              ? Colors.red.withValues(alpha: 0.15)
                              : AppTheme.bubbleGreen.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          apt.isFull
                              ? 'Full'
                              : '${apt.freeSpots}/${apt.capacity} Free',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: apt.isFull
                                ? Colors.red
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        apt.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Details row
                  Row(
                    children: [
                      _buildDetailChip(
                          Icons.bed_outlined, '${apt.rooms} Rooms'),
                      const SizedBox(width: 12),
                      _buildDetailChip(
                          Icons.bathtub_outlined, '${apt.bathrooms} Bath'),
                      const SizedBox(width: 12),
                      _buildDetailChip(Icons.square_foot,
                          '${apt.areaSqm.toStringAsFixed(0)} m²'),
                      const Spacer(),
                      Text(
                        'EGP ${apt.pricePerMonth.toStringAsFixed(0)}/mo',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.textGrey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
      ],
    );
  }
}

