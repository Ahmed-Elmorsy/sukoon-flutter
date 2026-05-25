import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/verification_session.dart';
import '../services/auth_session.dart';
import '../services/app_logger.dart';
import '../services/api_service.dart';
import 'log_viewer_screen.dart';
import 'auth/choose_language_screen.dart';
import 'auth/identity_photo_screen.dart';
import 'edit_profile_screen.dart';

class TenantProfileScreen extends StatelessWidget {
  final String role;

  const TenantProfileScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Settings
            },
            icon: const Icon(Icons.settings_outlined,
                color: AppTheme.textDark, size: 24),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar & Name
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
                child: Text('👤', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AuthSession.instance.name.isEmpty ? 'User' : AuthSession.instance.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role == 'owner' ? 'Property Owner' : 'Tenant',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            // Verification badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: VerificationSession.isFullyVerified
                    ? AppTheme.bubbleGreen.withValues(alpha: 0.4)
                    : AppTheme.inputBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    VerificationSession.isFullyVerified
                        ? Icons.verified
                        : Icons.pending_outlined,
                    color: VerificationSession.isFullyVerified
                        ? const Color(0xFF2E7D32)
                        : AppTheme.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    VerificationSession.isFullyVerified
                        ? 'Verified'
                        : 'Pending Verification',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VerificationSession.isFullyVerified
                          ? const Color(0xFF2E7D32)
                          : AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Personal Details Section
            _buildSectionCard(
              title: 'Personal Details',
              children: [
                _buildInfoRow(Icons.email_outlined, 'Email',
                    AuthSession.instance.email.isEmpty ? '—' : AuthSession.instance.email),
                const Divider(height: 20),
                _buildInfoRow(Icons.phone_outlined, 'Phone',
                    AuthSession.instance.phone.isEmpty ? 'Not set' : AuthSession.instance.phone),
                const Divider(height: 20),
                _buildInfoRow(Icons.badge_outlined, 'ID Number',
                    _ocrField(AuthSession.instance.idNumber,
                        VerificationSession.result?.ocrFront?.idNumber)),
                const Divider(height: 20),
                _buildInfoRow(Icons.cake_outlined, 'Date of Birth',
                    _ocrField(AuthSession.instance.birthDate.isNotEmpty
                        ? AuthSession.instance.birthDate
                        : AuthSession.instance.dob,
                        VerificationSession.result?.ocrFront?.birthDateFormatted)),
                const Divider(height: 20),
                _buildInfoRow(Icons.location_on_outlined, 'Address',
                    _ocrField(AuthSession.instance.address,
                        VerificationSession.result?.ocrFront?.address,
                        fallback: _buildLocationString())),
                const Divider(height: 20),
                _buildInfoRow(Icons.person_outline, 'Gender',
                    _ocrField(AuthSession.instance.gender,
                        VerificationSession.result?.ocrBack?.gender)),
                const Divider(height: 20),
                _buildInfoRow(Icons.church_outlined, 'Religion',
                    _ocrField(AuthSession.instance.religion,
                        VerificationSession.result?.ocrBack?.religion)),
                const Divider(height: 20),
                _buildInfoRow(Icons.favorite_outline, 'Marital Status',
                    _ocrField(AuthSession.instance.maritalStatus,
                        VerificationSession.result?.ocrBack?.maritalStatus)),
              ],
            ),
            const SizedBox(height: 16),
            // Occupation Section
            _buildSectionCard(
              title: 'Occupation',
              children: [
                _buildInfoRow(Icons.work_outline, 'Profession',
                    _ocrField(AuthSession.instance.profession,
                        VerificationSession.result?.ocrBack?.profession)),
              ],
            ),
            const SizedBox(height: 16),
            // ID Card Details Section
            _buildSectionCard(
              title: 'ID Card Details',
              children: [
                _buildInfoRow(Icons.calendar_today_outlined, 'Issue Date',
                    _ocrField(AuthSession.instance.idIssueDate,
                        VerificationSession.result?.ocrBack?.issueDate)),
                const Divider(height: 20),
                _buildInfoRow(Icons.event_outlined, 'Expiry Date',
                    _ocrField(AuthSession.instance.idExpiryDate,
                        VerificationSession.result?.ocrBack?.expiryDate)),
              ],
            ),
            const SizedBox(height: 16),
            // Documents Section
            _buildSectionCard(
              title: 'Documents',
              children: [
                _buildDocRow(
                  'National ID',
                  AuthSession.instance.idVerified ||
                      (VerificationSession.result?.validation?.idValid ?? false),
                ),
                const Divider(height: 20),
                _buildDocRow(
                  'Face Match',
                  VerificationSession.isFaceVerified,
                ),
                const Divider(height: 20),
                _buildDocRow(
                  'Liveness Check',
                  VerificationSession.isLivenessVerified,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Re-verify Identity Button (shown when not fully verified)
            if (!VerificationSession.isFullyVerified)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IdentityPhotoScreen(role: role),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_user_outlined, size: 20),
                    label: const Text(
                      'Re-verify Identity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
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
                  if (updated == true && context.mounted) {
                    (context as Element).markNeedsBuild();
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: AppTheme.primaryBlue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
            // View Logs Button (admin only)
            if (AuthSession.instance.role == 'admin') ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogViewerScreen()),
                ),
                icon: const Icon(Icons.terminal_outlined, color: AppTheme.primaryBlue),
                label: const Text(
                  'View App Logs',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            // Log Out Button
            TextButton(
              onPressed: () async {
                AppLogger.instance.info('AUTH', 'User tapped Log Out');
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
    );
  }

  String _ocrField(String? persisted, String? sessionValue, {String fallback = 'Not set'}) {
    if (persisted != null && persisted.isNotEmpty) return persisted;
    if (sessionValue != null && sessionValue.isNotEmpty) return sessionValue;
    return fallback;
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

  Widget _buildDocRow(String label, bool isVerified) {
    return Row(
      children: [
        Icon(
          isVerified ? Icons.check_circle : Icons.pending_outlined,
          size: 20,
          color: isVerified ? const Color(0xFF2E7D32) : AppTheme.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isVerified
                ? AppTheme.bubbleGreen.withValues(alpha: 0.4)
                : AppTheme.inputBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isVerified ? 'Verified' : 'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isVerified ? const Color(0xFF2E7D32) : AppTheme.textGrey,
            ),
          ),
        ),
      ],
    );
  }
}

