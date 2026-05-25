import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';

class OwnerContractsScreen extends StatefulWidget {
  final bool isAdmin;
  const OwnerContractsScreen({super.key, this.isAdmin = false});

  @override
  State<OwnerContractsScreen> createState() => _OwnerContractsScreenState();
}

class _OwnerContractsScreenState extends State<OwnerContractsScreen> {
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
      final token = AuthSession.instance.token;
      final isAdmin = widget.isAdmin || AuthSession.instance.role == 'admin';
      final res = isAdmin
          ? await ApiService.getAdminContracts(token)
          : await ApiService.getOwnerContracts(token);
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

  Future<void> _acceptContract(int id) async {
    final res = await ApiService.acceptContract(AuthSession.instance.token, id);
    if (res['status'] == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract accepted'), backgroundColor: Colors.green),
        );
      }
      _loadContracts();
    } else {
      if (mounted) {
        final msg = res['body']?['error']?.toString() ?? 'Failed to accept contract';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _refuseContract(int id) async {
    final res = await ApiService.refuseContract(AuthSession.instance.token, id, 'Declined by owner');
    if (res['status'] == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract refused'), backgroundColor: Colors.orange),
        );
      }
      _loadContracts();
    } else {
      if (mounted) {
        final msg = res['body']?['error']?.toString() ?? 'Failed to refuse contract';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Contract Requests',
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
          Icon(Icons.description_outlined, size: 60, color: AppTheme.lightGrey),
          SizedBox(height: 16),
          Text('No contract requests yet', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
          SizedBox(height: 8),
          Text('When tenants submit contracts,\nthey will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final id = contract['id'] as int;
    final status = contract['status']?.toString() ?? 'pending';
    final apt = contract['apartment'] as Map<String, dynamic>?;
    final user = contract['user'] as Map<String, dynamic>?;
    final aptId = apt?['id']?.toString() ?? '?';
    final tenantEmail = user?['email']?.toString() ?? 'Unknown tenant';
    final createdAt = contract['created_at']?.toString().substring(0, 10) ?? '';
    final isPending = status == 'pending';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apartment #$aptId',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Text(tenantEmail,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Submitted: $createdAt',
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          ],
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptContract(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _refuseContract(id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Refuse'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
