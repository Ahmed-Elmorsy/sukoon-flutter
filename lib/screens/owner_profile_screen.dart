import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/auth_session.dart';
import '../services/app_logger.dart';
import '../services/api_service.dart';
import 'auth/choose_language_screen.dart';
import 'edit_profile_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  bool _isLoading = false;
  String? _documentType = 'national_id';
  final _docNumberController = TextEditingController();
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  @override
  void dispose() {
    _docNumberController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    try {
      final me = await ApiService.getMe(AuthSession.instance.token);
      if (me['status'] == 200) {
        setState(() {
          AuthSession.instance.updateFromMe(me['body']);
        });
      }
    } catch (e) {
      AppLogger.instance.error('OWNER_PROFILE', 'Error refreshing profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpeg', 'png', 'jpg'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      AppLogger.instance.error('OWNER_PROFILE', 'Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick document')),
        );
      }
    }
  }

  Future<void> _submitIdentityDocument() async {
    if (_docNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your document number')),
      );
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your document file')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      Uint8List bytes;
      if (_selectedFile!.bytes != null) {
        bytes = _selectedFile!.bytes!;
      } else {
        bytes = await File(_selectedFile!.path!).readAsBytes();
      }

      final res = await ApiService.uploadOwnerIdentityDocument(
        token: AuthSession.instance.token,
        type: _documentType!,
        documentNumber: _docNumberController.text.trim(),
        fileBytes: bytes,
        fileName: _selectedFile!.name,
      );

      if (res['status'] == 201 || res['status'] == 200) {
        _docNumberController.clear();
        setState(() {
          _selectedFile = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Identity document uploaded successfully')),
          );
        }
        await _refreshProfile();
      } else {
        final error = res['body']['message'] ?? 'Upload failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
      }
    } catch (e) {
      AppLogger.instance.error('OWNER_PROFILE', 'Error uploading document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload document')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPayoutBottomSheet() {
    final formKey = GlobalKey<FormState>();
    String tempType = AuthSession.instance.payoutType.isNotEmpty 
        ? AuthSession.instance.payoutType 
        : 'bank';
    final numberController = TextEditingController(text: AuthSession.instance.payoutNumber);
    final infoController = TextEditingController(text: AuthSession.instance.payoutInfo);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payout Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Payout Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: tempType,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                        DropdownMenuItem(value: 'wallet', child: Text('Mobile Wallet (Vodafone / Orange Cash)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => tempType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tempType == 'bank' ? 'Bank Account / IBAN Number' : 'Wallet Phone Number',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: numberController,
                      keyboardType: tempType == 'wallet' ? TextInputType.phone : TextInputType.text,
                      decoration: InputDecoration(
                        hintText: tempType == 'bank' ? 'EG1234567890...' : '01xxxxxxxxx',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Additional Payout Info',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: infoController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Enter bank name, swift code, holder name...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            setState(() => _isLoading = true);
                            try {
                              final res = await ApiService.updatePayoutInfo(
                                token: AuthSession.instance.token,
                                payoutType: tempType,
                                payoutNumber: numberController.text.trim(),
                                payoutInfo: infoController.text.trim(),
                              );
                              if (!context.mounted) return;
                              if (res['status'] == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Payout details updated')),
                                );
                                await _refreshProfile();
                              } else {
                                final err = res['body']['message'] ?? 'Failed to update';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $err')),
                                );
                              }
                            } catch (e) {
                              AppLogger.instance.error('OWNER_PROFILE', 'Payout update error: $e');
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          }
                        },
                        child: const Text('Save Payout Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = AuthSession.instance.identityDocStatus;
    final isVerified = AuthSession.instance.idVerified;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Owner Profile',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refreshProfile,
            icon: const Icon(Icons.refresh, color: AppTheme.textDark),
          ),
        ],
      ),
      body: _isLoading && AuthSession.instance.name.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshProfile,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Header Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Text('🏢', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AuthSession.instance.name.isEmpty ? 'Owner User' : AuthSession.instance.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Property Owner',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Verification status badge
                    _buildVerificationBadge(status, isVerified),
                    const SizedBox(height: 28),

                    // Verification document upload or review
                    _buildIdentitySection(status, isVerified),
                    const SizedBox(height: 16),

                    // Payout details card
                    _buildPayoutCard(),
                    const SizedBox(height: 16),

                    // Personal details card
                    _buildSectionCard(
                      title: 'Personal Details',
                      children: [
                        _buildInfoRow(Icons.email_outlined, 'Email',
                            AuthSession.instance.email.isEmpty ? '—' : AuthSession.instance.email),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.phone_outlined, 'Phone',
                            AuthSession.instance.phone.isEmpty ? 'Not set' : AuthSession.instance.phone),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.location_on_outlined, 'Address',
                            _buildLocationString()),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.person_outline, 'Gender',
                            AuthSession.instance.gender.isEmpty ? 'Not set' : AuthSession.instance.gender),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.cake_outlined, 'Age',
                            AuthSession.instance.dob.isEmpty ? 'Not set' : AuthSession.instance.dob),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Edit Profile Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                          if (updated == true) {
                            _refreshProfile();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Logout Button
                    TextButton(
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        if (AuthSession.instance.isLoggedIn) {
                          await ApiService.logout(AuthSession.instance.token);
                        }
                        AuthSession.instance.clear();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const ChooseLanguageScreen()),
                          (_) => false,
                        );
                      },
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
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

  Widget _buildVerificationBadge(String status, bool isVerified) {
    Color bg = AppTheme.inputBackground;
    Color fg = AppTheme.grey;
    IconData icon = Icons.pending_outlined;
    String label = 'Not Verified';

    if (isVerified) {
      bg = AppTheme.bubbleGreen.withValues(alpha: 0.4);
      fg = const Color(0xFF2E7D32);
      icon = Icons.verified;
      label = 'Verified Owner';
    } else if (status == 'pending') {
      bg = const Color(0xFFFFF3E0);
      fg = Colors.orange;
      icon = Icons.hourglass_empty;
      label = 'Verification Pending';
    } else if (status == 'rejected') {
      bg = const Color(0xFFFFEBEE);
      fg = Colors.red;
      icon = Icons.error_outline;
      label = 'Verification Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(String status, bool isVerified) {
    if (isVerified) {
      return _buildSectionCard(
        title: 'Identity Verification Status',
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Documents Verified',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    Text(
                      'Type: ${AuthSession.instance.identityDocType.toUpperCase()} - Number: ${AuthSession.instance.identityDocNumber}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (status == 'pending') {
      return _buildSectionCard(
        title: 'Identity Verification Status',
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Admin Review',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    Text(
                      'Your document (${AuthSession.instance.identityDocType.toUpperCase()}) is currently being reviewed by our moderation team.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return _buildSectionCard(
      title: 'Upload Identity Document',
      children: [
        if (status == 'rejected') ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Previous Submission Rejected',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                      ),
                      Text(
                        'Reason: ${AuthSession.instance.identityDocRejectionReason.isEmpty ? "Invalid documents or details mismatch" : AuthSession.instance.identityDocRejectionReason}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Please upload a valid government-issued ID card or Passport for identity verification.',
          style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _documentType,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'national_id', child: Text('National ID')),
                  DropdownMenuItem(value: 'passport', child: Text('Passport')),
                  DropdownMenuItem(value: 'other', child: Text('Other ID')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _documentType = val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _docNumberController,
          decoration: const InputDecoration(
            labelText: 'Document Number',
            hintText: 'Enter ID number',
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickDocument,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.values[1]),
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.primaryBlue.withValues(alpha: 0.02),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryBlue, size: 36),
                const SizedBox(height: 8),
                Text(
                  _selectedFile != null ? _selectedFile!.name : 'Pick Document File (PDF, Image)',
                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                ),
                if (_selectedFile != null)
                  Text(
                    '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitIdentityDocument,
            child: _isLoading 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Submit ID Verification'),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutCard() {
    final type = AuthSession.instance.payoutType;
    final number = AuthSession.instance.payoutNumber;
    final info = AuthSession.instance.payoutInfo;

    return _buildSectionCard(
      title: 'Payout Settings',
      children: [
        if (number.isEmpty) ...[
          const Text(
            'You haven\'t configured your payout method yet. Configure it to receive payments for your properties.',
            style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 12),
        ] else ...[
          _buildInfoRow(
            type == 'wallet' ? Icons.phone_android_outlined : Icons.account_balance_outlined,
            'Method',
            type == 'wallet' ? 'Mobile Wallet' : 'Bank Account',
          ),
          const Divider(height: 20),
          _buildInfoRow(Icons.pin_outlined, 'Number / Account', number),
          if (info.isNotEmpty) ...[
            const Divider(height: 20),
            _buildInfoRow(Icons.info_outline, 'Details', info),
          ],
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _showPayoutBottomSheet,
            icon: const Icon(Icons.payment, size: 18),
            label: Text(number.isEmpty ? 'Set Payout Method' : 'Change Payout Settings'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildLocationString() {
    final city = AuthSession.instance.city;
    final country = AuthSession.instance.country;
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (city.isNotEmpty) return city;
    if (country.isNotEmpty) return country;
    return 'Not set';
  }
}
