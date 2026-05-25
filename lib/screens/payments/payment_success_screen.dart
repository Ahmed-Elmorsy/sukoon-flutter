import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/localization.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final int orderId;
  final double amount;
  final String methodName;
  final bool isWalletPending;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.methodName,
    this.isWalletPending = false,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = S.isAr;
    final isWallet = widget.isWalletPending;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Animated green Success Badge
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isWallet 
                          ? Colors.orange.withValues(alpha: 0.1) 
                          : AppTheme.bubbleGreen.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isWallet ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                        color: isWallet ? Colors.orange : const Color(0xFF2E7D32),
                        size: 64,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Status Title
                Text(
                  isWallet 
                      ? (isAr ? 'قيد المراجعة' : 'Submission Received')
                      : S.text('payment_success'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status Description
                Text(
                  isWallet
                      ? (isAr 
                          ? 'لقد تم إرسال إيصال التحويل بنجاح. سنقوم بإبلاغك فور مراجعة المالك وتأكيد الدفعة.' 
                          : 'Your transfer receipt has been submitted. The owner has been notified to review and confirm the payment.')
                      : S.text('payment_success_desc'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textGrey,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                // Transaction Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        isAr ? 'رقم الطلب' : 'Order ID',
                        '#${widget.orderId}',
                      ),
                      const Divider(height: 24, thickness: 1),
                      _buildSummaryRow(
                        isAr ? 'المبلغ الإجمالي' : 'Total Amount',
                        'EGP ${widget.amount.toStringAsFixed(2)}',
                        valueColor: AppTheme.primaryBlue,
                        bold: true,
                      ),
                      const Divider(height: 24, thickness: 1),
                      _buildSummaryRow(
                        isAr ? 'طريقة الدفع' : 'Payment Method',
                        widget.methodName,
                      ),
                      const Divider(height: 24, thickness: 1),
                      _buildSummaryRow(
                        isAr ? 'الحالة' : 'Status',
                        isWallet 
                            ? (isAr ? 'قيد المراجعة' : 'Reviewing') 
                            : (isAr ? 'مكتملة' : 'Completed'),
                        valueColor: isWallet ? Colors.orange : const Color(0xFF2E7D32),
                        bold: true,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Go to Dashboard Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      elevation: 2,
                    ),
                    child: Text(
                      S.text('go_to_dashboard'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
