import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../models/apartment.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import 'apply_for_rent_screen.dart';
import 'edit_apartment_screen.dart';

class ApartmentDetailScreen extends StatefulWidget {
  final Apartment apartment;
  final bool isOwnerView;
  final bool isJoined;

  const ApartmentDetailScreen({
    super.key,
    required this.apartment,
    this.isOwnerView = false,
    this.isJoined = false,
  });

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen> {
  late Apartment apartment;
  late bool isOwnerView;
  late bool isJoined;
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    apartment = widget.apartment;
    isOwnerView = widget.isOwnerView;
    isJoined = widget.isJoined;
  }

  Future<void> _refreshApartment() async {
    try {
      final res = await ApiService.getApartment(
          AuthSession.instance.token, int.parse(apartment.id));
      if (res['status'] == 200 && mounted) {
        setState(() {
          apartment = Apartment.fromJson(res['body'] as Map<String, dynamic>);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Column(
        children: [
          // Fixed header
          Container(
            height: 200,
            width: double.infinity,
            color: AppTheme.primaryBlue,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bubblePurple.withValues(alpha: 0.3),
                  ),
                  child: const Center(
                    child: Text('🏠', style: TextStyle(fontSize: 64)),
                  ),
                ),
                SafeArea(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, _dataChanged),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left,
                          color: AppTheme.textDark, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          apartment.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'EGP ${apartment.pricePerMonth.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const Text(
                            '/ month',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        apartment.address,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Property Details Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(
                            Icons.bed_outlined, '${apartment.rooms}', 'Rooms'),
                        _buildDivider(),
                        _buildDetailItem(Icons.people_outline,
                            '${apartment.freeSpots}/${apartment.capacity}', 'Free'),
                        _buildDivider(),
                        _buildDetailItem(Icons.square_foot,
                            apartment.areaSqm.toStringAsFixed(0), 'm²'),
                        _buildDivider(),
                        _buildDetailItem(Icons.category_outlined,
                            apartment.type[0].toUpperCase() + apartment.type.substring(1), 'Type'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Owner Info
                  const Text(
                    'Owner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                AppTheme.primaryBlue.withValues(alpha: 0.1),
                          ),
                          child: const Center(
                            child:
                                Text('👤', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                apartment.ownerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Property Owner',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isJoined)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.chat_outlined,
                                color: Colors.white, size: 20),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    apartment.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textGrey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Amenities
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: apartment.amenities
                        .map((a) => _buildAmenityChip(a))
                        .toList(),
                  ),
                  // Location Map
                  if (apartment.latitude != null &&
                      apartment.longitude != null) ...[  
                    const SizedBox(height: 24),
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 200,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                apartment.latitude!,
                                apartment.longitude!,
                              ),
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('apt'),
                                position: LatLng(
                                  apartment.latitude!,
                                  apartment.longitude!,
                                ),
                              ),
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppTheme.primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${apartment.latitude!.toStringAsFixed(4)}, '
                              '${apartment.longitude!.toStringAsFixed(4)}',
                              style: const TextStyle(
                                  fontSize: 14, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                  ],
                  // Joined section - extra details
                  if (isJoined) ...[
                    const SizedBox(height: 28),
                    _buildJoinedSection(),
                  ],
                  // Members section (owner/admin only)
                  if (isOwnerView) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _showMembersSheet(context),
                        icon: const Icon(Icons.people_outline, size: 20),
                        label: const Text(
                          'Manage Members',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Action Button
                  if (!isOwnerView && !isJoined)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ApplyForRentScreen(apartment: apartment),
                          ),
                        ),
                        child: const Text('Apply for Rent'),
                      ),
                    ),
                  if (isJoined)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Contact landlord action
                        },
                        icon: const Icon(Icons.chat_outlined, size: 20),
                        label: const Text('Contact Landlord'),
                      ),
                    ),
                  if (isOwnerView)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditApartmentScreen(apartment: apartment),
                            ),
                          );
                          if (updated == true && context.mounted) {
                            _dataChanged = true;
                            Navigator.pop(context, true);
                          }
                        },
                        child: const Text('Edit Apartment'),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.lightGrey,
    );
  }

  Widget _buildAmenityChip(String amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.selectedCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        amenity,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  void _showMembersSheet(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _MembersPage(apartmentId: int.parse(apartment.id)),
      ),
    );
    if (changed == true) {
      _dataChanged = true;
      _refreshApartment();
    }
  }


  Widget _buildJoinedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lease Details
        const Text(
          'Lease Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildLeaseRow('Start Date', 'March 15, 2026'),
              const Divider(height: 20),
              _buildLeaseRow('End Date', 'March 15, 2027'),
              const Divider(height: 20),
              _buildLeaseRow('Monthly Rent',
                  'EGP ${apartment.pricePerMonth.toStringAsFixed(0)}'),
              const Divider(height: 20),
              _buildLeaseRow('Payment Due', '1st of each month'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Payment Info
        const Text(
          'Payment Info',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bubbleGreen.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Text('✅', style: TextStyle(fontSize: 22)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rent Paid — March 2026',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Next payment due: April 1, 2026',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // House Rules
        const Text(
          'Community Rules',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleItem(text: 'No smoking inside the apartment'),
              SizedBox(height: 8),
              _RuleItem(text: 'Quiet hours: 10 PM - 7 AM'),
              SizedBox(height: 8),
              _RuleItem(text: 'Pets allowed with prior approval'),
              SizedBox(height: 8),
              _RuleItem(text: 'Report maintenance issues promptly'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaseRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textGrey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String text;

  const _RuleItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MembersPage extends StatefulWidget {
  final int apartmentId;
  const _MembersPage({required this.apartmentId});

  @override
  State<_MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<_MembersPage> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _changed = false;
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.getApartmentMembers(
          AuthSession.instance.token, widget.apartmentId);
      if (res['status'] == 200 && mounted) {
        setState(() {
          _members = (res['body']['data'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    final res = await ApiService.addApartmentMember(
        AuthSession.instance.token, widget.apartmentId, email);
    if (mounted) {
      if (res['status'] == 200) {
        _emailCtrl.clear();
        _changed = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added'), backgroundColor: Colors.green),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['body']?['error']?.toString() ?? 'Failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _remove(int userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $name from this apartment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ApiService.removeApartmentMember(
        AuthSession.instance.token, widget.apartmentId, userId);
    if (mounted) {
      if (res['status'] == 200) {
        _changed = true;
        setState(() {
          _members.removeWhere((m) {
            final uid = (m['user_id'] is int) ? m['user_id'] as int : int.tryParse(m['user_id'].toString()) ?? -1;
            return uid == userId;
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['body']?['error']?.toString() ?? 'Failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _changed) {
          // Result is passed via Navigator
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Members / Tenants'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _changed),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add by email',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  width: 70,
                  child: ElevatedButton(
                    onPressed: _add,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _members.isEmpty
                      ? const Center(child: Text('No members yet'))
                      : ListView.builder(
                          itemCount: _members.length,
                          itemBuilder: (ctx, i) {
                            final m = _members[i];
                            final name = m['name']?.toString() ?? 'Unknown';
                            final email = m['email']?.toString() ?? '';
                            final status = m['membership_status']?.toString() ?? 'pending';
                            final gender = m['gender']?.toString() ?? '';
                            final userId = (m['user_id'] is int) ? m['user_id'] as int : int.tryParse(m['user_id'].toString()) ?? 0;

                            Color statusColor;
                            String statusLabel;
                            switch (status) {
                              case 'accepted':
                                statusColor = const Color(0xFF2E7D32);
                                statusLabel = 'Accepted';
                                break;
                              case 'paid':
                                statusColor = AppTheme.primaryBlue;
                                statusLabel = 'Paid';
                                break;
                              default:
                                statusColor = Colors.orange;
                                statusLabel = 'Pending';
                            }

                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                child: Text(gender == 'male' ? '♂' : '♀', style: const TextStyle(fontSize: 16)),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: email.isNotEmpty ? Text(email, style: const TextStyle(fontSize: 12)) : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _remove(userId, name),
                                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                                  ),
                                ],
                              ),
                            );
                          },
                          ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}


