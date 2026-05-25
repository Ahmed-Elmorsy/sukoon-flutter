import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../widgets/decorative_background.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;

  // Identity Docs
  List<dynamic> _users = [];
  String _identityFilter = 'pending'; // 'pending', 'approved', 'rejected'

  // Apartments
  List<dynamic> _apartments = [];
  String _apartmentFilter = 'pending'; // 'pending', 'verified', 'refused'

  // Contracts
  List<dynamic> _contracts = [];
  String _contractFilter = 'pending'; // 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTab(_tabController.index);
      }
    });
    _loadTab(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTab(int index) async {
    setState(() => _loading = true);
    final token = AuthSession.instance.token;
    try {
      if (index == 0) {
        final res = await ApiService.getUsers(token);
        if (res['status'] == 200) {
          final raw = res['body'];
          final list = (raw is List ? raw : (raw['data'] ?? raw['users'] ?? [])) as List<dynamic>;
          setState(() {
            _users = list;
          });
        }
      } else if (index == 1) {
        final res = await ApiService.getApartments(token);
        if (res['status'] == 200) {
          final list = res['body'] as List<dynamic>? ?? [];
          setState(() {
            _apartments = list;
          });
        }
      } else if (index == 2) {
        final res = await ApiService.getAdminContracts(token);
        if (res['status'] == 200) {
          final raw = res['body'];
          final list = (raw is List ? raw : (raw['data'] ?? raw['contracts'] ?? [])) as List<dynamic>;
          setState(() {
            _contracts = list;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document link')),
        );
      }
    }
  }

  // ── ID Verification Actions ──────────────────────────────────────────────────
  Future<void> _approveId(int docId) async {
    setState(() => _loading = true);
    final res = await ApiService.verifyIdentityDocument(AuthSession.instance.token, docId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['status'] == 200 || res['status'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identity Document Approved Successfully'), backgroundColor: Color(0xFF2E7D32)),
      );
      _loadTab(0);
    } else {
      final msg = res['body']['message'] ?? 'Failed to approve';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectId(int docId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Identity Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter reason for rejection...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _loading = true);
    final res = await ApiService.rejectIdentityDocument(AuthSession.instance.token, docId, reason);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['status'] == 200 || res['status'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identity Document Rejected'), backgroundColor: Colors.orange),
      );
      _loadTab(0);
    } else {
      final msg = res['body']['message'] ?? 'Failed to reject';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
      );
    }
  }

  // ── Apartment Moderation Actions ─────────────────────────────────────────────
  Future<void> _showApartmentDetails(Map<String, dynamic> apt) async {
    final id = int.tryParse(apt['id'].toString()) ?? 0;
    setState(() => _loading = true);
    final res = await ApiService.getApartmentModerationDetails(AuthSession.instance.token, id);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['status'] == 200) {
      final details = res['body']['data'] ?? res['body'];
      _showModerationSheet(apt, details);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch moderation details'), backgroundColor: Colors.red),
      );
    }
  }

  void _showModerationSheet(Map<String, dynamic> apt, Map<String, dynamic> details) {
    final doc = details['apartment_document'] as Map<String, dynamic>?;
    final owner = details['owner'] as Map<String, dynamic>? ?? apt['owner'] as Map<String, dynamic>?;
    final docId = doc != null ? int.tryParse(doc['id'].toString()) : null;
    final docUrl = doc?['file_url'] ?? doc?['path'];
    final docStatus = doc?['status']?.toString() ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                apt['title']?.toString() ?? 'Apartment Moderation',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                apt['location']?.toString() ?? 'Location details not set',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
              ),
              const Divider(height: 24),
              if (owner != null) ...[
                const Text('Owner Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(height: 6),
                Text('Name: ${owner['name'] ?? "${owner['profile']?['first_name'] ?? ''} ${owner['profile']?['last_name'] ?? ''}"}'),
                Text('Email: ${owner['email'] ?? ''}'),
                const Divider(height: 24),
              ],
              const Text('Ownership Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              if (doc != null) ...[
                Row(
                  children: [
                    const Icon(Icons.file_present_rounded, color: AppTheme.primaryBlue, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${doc['type']?.toString().toUpperCase() ?? 'DOCUMENT'}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Status: ${docStatus.toUpperCase()}', style: TextStyle(color: _getStatusColor(docStatus))),
                        ],
                      ),
                    ),
                    if (docUrl != null)
                      IconButton(
                        icon: const Icon(Icons.open_in_new, color: AppTheme.primaryBlue),
                        onPressed: () => _launchURL(docUrl.toString()),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (docStatus == 'pending' && docId != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            _verifyAptDoc(docId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Verify Document'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            _rejectAptDoc(docId);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Reject Document'),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                const Text('No ownership documents uploaded yet.', style: TextStyle(color: AppTheme.textGrey)),
              ],
              const Divider(height: 24),
              const Text('Listing Status Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _verifyListing(int.parse(apt['id'].toString()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve Listing'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _refuseListing(int.parse(apt['id'].toString()));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Refuse Listing'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyAptDoc(int docId) async {
    setState(() => _loading = true);
    final res = await ApiService.verifyApartmentDocument(AuthSession.instance.token, docId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['status'] == 200 || res['status'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apartment Document Verified'), backgroundColor: Color(0xFF2E7D32)),
      );
      _loadTab(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['body']['message']?.toString() ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectAptDoc(int docId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Apartment Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter reason for rejection...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _loading = true);
    final res = await ApiService.rejectApartmentDocument(AuthSession.instance.token, docId, reason);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['status'] == 200 || res['status'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apartment Document Rejected'), backgroundColor: Colors.orange),
      );
      _loadTab(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['body']['message']?.toString() ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyListing(int aptId) async {
    setState(() => _loading = true);
    final res = await ApiService.verifyApartment(AuthSession.instance.token, aptId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['status'] == 200 || res['status'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing Approved Successfully'), backgroundColor: Color(0xFF2E7D32)),
      );
      _loadTab(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['body']['message']?.toString() ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _refuseListing(int aptId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Refuse Listing'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter reason for refusal...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Refuse'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _loading = true);
    final res = await ApiService.refuseApartment(AuthSession.instance.token, aptId, reason: reason);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['status'] == 200 || res['status'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing Refused'), backgroundColor: Colors.orange),
      );
      _loadTab(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['body']['message']?.toString() ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Tenant Contract Actions ──────────────────────────────────────────────────
  Future<void> _approveContract(int contractId) async {
    setState(() => _loading = true);
    final res = await ApiService.verifyTenantContract(AuthSession.instance.token, contractId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['status'] == 200 || res['status'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lease Contract Approved Successfully'), backgroundColor: Color(0xFF2E7D32)),
      );
      _loadTab(2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['body']['message']?.toString() ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectContract(int contractId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Lease Contract'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter reason for rejection...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _loading = true);
    final res = await ApiService.rejectTenantContract(AuthSession.instance.token, contractId, reason);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['status'] == 200 || res['status'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lease Contract Rejected'), backgroundColor: Colors.orange),
      );
      _loadTab(2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['body']['message']?.toString() ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return const Color(0xFF2E7D32);
      case 'rejected':
      case 'refused':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  // ── Build UI Methods ─────────────────────────────────────────────────────────
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
          label: const Text('Back', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16)),
        ),
        leadingWidth: 100,
        title: const Text(
          'Verification Hub',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
            onPressed: () => _loadTab(_tabController.index),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textGrey,
          indicatorColor: AppTheme.primaryBlue,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.badge_outlined), text: 'Identity Docs'),
            Tab(icon: Icon(Icons.home_work_outlined), text: 'Apartments'),
            Tab(icon: Icon(Icons.description_outlined), text: 'Contracts'),
          ],
        ),
      ),
      body: DecorativeBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildIdentityTab(),
                  _buildApartmentTab(),
                  _buildContractTab(),
                ],
              ),
      ),
    );
  }

  // ── Identity Tab ─────────────────────────────────────────────────────────────
  Widget _buildIdentityTab() {
    final filteredUsers = _users.where((u) {
      final doc = u['identity_document'] as Map<String, dynamic>?;
      if (_identityFilter == 'pending') {
        return doc != null && doc['status'] == 'pending';
      } else if (_identityFilter == 'approved') {
        return doc != null && (doc['status'] == 'approved' || doc['is_verified'] == true);
      } else {
        return doc != null && doc['status'] == 'rejected';
      }
    }).toList();

    return Column(
      children: [
        _buildFilterSelector(
          currentValue: _identityFilter,
          options: const {'pending': 'Pending', 'approved': 'Approved', 'rejected': 'Rejected'},
          onChanged: (val) => setState(() => _identityFilter = val),
        ),
        Expanded(
          child: filteredUsers.isEmpty
              ? _buildEmptyState(Icons.badge, 'No Identity Documents in this status')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (ctx, i) => _buildIdentityCard(filteredUsers[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildIdentityCard(Map<String, dynamic> user) {
    final doc = user['identity_document'] as Map<String, dynamic>;
    final docId = int.tryParse(doc['id'].toString()) ?? 0;
    final fileUrl = doc['file_url'] ?? doc['path'];
    final name = '${user['profile']?['first_name'] ?? user['name'] ?? ''} ${user['profile']?['last_name'] ?? ''}'.trim();
    final typeLabel = doc['type']?.toString().toUpperCase() ?? 'DOCUMENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('👤', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 15)),
                    Text(user['email']?.toString() ?? '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text('Doc Type: $typeLabel', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Doc Number: ${doc['document_number'] ?? 'N/A'}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          if (doc['rejection_reason'] != null && doc['rejection_reason'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Rejection Reason: ${doc['rejection_reason']}', style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (fileUrl != null) ...[
                OutlinedButton.icon(
                  onPressed: () => _launchURL(fileUrl.toString()),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (doc['status'] == 'pending') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveId(docId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectId(docId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Apartment Tab ────────────────────────────────────────────────────────────
  Widget _buildApartmentTab() {
    final filteredApts = _apartments.where((a) {
      final status = a['status']?.toString() ?? 'pending';
      if (_apartmentFilter == 'pending') {
        return status == 'pending';
      } else if (_apartmentFilter == 'verified') {
        return status == 'available' || status == 'open' || status == 'verified';
      } else {
        return status == 'refused' || status == 'closed';
      }
    }).toList();

    return Column(
      children: [
        _buildFilterSelector(
          currentValue: _apartmentFilter,
          options: const {'pending': 'Pending Review', 'verified': 'Verified / Open', 'refused': 'Refused / Closed'},
          onChanged: (val) => setState(() => _apartmentFilter = val),
        ),
        Expanded(
          child: filteredApts.isEmpty
              ? _buildEmptyState(Icons.home, 'No Apartments in this status')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredApts.length,
                  itemBuilder: (ctx, i) => _buildApartmentCard(filteredApts[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildApartmentCard(Map<String, dynamic> apt) {
    final title = apt['title'] ?? 'Apartment #${apt['id']}';
    final location = apt['location'] ?? 'No Address';
    final price = double.tryParse(apt['price']?.toString() ?? '0') ?? 0;
    final status = apt['status']?.toString() ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.bubblePurple.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('🏠', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(location, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('EGP ${price.toStringAsFixed(0)}/mo',
                        style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getStatusColor(status)),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Review Details & Docs', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ElevatedButton(
                onPressed: () => _showApartmentDetails(apt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Row(
                  children: [
                    Text('Manage', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Contract Tab ─────────────────────────────────────────────────────────────
  Widget _buildContractTab() {
    final filteredContracts = _contracts.where((c) {
      final status = c['status']?.toString() ?? 'pending';
      if (_contractFilter == 'pending') {
        return status == 'pending';
      } else if (_contractFilter == 'approved') {
        return status == 'approved' || status == 'verified';
      } else {
        return status == 'rejected';
      }
    }).toList();

    return Column(
      children: [
        _buildFilterSelector(
          currentValue: _contractFilter,
          options: const {'pending': 'Pending Approval', 'approved': 'Approved', 'rejected': 'Rejected'},
          onChanged: (val) => setState(() => _contractFilter = val),
        ),
        Expanded(
          child: filteredContracts.isEmpty
              ? _buildEmptyState(Icons.description, 'No Lease Contracts in this status')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredContracts.length,
                  itemBuilder: (ctx, i) => _buildContractCard(filteredContracts[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildContractCard(Map<String, dynamic> c) {
    final contractId = int.tryParse(c['id'].toString()) ?? 0;
    final fileUrl = c['file_url'] ?? c['path'] ?? c['document_url'];
    final status = c['status']?.toString() ?? 'pending';
    final tenant = c['renter'] ?? c['user'] ?? {};
    final tenantName = '${tenant['profile']?['first_name'] ?? tenant['name'] ?? 'Tenant'} ${tenant['profile']?['last_name'] ?? ''}'.trim();
    final aptTitle = c['apartment']?['title'] ?? 'Apartment #${c['apartment_id'] ?? ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: AppTheme.primaryBlue, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Lease Contract #$contractId',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getStatusColor(status)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Apartment: $aptTitle', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Tenant: $tenantName', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          if (c['rejection_reason'] != null && c['rejection_reason'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Rejection Reason: ${c['rejection_reason']}', style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (fileUrl != null) ...[
                OutlinedButton.icon(
                  onPressed: () => _launchURL(fileUrl.toString()),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View Contract'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (status == 'pending') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveContract(contractId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectContract(contractId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────────
  Widget _buildFilterSelector({
    required String currentValue,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.entries.map((e) {
          final isSelected = currentValue == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textGrey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppTheme.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: AppTheme.textGrey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
