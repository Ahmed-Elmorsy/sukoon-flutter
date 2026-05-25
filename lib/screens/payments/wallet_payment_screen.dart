import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/localization.dart';
import 'payment_success_screen.dart';

class WalletPaymentScreen extends StatefulWidget {
  final int orderId;
  final double amount;
  final Map<String, dynamic> breakdown;

  const WalletPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.breakdown,
  });

  @override
  State<WalletPaymentScreen> createState() => _WalletPaymentScreenState();
}

class _WalletPaymentScreenState extends State<WalletPaymentScreen> {
  Uint8List? _receiptBytes;
  bool _submitting = false;
  final String _walletAddress = '01001234567';
  final String _instapayAddress = 'skoon@instapay';

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (_) {}
    
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _receiptBytes = bytes;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.isAr ? 'تم نسخ $label' : 'Copied $label to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (_receiptBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.isAr ? 'الرجاء رفع إيصال التحويل أولاً.' : 'Please upload transfer receipt first.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    
    // Simulate transaction submission delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _submitting = false);
    
    // Navigate to payment success screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          orderId: widget.orderId,
          amount: widget.amount,
          methodName: S.isAr ? 'المحفظة الرقمية' : 'Digital Wallet',
          isWalletPending: true,
        ),
      ),
      (route) => route.isFirst,
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
            isAr ? 'المحفظة الرقمية' : 'Digital Wallet',
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _submitting
              ? _buildSubmittingLayout()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        S.text('wallet_instructions'),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textGrey,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Wallet Address Details Card
                      _buildTransferDetailsCard(),
                      const SizedBox(height: 32),
                      
                      // Receipt Upload Area
                      _buildFieldLabel(S.text('upload_receipt')),
                      const SizedBox(height: 12),
                      _buildUploadArea(),
                      
                      const SizedBox(height: 40),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            elevation: 2,
                          ),
                          child: Text(
                            S.text('submit_payment'),
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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildTransferDetailsCard() {
    final isAr = S.isAr;
    return Container(
      width: double.infinity,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'المبلغ المطلوب تحويله' : 'Required Amount',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                ),
              ),
              Text(
                'EGP ${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const Divider(height: 32, thickness: 1),
          
          // Mobile Wallet Number Row
          _buildAddressRow(
            icon: Icons.phone_android_rounded,
            label: isAr ? 'رقم محفظة فودافون كاش' : 'Vodafone Cash Wallet',
            value: _walletAddress,
          ),
          const SizedBox(height: 16),
          
          // InstaPay Address Row
          _buildAddressRow(
            icon: Icons.account_balance_rounded,
            label: isAr ? 'عنوان إنستاباي' : 'InstaPay IPA Address',
            value: _instapayAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryBlue, size: 20),
          onPressed: () => _copyToClipboard(value, label),
          tooltip: 'Copy',
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickReceipt,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: _receiptBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      Image.memory(
                        _receiptBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 16),
                            onPressed: () {
                              setState(() {
                                _receiptBytes = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🧾', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 12),
                    Text(
                      S.text('upload_receipt'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        S.text('receipt_desc'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSubmittingLayout() {
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
            isAr ? 'جاري إرسال إيصال التحويل...' : 'Submitting transfer receipt...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'يرجى الانتظار لحين اكتمال الرفع والتحقق' : 'Please wait while uploading & submitting',
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

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0, metric.length);
        final extractPath = metric.extractPath(start, end.toDouble());
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
