import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _ageController;
  late String _gender;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final s = AuthSession.instance;
    _firstNameController = TextEditingController(text: s.name);
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController(text: s.phone);
    _cityController = TextEditingController(text: s.city);
    _countryController = TextEditingController(text: s.country);
    _ageController = TextEditingController();
    _gender = s.gender.isNotEmpty ? s.gender : 'male';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.saveUserProfile(
        token: AuthSession.instance.token,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 18,
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
      );
      if (!mounted) return;
      if (res['status'] == 200 || res['status'] == 201) {
        // Update local session
        final s = AuthSession.instance;
        if (_firstNameController.text.trim().isNotEmpty) {
          s.name = _firstNameController.text.trim();
        }
        s.city = _cityController.text.trim();
        s.country = _countryController.text.trim();
        s.gender = _gender;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final msg = res['body']['message'] ?? 'Update failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: AppTheme.primaryBlue),
          label: const Text('Back', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16)),
        ),
        leadingWidth: 100,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildField('First Name', _firstNameController, TextInputType.name),
              const SizedBox(height: 16),
              _buildField('Last Name', _lastNameController, TextInputType.name, required: false),
              const SizedBox(height: 16),
              _buildField('Phone', _phoneController, TextInputType.phone, required: false),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _buildField('City', _cityController, TextInputType.text, required: false)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Country', _countryController, TextInputType.text, required: false)),
              ]),
              const SizedBox(height: 16),
              _buildField('Age', _ageController, TextInputType.number, required: false),
              const SizedBox(height: 16),
              _buildLabel('Gender'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'male'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Profile'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark));
  }

  Widget _buildField(String label, TextEditingController ctrl, TextInputType type, {bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
        ),
      ],
    );
  }
}
