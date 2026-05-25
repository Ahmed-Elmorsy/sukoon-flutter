import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';

class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});

  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await ApiService.getRefundRequests(AuthSession.instance.token);
      if (res['status'] == 200 && mounted) {
        final data = res['body']['data'] as List<dynamic>? ?? [];
        setState(() {
          _requests = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(int id) async {
    final res =
        await ApiService.approveRefund(AuthSession.instance.token, id);
    if (!mounted) return;
    if (res['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Refund approved'),
            backgroundColor: Color(0xFF2E7D32)),
      );
      _load();
    } else {
      final msg = res['body']['error'] ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject(int id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Refund'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason for rejection...'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim().isEmpty
                      ? 'Refund rejected by admin.'
                      : controller.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null) return;
    final res = await ApiService.rejectRefund(
        AuthSession.instance.token, id, reason);
    if (!mounted) return;
    if (res['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Refund rejected'), backgroundColor: Colors.orange),
      );
      _load();
    }
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
          label: const Text('Back',
              style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16)),
        ),
        leadingWidth: 100,
        title: const Text('Refund Requests',
            style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.money_off, size: 60, color: AppTheme.lightGrey),
                      SizedBox(height: 16),
                      Text('No refund requests',
                          style: TextStyle(
                              color: AppTheme.textGrey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, i) => _buildCard(_requests[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> req) {
    final id = req['id'] as int? ?? 0;
    final status = req['status']?.toString() ?? 'pending';
    final reason = req['reason']?.toString() ?? '';
    final createdAt = req['created_at']?.toString().substring(0, 10) ?? '';
    final isPending = status == 'pending';

    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = AppTheme.bubbleGreen.withValues(alpha: 0.5);
        fg = const Color(0xFF2E7D32);
        label = 'Approved';
        break;
      case 'rejected':
        bg = Colors.red.withValues(alpha: 0.1);
        fg = Colors.red;
        label = 'Rejected';
        break;
      default:
        bg = AppTheme.inputBackground;
        fg = AppTheme.textGrey;
        label = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.money_off, color: AppTheme.primaryBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Refund #$id',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textDark)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Reason: $reason',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textGrey, height: 1.3)),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Submitted: $createdAt',
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.lightGrey)),
          ],
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approve(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
