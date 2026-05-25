import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/decorative_background.dart';
import '../../services/id_verification_service.dart';
import '../../services/verification_session.dart';
import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../services/app_logger.dart';
import '../../services/localization.dart';
import '../main_shell.dart';

class DocumentVerificationScreen extends StatefulWidget {
  final String role;
  final Uint8List selfieBytes;

  const DocumentVerificationScreen({
    super.key,
    required this.role,
    required this.selfieBytes,
  });

  @override
  State<DocumentVerificationScreen> createState() =>
      _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState
    extends State<DocumentVerificationScreen> {
  String _selectedDocType = 'national_id';
  Uint8List? _frontBytes;
  Uint8List? _backBytes;
  bool _isSubmitting = false;

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      if (isFront) {
        _frontBytes = bytes;
      } else {
        _backBytes = bytes;
      }
    });
  }

  Future<void> _submitDocuments() async {
    final isAr = S.isAr;
    if (_frontBytes == null || _backBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'الرجاء رفع كلا وجهي الهوية أولاً.' : 'Please upload both sides of your ID first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final service = IdVerificationService();

    final requestId = await service.submitVerification(
      frontBytes: _frontBytes!,
      backBytes: _backBytes!,
      selfieBytes: widget.selfieBytes,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (requestId == null) {
      _showErrorDialog(
          isAr
              ? 'لم نتمكن من الاتصال بخادم التحقق. يرجى التحقق من اتصالك والمحاولة مرة أخرى.'
              : 'Could not reach the verification server. Please check your connection and try again.');
      return;
    }

    // Fire-and-forget: poll result & upload documents in background
    _backgroundVerify(service, requestId);

    // Navigate to main page immediately
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainShell(role: widget.role)),
      (route) => false,
    );
  }

  /// Runs in the background after the user has already navigated away.
  void _backgroundVerify(IdVerificationService service, String requestId) async {
    try {
      final result = await service.pollResult(requestId);
      if (result != null) {
        VerificationSession.result = result;
        // Auto-fill profile from OCR data
        if (result.ocrFront != null) {
          final ocr = result.ocrFront!;
          if (ocr.name.isNotEmpty) AuthSession.instance.name = ocr.name;
          if (ocr.address.isNotEmpty) AuthSession.instance.address = ocr.address;
          if (ocr.idNumber.isNotEmpty) AuthSession.instance.idNumber = ocr.idNumber;
          if (ocr.birthDateFormatted.isNotEmpty) {
            AuthSession.instance.dob = ocr.birthDateFormatted;
            AuthSession.instance.birthDate = ocr.birthDate;
          }
        }
        if (result.ocrBack != null) {
          final back = result.ocrBack!;
          if (back.profession.isNotEmpty) AuthSession.instance.profession = back.profession;
          if (back.gender.isNotEmpty) AuthSession.instance.gender = back.gender;
          if (back.religion.isNotEmpty) AuthSession.instance.religion = back.religion;
          if (back.maritalStatus.isNotEmpty) AuthSession.instance.maritalStatus = back.maritalStatus;
          if (back.expiryDate.isNotEmpty) AuthSession.instance.idExpiryDate = back.expiryDate;
          if (back.issueDate.isNotEmpty) AuthSession.instance.idIssueDate = back.issueDate;
        }
        if (result.success) AuthSession.instance.idVerified = true;
        AppLogger.instance.info('IDENTITY', 'Background verification completed: success=${result.success}');

        // Save OCR data to backend + trigger FCM notification
        if (AuthSession.instance.isLoggedIn) {
          try {
            final ocrPayload = <String, dynamic>{
              'id_verified': result.success,
            };
            if (result.ocrFront != null) {
              final f = result.ocrFront!;
              if (f.name.isNotEmpty) ocrPayload['name'] = f.name;
              if (f.address.isNotEmpty) ocrPayload['address'] = f.address;
              if (f.idNumber.isNotEmpty) ocrPayload['id_number'] = f.idNumber;
              if (f.birthDate.isNotEmpty) ocrPayload['birth_date'] = f.birthDate;
            }
            if (result.ocrBack != null) {
              final b = result.ocrBack!;
              if (b.profession.isNotEmpty) ocrPayload['profession'] = b.profession;
              if (b.gender.isNotEmpty) ocrPayload['gender'] = b.gender;
              if (b.religion.isNotEmpty) ocrPayload['religion'] = b.religion;
              if (b.maritalStatus.isNotEmpty) ocrPayload['marital_status'] = b.maritalStatus;
              if (b.expiryDate.isNotEmpty) ocrPayload['expiry_date'] = b.expiryDate;
              if (b.issueDate.isNotEmpty) ocrPayload['issue_date'] = b.issueDate;
            }
            final saveRes = await ApiService.saveOcrData(
                AuthSession.instance.token, ocrPayload);
            AppLogger.instance.info('IDENTITY', 'OCR data saved to backend: ${saveRes['status']}');
          } catch (e) {
            AppLogger.instance.info('IDENTITY', 'OCR data save failed: $e');
          }
        }
      } else {
        AppLogger.instance.info('IDENTITY', 'Background verification: no result (timed out or not found)');
      }
    } catch (e) {
      AppLogger.instance.info('IDENTITY', 'Background verification error: $e');
    }

    // Upload documents to backend (best-effort)
    if (AuthSession.instance.isLoggedIn) {
      try {
        final docs = [
          {'bytes': _frontBytes!, 'type': '${_selectedDocType}_front'},
          {'bytes': _backBytes!,  'type': '${_selectedDocType}_back'},
        ];
        final uploadRes = await ApiService.uploadIdentityDocuments(
          token: AuthSession.instance.token,
          documents: docs,
        );
        AppLogger.instance.info('IDENTITY', 'Document upload response: ${uploadRes['status']}');
      } catch (e) {
        AppLogger.instance.info('IDENTITY', 'Document upload skipped (backend not ready): $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    final isAr = S.isAr;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(isAr ? 'فشل التحقق' : 'Verification Failed',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAr ? 'حاول مجدداً' : 'Try Again'),
            ),
          ),
        ],
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
          leading: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryBlue),
            label: Text(
              isAr ? 'رجوع' : 'Back',
              style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
            ),
          ),
          leadingWidth: 100,
          title: Text(
            S.text('doc_verification'),
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: DecorativeBackground(
          showTopLeftBubble: false,
          showBottomLeftBubble: true,
          showBottomRightBubble: false,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      S.text('verify_your_id'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      S.text('doc_desc'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textGrey,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Document Type Selector
                  Row(
                    children: [
                      _buildDocTypeChip(S.text('national_id'), 'national_id'),
                      const SizedBox(width: 10),
                      _buildDocTypeChip(S.text('passport'), 'passport'),
                      const SizedBox(width: 10),
                      _buildDocTypeChip(S.text('drivers_license'), 'drivers_license'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Front Side Upload
                  _buildUploadArea(
                    label: S.text('front_side'),
                    subtitle: S.text('tap_to_upload'),
                    isDashed: true,
                    isUploaded: _frontBytes != null,
                    onTap: () => _pickImage(true),
                  ),
                  const SizedBox(height: 16),
                  // Back Side Upload
                  _buildUploadArea(
                    label: S.text('back_side'),
                    subtitle: S.text('tap_to_upload'),
                    isDashed: false,
                    isUploaded: _backBytes != null,
                    onTap: () => _pickImage(false),
                  ),
                  const SizedBox(height: 20),
                  // Security Note
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔒', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          S.text('doc_secure_note'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitDocuments,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                            )
                          : Text(S.text('submit_docs')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MainShell(role: widget.role)),
                        (_) => false,
                      ),
                      child: Text(
                        S.text('skip_for_now'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocTypeChip(String label, String value) {
    final isSelected = _selectedDocType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDocType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.lightGrey,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea({
    required String label,
    required String subtitle,
    required bool isDashed,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    final isAr = S.isAr;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: isDashed ? DashedBorderPainter() : null,
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: isDashed
              ? null
              : BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.lightGrey),
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isUploaded)
                const Icon(Icons.check_circle,
                    color: AppTheme.primaryBlue, size: 40)
              else
                const Text('📄', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                isUploaded
                    ? (isAr ? 'تم رفع $label' : '$label Uploaded')
                    : label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              if (!isUploaded) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
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
