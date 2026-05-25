import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/localization.dart';
import 'card_payment_screen.dart';
import 'wallet_payment_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final int orderId;
  final double amount;
  final Map<String, dynamic> breakdown;

  const PaymentMethodScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.breakdown,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedMethod = 'card'; // 'card' or 'wallet'

  void _proceed() {
    if (_selectedMethod == 'card') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CardPaymentScreen(
            orderId: widget.orderId,
            amount: widget.amount,
            breakdown: widget.breakdown,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletPaymentScreen(
            orderId: widget.orderId,
            amount: widget.amount,
            breakdown: widget.breakdown,
          ),
        ),
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
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryBlue, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            S.text('payment_method'),
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  S.text('payment_method_desc'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Card payment option
                _buildMethodOption(
                  id: 'card',
                  title: S.text('credit_debit_card'),
                  subtitle: S.text('card_desc'),
                  icon: Icons.credit_card_rounded,
                  colors: [const Color(0xFF3366FF), const Color(0xFF5285FF)],
                ),
                const SizedBox(height: 16),
                
                // Wallet payment option
                _buildMethodOption(
                  id: 'wallet',
                  title: S.text('digital_wallet'),
                  subtitle: S.text('wallet_desc'),
                  icon: Icons.account_balance_wallet_rounded,
                  colors: [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
                ),
                
                const Spacer(),
                
                // Total Breakdown section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.text('total_breakdown'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if ((widget.breakdown['rent_cents'] as int? ?? 0) > 0)
                        _buildBreakdownRow(isAr ? 'قيمة الإيجار' : 'Rent', (widget.breakdown['rent_cents'] as int) / 100),
                      if ((widget.breakdown['insurance_cents'] as int? ?? 0) > 0)
                        _buildBreakdownRow(isAr ? 'مبلغ التأمين' : 'Insurance', (widget.breakdown['insurance_cents'] as int) / 100),
                      if ((widget.breakdown['platform_fee_cents'] as int? ?? 0) > 0)
                        _buildBreakdownRow(isAr ? 'رسوم المنصة' : 'Platform Fee', (widget.breakdown['platform_fee_cents'] as int) / 100),
                      const Divider(height: 24, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'المجموع الإجمالي' : 'Total Amount',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'EGP ${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _proceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      elevation: 2,
                    ),
                    child: Text(
                      S.text('continue'),
                      style: const TextStyle(
                        fontSize: 18,
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

  Widget _buildMethodOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.selectedCardBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textGrey),
          ),
          Text(
            'EGP ${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}
