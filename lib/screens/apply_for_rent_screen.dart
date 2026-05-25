import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../models/apartment.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import 'apartment_detail_screen.dart';

class ApplyForRentScreen extends StatefulWidget {
  final Apartment apartment;

  const ApplyForRentScreen({super.key, required this.apartment});

  @override
  State<ApplyForRentScreen> createState() => _ApplyForRentScreenState();
}

class _ApplyForRentScreenState extends State<ApplyForRentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _moveInDateController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedDuration;
  int _occupants = 1;
  Uint8List? _contractBytes;
  String? _contractName;
  bool _loading = false;

  final List<String> _durations = [
    '3 months',
    '6 months',
    '1 year',
    '2 years',
  ];

  @override
  void dispose() {
    _moveInDateController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        _moveInDateController.text =
            '${date.day.toString().padLeft(2, '0')} / ${date.month.toString().padLeft(2, '0')} / ${date.year}';
      });
    }
  }

  Future<void> _pickContract() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _contractBytes = result.files.single.bytes;
        _contractName = result.files.single.name;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contractBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach your contract document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final apartmentId = int.tryParse(widget.apartment.id) ?? 0;

      // Step 1: Join the apartment (creates membership) before uploading contract
      final joinRes = await ApiService.joinApartment(
        AuthSession.instance.token,
        apartmentId,
      );
      // 400 = already joined — that's fine, continue
      if (joinRes['status'] != 200 && joinRes['status'] != 400) {
        if (!mounted) return;
        final msg = joinRes['body']?['error'] ?? 'Failed to join apartment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
        );
        setState(() => _loading = false);
        return;
      }

      // Step 2: Upload the contract
      final res = await ApiService.createContract(
        token: AuthSession.instance.token,
        apartmentId: apartmentId,
        documentBytes: _contractBytes!,
        fileName: _contractName ?? 'contract.pdf',
      );
      if (!mounted) return;
      if (res['status'] == 200 || res['status'] == 201) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.bubbleGreen.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('🎉', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 20),
                const Text('Application Submitted!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text(
                  'Your contract has been uploaded and is pending review.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textGrey, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ApartmentDetailScreen(
                            apartment: widget.apartment,
                            isJoined: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Apartment'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      } else {
        final msg = res['body']['message'] ?? 'Submission failed';
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
          label: const Text(
            'Back',
            style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
          ),
        ),
        leadingWidth: 100,
        title: const Text(
          'Apply for Rent',
          style: TextStyle(
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
              const SizedBox(height: 16),
              // Apartment Summary Card
              _buildApartmentSummary(),
              const SizedBox(height: 28),
              // Section Title
              const Text(
                'Rental Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),
              // Move-in Date
              _buildLabel('Preferred Move-in Date'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _moveInDateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  hintText: 'DD / MM / YYYY',
                  suffixIcon: Icon(Icons.calendar_today_outlined,
                      color: AppTheme.grey, size: 20),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please select a date' : null,
              ),
              const SizedBox(height: 20),
              // Lease Duration
              _buildLabel('Lease Duration'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDuration,
                hint: const Text('Select duration',
                    style: TextStyle(color: AppTheme.grey, fontSize: 15)),
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _durations
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, style: const TextStyle(fontSize: 15)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDuration = v),
                validator: (v) => v == null ? 'Please select a duration' : null,
              ),
              const SizedBox(height: 20),
              // Number of Occupants
              _buildLabel('Number of Occupants'),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_occupants > 1) setState(() => _occupants--);
                      },
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppTheme.primaryBlue, size: 26),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    Text(
                      '$_occupants',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _occupants++),
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppTheme.primaryBlue, size: 26),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Message to Owner
              _buildLabel('Message to Owner (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Introduce yourself and share why you\'re interested in this apartment...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              // Contract File Picker
              _buildLabel('Contract Document'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickContract,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _contractBytes != null
                          ? AppTheme.primaryBlue
                          : AppTheme.lightGrey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _contractBytes != null
                            ? Icons.check_circle_outline
                            : Icons.attach_file_outlined,
                        color: _contractBytes != null
                            ? AppTheme.primaryBlue
                            : AppTheme.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _contractBytes != null
                              ? (_contractName ?? 'contract.pdf')
                              : 'Tap to attach contract PDF',
                          style: TextStyle(
                            fontSize: 14,
                            color: _contractBytes != null
                                ? AppTheme.textDark
                                : AppTheme.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.selectedCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                      width: 3,
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Text('ℹ️', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The owner will review your application and may contact you for additional information.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitApplication,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Application'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApartmentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: AppTheme.bubblePurple.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🏠', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.apartment.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.apartment.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'EGP ${widget.apartment.pricePerMonth.toStringAsFixed(0)}/mo',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
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

