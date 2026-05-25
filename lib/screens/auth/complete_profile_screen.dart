import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../theme/app_theme.dart';
import '../../widgets/step_progress_bar.dart';
import '../../services/profile_data.dart';
import '../../services/api_service.dart';
import '../../services/auth_session.dart';
import '../../services/localization.dart';
import 'about_yourself_screen.dart';
import 'identity_photo_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String role;

  const CompleteProfileScreen({super.key, required this.role});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedCountry;
  bool _loading = false;

  Uint8List? _photoBytes;
  String? _photoName;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoName = image.name;
    });
  }

  final List<String> _countries = [
    'Egypt',
    'Saudi Arabia',
    'UAE',
    'Jordan',
    'Kuwait',
    'Qatar',
    'Bahrain',
    'Oman',
    'Iraq',
    'Lebanon',
  ];

  @override
  void initState() {
    super.initState();
    final pd = ProfileData.instance;
    if (pd.firstName.isNotEmpty)  _firstNameController.text  = pd.firstName;
    if (pd.middleName.isNotEmpty) _middleNameController.text = pd.middleName;
    if (pd.lastName.isNotEmpty)   _lastNameController.text   = pd.lastName;
    if (pd.dob.isNotEmpty)        _dobController.text        = pd.dob;
    if (pd.city.isNotEmpty)       _cityController.text       = pd.city;
    if (pd.country.isNotEmpty)    _selectedCountry           = pd.country;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _dobController.text =
            '${date.day.toString().padLeft(2, '0')} / ${date.month.toString().padLeft(2, '0')} / ${date.year}';
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      try {
        final dobStr = _dobController.text.trim();
        ProfileData.instance
          ..firstName  = _firstNameController.text.trim()
          ..middleName = _middleNameController.text.trim()
          ..lastName   = _lastNameController.text.trim()
          ..dob        = dobStr
          ..country    = _selectedCountry ?? ''
          ..city       = _cityController.text.trim();

        final res = await ApiService.saveUserProfile(
          token: AuthSession.instance.token,
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          age: ProfileData.instance.age,
          country: _selectedCountry ?? '',
          city: _cityController.text.trim(),
          photoBytes: _photoBytes,
          photoName: _photoName,
        );

        if (res['status'] == 200 || res['status'] == 201) {
          AuthSession.instance.name = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
          AuthSession.instance.city = _cityController.text.trim();
          AuthSession.instance.country = _selectedCountry ?? '';
          AuthSession.instance.dob = dobStr;

          if (!mounted) return;
          if (widget.role == 'admin') {
            // Admin/Sponsor needs to complete company details next (Step 3)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AboutYourselfScreen(role: widget.role),
              ),
            );
          } else {
            // Renter (already did AboutYourselfScreen) and Owner go directly to Identity photo upload
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IdentityPhotoScreen(role: widget.role),
              ),
            );
          }
        } else {
          final msg = res['body']['message'] ?? 'Failed to update profile';
          _showError(msg.toString());
        }
      } catch (e) {
        _showError('Network error: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  String _localCountry(String c) {
    if (!S.isAr) return c;
    switch (c) {
      case 'Egypt': return 'مصر';
      case 'Saudi Arabia': return 'السعودية';
      case 'UAE': return 'الإمارات';
      case 'Jordan': return 'الأردن';
      case 'Kuwait': return 'الكويت';
      case 'Qatar': return 'قطر';
      case 'Bahrain': return 'البحرين';
      case 'Oman': return 'عمان';
      case 'Iraq': return 'العراق';
      case 'Lebanon': return 'لبنان';
      default: return c;
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
            S.text('complete_profile'),
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
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
                const SizedBox(height: 8),
                const StepProgressBar(currentStep: 2, totalSteps: 3),
                const SizedBox(height: 24),
                // Profile Photo
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.bubblePurple.withValues(alpha: 0.3),
                            image: _photoBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(_photoBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _photoBytes == null
                              ? const Center(
                                  child: Text('📷', style: TextStyle(fontSize: 36)),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.text('add_photo'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // First Name
                _buildLabel(S.text('first_name')),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(hintText: isAr ? 'الاسم الأول' : 'John'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isAr ? 'الرجاء إدخال الاسم الأول' : 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Middle Name
                _buildLabel(S.text('middle_name')),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _middleNameController,
                  decoration: InputDecoration(hintText: isAr ? 'اختياري' : 'Optional'),
                ),
                const SizedBox(height: 20),
                // Last Name
                _buildLabel(S.text('last_name')),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(hintText: isAr ? 'اسم العائلة' : 'Doe'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isAr ? 'الرجاء إدخال اسم العائلة' : 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Date of Birth
                _buildLabel(S.text('dob')),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    hintText: 'DD / MM / YYYY',
                    suffixIcon: Icon(Icons.calendar_today_outlined,
                        color: AppTheme.grey, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return isAr ? 'الرجاء اختيار تاريخ الميلاد' : 'Please select your date of birth';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Country & City Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(S.text('country')),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            hint: Text(isAr ? 'اختر' : 'Select',
                                style: const TextStyle(
                                    color: AppTheme.grey, fontSize: 15)),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            items: _countries
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(_localCountry(c),
                                          style: const TextStyle(fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedCountry = value);
                            },
                            validator: (value) {
                              if (value == null) return isAr ? 'مطلوب' : 'Required';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(S.text('city')),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cityController,
                            decoration:
                                InputDecoration(hintText: isAr ? 'المدينة' : 'Enter city'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return isAr ? 'مطلوب' : 'Required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Save & Continue
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveAndContinue,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(S.text('save_continue')),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }
}
