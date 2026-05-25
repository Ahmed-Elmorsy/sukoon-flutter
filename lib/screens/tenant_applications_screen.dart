import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';

class TenantApplicationsScreen extends StatefulWidget {
  const TenantApplicationsScreen({super.key});

  @override
  State<TenantApplicationsScreen> createState() => _TenantApplicationsScreenState();
}

class _TenantApplicationsScreenState extends State<TenantApplicationsScreen> {
  List<Map<String, dynamic>> _contracts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getContracts(AuthSession.instance.token);
      if (res['status'] == 200 && mounted) {
        final list = res['body'] as List<dynamic>;
        setState(() {
          _contracts = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Applications',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
            onPressed: _loadContracts,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contracts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadContracts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _contracts.length,
                    itemBuilder: (context, i) => _buildContractCard(_contracts[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.file_copy_outlined, size: 60, color: AppTheme.lightGrey),
          SizedBox(height: 16),
          Text('No applications yet', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
          SizedBox(height: 8),
          Text('Your submitted contracts\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final status = contract['status']?.toString() ?? 'pending';
    final apt = contract['apartment'] as Map<String, dynamic>?;
    final aptId = apt?['id']?.toString() ?? '?';
    final createdAt = contract['created_at']?.toString().substring(0, 10) ?? '';

    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'accepted':
        bg = AppTheme.bubbleGreen.withValues(alpha: 0.5);
        fg = const Color(0xFF2E7D32);
        label = 'Accepted';
        break;
      case 'refused':
        bg = Colors.red.withValues(alpha: 0.1);
        fg = Colors.red;
        label = 'Refused';
        break;
      default:
        bg = AppTheme.inputBackground;
        fg = AppTheme.textGrey;
        label = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apartment #$aptId',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Submitted: $createdAt',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
  }
}
