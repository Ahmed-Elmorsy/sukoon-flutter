import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/localization.dart';
import 'payment_success_screen.dart';

class CardPaymentScreen extends StatefulWidget {
  final int orderId;
  final double amount;
  final Map<String, dynamic> breakdown;

  const CardPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.breakdown,
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  
  bool _processing = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _processing = true);
    
    // Simulate payment gateway delay (e.g., Paymob request)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _processing = false);
    
    // Navigate to payment success screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          orderId: widget.orderId,
          amount: widget.amount,
          methodName: S.isAr ? 'بطاقة ائتمان' : 'Credit Card',
        ),
      ),
      (route) => route.isFirst, // Keeps the dashboard or root screen beneath it
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
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryBlue, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'الدفع بالبطاقة' : 'Card Payment',
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _processing
              ? _buildProcessingLayout()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Styled credit card preview
                        _buildCreditCardPreview(),
                        const SizedBox(height: 32),
                        
                        // Card Number Field
                        _buildFieldLabel(S.text('card_number')),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _numberCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '•••• •••• •••• ••••',
                            prefixIcon: const Icon(Icons.credit_card_rounded, color: AppTheme.grey),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                            _CardNumberFormatter(),
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return isAr ? 'الرجاء إدخال رقم البطاقة' : 'Please enter card number';
                            }
                            final clean = v.replaceAll(' ', '');
                            if (clean.length < 16) {
                              return isAr ? 'يجب أن يكون رقم البطاقة ١٦ رقماً' : 'Card number must be 16 digits';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        
                        // Card Holder Name Field
                        _buildFieldLabel(S.text('card_holder')),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _holderCtrl,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            hintText: isAr ? 'الاسم كما هو مكتوب على البطاقة' : 'e.g. John Doe',
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.grey),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return isAr ? 'الرجاء إدخال اسم صاحب البطاقة' : 'Please enter card holder name';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        
                        // Expiry & CVV Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(S.text('expiry_date_pay')),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _expiryCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'MM/YY',
                                      prefixIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.grey, size: 20),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                      _CardExpiryFormatter(),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return isAr ? 'مطلوب' : 'Required';
                                      }
                                      if (!v.contains('/')) return isAr ? 'تاريخ غير صالح' : 'Invalid date';
                                      final parts = v.split('/');
                                      if (parts.length != 2) return isAr ? 'غير صالح' : 'Invalid';
                                      final month = int.tryParse(parts[0]) ?? 0;
                                      if (month < 1 || month > 12) return isAr ? 'شهر غير صالح' : 'Invalid month';
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(S.text('cvv')),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _cvvCtrl,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      hintText: '•••',
                                      prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.grey),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return isAr ? 'مطلوب' : 'Required';
                                      }
                                      if (v.length < 3) return isAr ? 'غير صالح' : 'Invalid';
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Pay Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _pay,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32), // High-trust green
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.security_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  '${S.text('pay_now_btn')} EGP ${widget.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildCreditCardPreview() {
    final cleanNum = _numberCtrl.text.isEmpty ? '•••• •••• •••• ••••' : _numberCtrl.text;
    final cleanHolder = _holderCtrl.text.isEmpty ? 'CARD HOLDER' : _holderCtrl.text.toUpperCase();
    final cleanExpiry = _expiryCtrl.text.isEmpty ? 'MM/YY' : _expiryCtrl.text;
    
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A4E), Color(0xFF3366FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A4E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Skoon Pay',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                width: 45,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'VISA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            cleanNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.isAr ? 'صاحب البطاقة' : 'CARDHOLDER',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cleanHolder,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    S.isAr ? 'ينتهي في' : 'EXPIRES',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cleanExpiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingLayout() {
    final isAr = S.isAr;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isAr ? 'جاري معالجة الدفعة بأمان...' : 'Processing payment securely...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'يرجى عدم إغلاق التطبيق أو الرجوع' : 'Please do not close the app or navigate back',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
