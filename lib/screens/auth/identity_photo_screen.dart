import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/step_progress_bar.dart';
import '../../services/id_verification_service.dart';
import '../../services/localization.dart';
import 'document_verification_screen.dart';

class IdentityPhotoScreen extends StatefulWidget {
  final String role;

  const IdentityPhotoScreen({super.key, required this.role});

  @override
  State<IdentityPhotoScreen> createState() => _IdentityPhotoScreenState();
}

class _IdentityPhotoScreenState extends State<IdentityPhotoScreen> {
  Uint8List? _selfieBytes;
  bool _isChecking = false;
  String? _errorMessage;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    XFile? photo;

    try {
      photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
      );
    } catch (_) {
      photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
    }

    if (photo == null) return;

    final bytes = await photo.readAsBytes();

    setState(() {
      _selfieBytes = bytes;
      _isChecking = true;
      _errorMessage = null;
    });

    final service = IdVerificationService();
    final livenessResult = await service.checkLiveness(bytes);

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (livenessResult.passed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentVerificationScreen(
            role: widget.role,
            selfieBytes: bytes,
          ),
        ),
      );
    } else {
      final detail = livenessResult.error != null
          ? '\n\nDetails: ${livenessResult.error}'
          : '';
      setState(() {
        _selfieBytes = null;
        _errorMessage = S.isAr
            ? 'فشل التحقق من الحيوية. يرجى التأكد من الإضاءة الجيدة والمحاولة مرة أخرى.$detail'
            : 'Liveness check failed. Please ensure good lighting and try again.$detail';
      });
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
            S.text('identity_verification'),
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const StepProgressBar(currentStep: 3, totalSteps: 3),
              const SizedBox(height: 32),
              Text(
                S.text('take_selfie'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                S.text('take_selfie_desc'),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textGrey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selfieBytes != null
                          ? AppTheme.primaryBlue
                          : AppTheme.lightGrey,
                      width: 2.5,
                    ),
                  ),
                  child: _isChecking
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                                color: AppTheme.primaryBlue),
                            const SizedBox(height: 16),
                            Text(
                              isAr ? 'جاري التحقق من الحيوية...' : 'Checking liveness...',
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        )
                      : _selfieBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.memory(
                                _selfieBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('😐',
                                    style: TextStyle(fontSize: 60)),
                                const SizedBox(height: 16),
                                Text(
                                  isAr ? 'ضع وجهك داخل الإطار' : 'Align face here',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _takePhoto,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('📸',
                          style: TextStyle(fontSize: 20)),
                  label: Text(
                    _isChecking
                        ? (isAr ? 'جاري التحقق...' : 'Checking...')
                        : _selfieBytes != null
                            ? (isAr ? 'إعادة التقاط الصورة' : 'Retake Photo')
                            : (isAr ? 'التقاط صورة' : 'Take Photo'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
