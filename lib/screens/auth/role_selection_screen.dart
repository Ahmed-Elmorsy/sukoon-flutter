import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/decorative_background.dart';
import '../../services/localization.dart';
import 'registration_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole; // 'renter', 'owner', or 'admin'

  void _continue() {
    if (_selectedRole != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationScreen(role: _selectedRole!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: S.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: DecorativeBackground(
          showTopRightBubble: true,
          showTopLeftBubble: false,
          showBottomRightBubble: false,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  // Title
                  Text(
                    S.text('who_are_you'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.text('choose_role_skoon'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Renter Card
                  _buildRoleCard(
                    emoji: '🏠',
                    title: S.text('i_am_renter'),
                    subtitle: S.text('renter_desc'),
                    value: 'renter',
                  ),
                  const SizedBox(height: 16),
                  // Owner Card
                  _buildRoleCard(
                    emoji: '🔑',
                    title: S.text('i_am_owner'),
                    subtitle: S.text('owner_desc'),
                    value: 'owner',
                  ),
                  const SizedBox(height: 16),
                  // Sponsor Card
                  _buildRoleCard(
                    emoji: '📢',
                    title: S.text('i_am_sponsor'),
                    subtitle: S.text('sponsor_desc'),
                    value: 'admin',
                  ),
                  const Spacer(),
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _selectedRole != null ? _continue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.selectedCardBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.3) : AppTheme.cardBorder,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
