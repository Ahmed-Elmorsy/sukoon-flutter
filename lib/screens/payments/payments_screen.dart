import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../services/localization.dart';
import 'payment_method_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _loadingOrders = true;
  bool _loadingTxns = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final res =
          await ApiService.getPaymentOrders(AuthSession.instance.token);
      if (res['status'] == 200 && mounted) {
        final data = res['body']['data'] as List<dynamic>? ?? [];
        setState(() {
          _orders = data.cast<Map<String, dynamic>>();
          _loadingOrders = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingOrders = false);
  }

  Future<void> _loadTransactions() async {
    setState(() => _loadingTxns = true);
    try {
      final res =
          await ApiService.getTransactions(AuthSession.instance.token);
      if (res['status'] == 200 && mounted) {
        final data = res['body']['data'] as List<dynamic>? ?? [];
        setState(() {
          _transactions = data.cast<Map<String, dynamic>>();
          _loadingTxns = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingTxns = false);
  }

  Future<void> _requestRefund(int orderId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Refund'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason for refund...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Submit')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final res = await ApiService.submitRefundRequest(
        AuthSession.instance.token, orderId, reason);
    if (!mounted) return;
    if (res['status'] == 201 || res['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Refund request submitted'),
            backgroundColor: Color(0xFF2E7D32)),
      );
      _loadOrders();
    } else {
      final msg = res['body']['error'] ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = S.isAr;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(isAr ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new, color: AppTheme.primaryBlue, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(S.text('payments'),
              style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
              onPressed: () {
                _loadOrders();
                _loadTransactions();
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textGrey,
            indicatorColor: AppTheme.primaryBlue,
            tabs: [
              Tab(text: S.text('orders')),
              Tab(text: S.text('transactions')),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersTab(),
            _buildTransactionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_loadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, size: 60, color: AppTheme.lightGrey),
            const SizedBox(height: 16),
            Text(S.text('no_orders'),
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, i) => _buildOrderCard(_orders[i]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = order['id'] as int? ?? 0;
    final status = order['status']?.toString() ?? 'pending';
    final amountCents = order['amount_cents'] as int? ?? 0;
    final amount = (amountCents / 100).toStringAsFixed(2);
    final createdAt = order['created_at']?.toString().substring(0, 10) ?? '';
    final expiresAt = order['expires_at']?.toString().substring(0, 16) ?? '';
    final breakdown = order['breakdown'] as Map<String, dynamic>? ?? {};
    final isPaid = status == 'paid';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withValues(alpha: 0.1)
                      : AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                    isPending ? Icons.payment : Icons.receipt_long,
                    color: isPending ? Colors.orange : AppTheme.primaryBlue,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${S.text('order_no')} #$id',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textDark)),
                    Text('EGP $amount',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue)),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          // Breakdown
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if ((breakdown['rent_cents'] as int? ?? 0) > 0)
                    _breakdownRow('Rent', (breakdown['rent_cents'] as int) / 100),
                  if ((breakdown['insurance_cents'] as int? ?? 0) > 0)
                    _breakdownRow('Insurance', (breakdown['insurance_cents'] as int) / 100),
                  if ((breakdown['platform_fee_cents'] as int? ?? 0) > 0)
                    _breakdownRow('Platform Fee', (breakdown['platform_fee_cents'] as int) / 100),
                ],
              ),
            ),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${S.text('created')}: $createdAt',
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          ],
          if (isPending && expiresAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${S.text('expires')}: ${expiresAt.replaceAll('T', ' ')}',
                style:
                    const TextStyle(fontSize: 12, color: Colors.orange)),
          ],
          // PAY NOW button for pending orders
          if (isPending) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final amountDouble = amountCents / 100;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentMethodScreen(
                        orderId: id,
                        amount: amountDouble,
                        breakdown: breakdown,
                      ),
                    ),
                  ).then((_) {
                    _loadOrders();
                    _loadTransactions();
                  });
                },
                icon: const Icon(Icons.payment, size: 20),
                label: Text(S.text('pay_now'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (isPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _requestRefund(id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(S.text('request_refund')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, double amount) {
    final isAr = S.isAr;
    String localizedLabel = label;
    if (label == 'Rent') localizedLabel = isAr ? 'قيمة الإيجار' : 'Rent';
    if (label == 'Insurance') localizedLabel = isAr ? 'مبلغ التأمين' : 'Insurance';
    if (label == 'Platform Fee') localizedLabel = isAr ? 'رسوم المنصة' : 'Platform Fee';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(localizedLabel,
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          Text('EGP ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_loadingTxns) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz, size: 60, color: AppTheme.lightGrey),
            const SizedBox(height: 16),
            Text(S.text('no_transactions'),
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, i) => _buildTransactionCard(_transactions[i]),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> txn) {
    final type = txn['type']?.toString() ?? 'charge';
    final status = txn['status']?.toString() ?? 'pending';
    final amountCents = txn['amount_cents'] as int? ?? 0;
    final amount = (amountCents / 100).toStringAsFixed(2);
    final createdAt = txn['created_at']?.toString().substring(0, 10) ?? '';
    final isRefund = type == 'refund';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            isRefund ? Icons.arrow_back : Icons.arrow_forward,
            color: isRefund ? Colors.orange : const Color(0xFF2E7D32),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isRefund ? S.text('refund') : S.text('payment'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textDark)),
                if (createdAt.isNotEmpty)
                  Text(createdAt,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textGrey)),
              ],
            ),
          ),
          Text('${isRefund ? '-' : '+'} EGP $amount',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isRefund ? Colors.orange : const Color(0xFF2E7D32))),
          const SizedBox(width: 8),
          _buildStatusBadge(status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'paid':
      case 'success':
        bg = AppTheme.bubbleGreen.withValues(alpha: 0.5);
        fg = const Color(0xFF2E7D32);
        label = status == 'paid' ? S.text('paid') : S.text('success');
        break;
      case 'refunded':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange;
        label = S.text('refunded');
        break;
      case 'failed':
        bg = Colors.red.withValues(alpha: 0.1);
        fg = Colors.red;
        label = S.text('failed');
        break;
      default:
        bg = AppTheme.inputBackground;
        fg = AppTheme.textGrey;
        label = S.text('pending');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
