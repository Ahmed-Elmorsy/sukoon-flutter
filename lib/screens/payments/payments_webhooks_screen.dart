import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../services/localization.dart';

class PaymentsWebhooksScreen extends StatefulWidget {
  const PaymentsWebhooksScreen({super.key});

  @override
  State<PaymentsWebhooksScreen> createState() => _PaymentsWebhooksScreenState();
}

class _PaymentsWebhooksScreenState extends State<PaymentsWebhooksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hmacCtrl = TextEditingController(text: 'SIGNATURE_HERE');
  final _txnIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '60.00');
  final _orderIdCtrl = TextEditingController(text: '987654321');
  
  bool _isSuccess = true;
  bool _sending = false;
  bool _loadingOrders = true;
  List<Map<String, dynamic>> _orders = [];
  
  // To show the response details
  int? _responseStatus;
  String? _responseBody;

  @override
  void initState() {
    super.initState();
    _generateRandomTxnId();
    _loadOrders();
  }

  @override
  void dispose() {
    _hmacCtrl.dispose();
    _txnIdCtrl.dispose();
    _amountCtrl.dispose();
    _orderIdCtrl.dispose();
    super.dispose();
  }

  void _generateRandomTxnId() {
    final random = Random();
    final id = 10000000 + random.nextInt(90000000); // 8-digit random transaction ID
    setState(() {
      _txnIdCtrl.text = id.toString();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final res = await ApiService.getPaymentOrders(AuthSession.instance.token);
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

  // Helper to generate the current JSON payload based on inputs
  Map<String, dynamic> _buildPayload() {
    final double amt = double.tryParse(_amountCtrl.text) ?? 0.0;
    final int amountCents = (amt * 100).round();
    final int txnId = int.tryParse(_txnIdCtrl.text) ?? 12345678;
    final int orderId = int.tryParse(_orderIdCtrl.text) ?? 987654321;

    return {
      'obj': {
        'id': txnId,
        'success': _isSuccess,
        'amount_cents': amountCents,
        'order': {
          'id': orderId,
        },
        'currency': 'EGP',
      }
    };
  }

  Future<void> _sendWebhook() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _sending = true;
      _responseStatus = null;
      _responseBody = null;
    });

    final payload = _buildPayload();
    final hmac = _hmacCtrl.text.trim();

    try {
      final res = await ApiService.triggerPaymobWebhook(
        hmac: hmac,
        payload: payload,
      );

      if (mounted) {
        setState(() {
          _responseStatus = res['status'];
          _responseBody = const JsonEncoder.withIndent('  ').convert(res['body']);
          _sending = false;
        });

        if (res['status'] >= 200 && res['status'] < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Webhook callback triggered successfully!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          _loadOrders(); // Refresh order status list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: Server returned status ${res['status']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _responseStatus = 0;
          _responseBody = e.toString();
          _sending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error triggering webhook: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectOrder(Map<String, dynamic> order) {
    final id = order['id'] as int? ?? 0;
    final amountCents = order['amount_cents'] as int? ?? 0;
    final amount = amountCents / 100;
    
    setState(() {
      _orderIdCtrl.text = id.toString();
      _amountCtrl.text = amount.toStringAsFixed(2);
      _isSuccess = true;
      _generateRandomTxnId();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pre-filled form with Order #$id'),
        duration: const Duration(seconds: 1),
      ),
    );
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
          title: const Text(
            'Payments & Webhooks Sim',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
              onPressed: () {
                _loadOrders();
                _generateRandomTxnId();
              },
            )
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final content = [
                // Webhook form card
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.webhook, color: AppTheme.primaryBlue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Webhook Configuration',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              
                              // HMAC Signature field
                              const Text('HMAC Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _hmacCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'HMAC signature token',
                                  prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Signature is required' : null,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Transaction ID (Paymob)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _txnIdCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: 'e.g. 12345678',
                                            prefixIcon: const Icon(Icons.payment, size: 20),
                                            suffixIcon: IconButton(
                                              icon: const Icon(Icons.cached, size: 18),
                                              onPressed: _generateRandomTxnId,
                                            ),
                                          ),
                                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Order ID (Internal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _orderIdCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: 'e.g. 987654321',
                                            prefixIcon: Icon(Icons.receipt_long, size: 20),
                                          ),
                                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Amount (EGP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _amountCtrl,
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            hintText: '0.00',
                                            prefixIcon: Icon(Icons.monetization_on_outlined, size: 20),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Required';
                                            if (double.tryParse(v) == null) return 'Invalid amount';
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Success status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Switch(
                                            value: _isSuccess,
                                            activeThumbColor: const Color(0xFF2E7D32),
                                            activeTrackColor: const Color(0xFF2E7D32).withValues(alpha: 0.5),
                                            onChanged: (val) => setState(() => _isSuccess = val),
                                          ),
                                          Text(
                                            _isSuccess ? 'Success' : 'Failed',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _isSuccess ? const Color(0xFF2E7D32) : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Send Webhook callback button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _sending ? null : _sendWebhook,
                                  icon: _sending 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                                  label: Text(
                                    _sending ? 'Sending...' : 'Trigger Webhook POST',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              
                              if (_responseStatus != null) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'API Response:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Status: ',
                                            style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13),
                                          ),
                                          Text(
                                            '$_responseStatus',
                                            style: TextStyle(
                                              color: _responseStatus == 200 || _responseStatus == 201 
                                                  ? Colors.greenAccent 
                                                  : Colors.redAccent,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(color: Colors.white12),
                                      const SizedBox(height: 4),
                                      Text(
                                        _responseBody ?? '{}',
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Active orders list (either side-by-side or bottom)
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            'Active Payment Orders',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: _loadingOrders
                              ? const Center(child: CircularProgressIndicator())
                              : _orders.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.cardBorder),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.payment, size: 40, color: AppTheme.grey),
                                            SizedBox(height: 10),
                                            Text(
                                              'No active payment orders found.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: AppTheme.textGrey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _orders.length,
                                      itemBuilder: (context, i) {
                                        final order = _orders[i];
                                        final id = order['id'] as int? ?? 0;
                                        final status = order['status']?.toString() ?? 'pending';
                                        final amountCents = order['amount_cents'] as int? ?? 0;
                                        final amount = amountCents / 100;
                                        final isPending = status == 'pending';
                                        
                                        return Card(
                                          color: Colors.white,
                                          margin: const EdgeInsets.only(bottom: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          elevation: 1,
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                            leading: CircleAvatar(
                                              backgroundColor: isPending 
                                                  ? Colors.orange.withValues(alpha: 0.1) 
                                                  : AppTheme.primaryBlue.withValues(alpha: 0.1),
                                              child: Icon(
                                                isPending ? Icons.pending_actions : Icons.check_circle_outline,
                                                color: isPending ? Colors.orange : AppTheme.primaryBlue,
                                              ),
                                            ),
                                            title: Text(
                                              'Order #$id',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                            ),
                                            subtitle: Text(
                                              'EGP ${amount.toStringAsFixed(2)}',
                                              style: const TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.w500),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildStatusBadge(status),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.grey),
                                              ],
                                            ),
                                            onTap: () => _selectOrder(order),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                );
              } else {
                return Column(
                  children: content,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'paid':
      case 'success':
        bg = AppTheme.bubbleGreen.withValues(alpha: 0.5);
        fg = const Color(0xFF2E7D32);
        break;
      case 'failed':
        bg = Colors.red.withValues(alpha: 0.1);
        fg = Colors.red;
        break;
      default:
        bg = AppTheme.inputBackground;
        fg = AppTheme.textGrey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
