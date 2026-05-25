import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/apartment.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';

class EditApartmentScreen extends StatefulWidget {
  final Apartment apartment;

  const EditApartmentScreen({super.key, required this.apartment});

  @override
  State<EditApartmentScreen> createState() => _EditApartmentScreenState();
}

class _EditApartmentScreenState extends State<EditApartmentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _priceController;
  late final TextEditingController _capacityController;
  late final TextEditingController _roomsController;
  late final TextEditingController _bedsController;
  late final TextEditingController _rentDurationController;

  late String _genderAllowed;
  late bool _hasAc;
  late bool _hasWater;
  late bool _hasGas;
  late bool _isFurnished;
  late String _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final apt = widget.apartment;
    _priceController = TextEditingController(text: apt.pricePerMonth.toStringAsFixed(0));
    _capacityController = TextEditingController(text: apt.capacity.toString());
    _roomsController = TextEditingController(text: apt.rooms.toString());
    _bedsController = TextEditingController(text: '1');
    _rentDurationController = TextEditingController(text: '6');
    _genderAllowed = 'any';
    _hasAc = apt.amenities.contains('AC');
    _hasWater = apt.amenities.contains('Water');
    _hasGas = apt.amenities.contains('Gas');
    _isFurnished = apt.amenities.contains('Furnished');
    _status = apt.status == 'available' ? 'open' : apt.status;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _capacityController.dispose();
    _roomsController.dispose();
    _bedsController.dispose();
    _rentDurationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fields = <String, String>{
        'price': _priceController.text.trim(),
        'capacity': _capacityController.text.trim(),
        'rooms_count': _roomsController.text.trim(),
        'beds_count': _bedsController.text.trim(),
        'gender_allowed': _genderAllowed,
        'has_ac': _hasAc ? '1' : '0',
        'has_water': _hasWater ? '1' : '0',
        'has_gas': _hasGas ? '1' : '0',
        'is_furnished': _isFurnished ? '1' : '0',
        'status': _status,
        'rent_duration': _rentDurationController.text.trim(),
      };
      final id = int.tryParse(widget.apartment.id) ?? 0;
      final res = await ApiService.updateApartment(
        AuthSession.instance.token,
        id,
        fields,
      );
      if (!mounted) return;
      if (res['status'] == 200 || res['status'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apartment updated successfully'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final msg = res['body']['message'] ?? res['body']['error'] ?? 'Update failed';
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
          'Edit Apartment',
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
              const SizedBox(height: 16),
              _buildField('Price / Month (EGP)', _priceController),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildField('Capacity', _capacityController)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Rent Duration (months)', _rentDurationController)),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildField('Rooms', _roomsController)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Beds', _bedsController)),
              ]),
              const SizedBox(height: 20),
              _buildLabel('Gender Allowed'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _genderAllowed,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Any')),
                  DropdownMenuItem(value: 'male', child: Text('Male only')),
                  DropdownMenuItem(value: 'female', child: Text('Female only')),
                ],
                onChanged: (v) => setState(() => _genderAllowed = v ?? 'any'),
              ),
              const SizedBox(height: 20),
              _buildLabel('Status'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(value: 'full', child: Text('Full')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'open'),
              ),
              const SizedBox(height: 20),
              _buildLabel('Amenities'),
              const SizedBox(height: 12),
              _buildToggleRow('AC', _hasAc, (v) => setState(() => _hasAc = v)),
              _buildToggleRow('Water', _hasWater, (v) => setState(() => _hasWater = v)),
              _buildToggleRow('Gas', _hasGas, (v) => setState(() => _hasGas = v)),
              _buildToggleRow('Furnished', _isFurnished, (v) => setState(() => _isFurnished = v)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveChanges,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
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

  Widget _buildField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: AppTheme.textDark)),
          Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryBlue),
        ],
      ),
    );
  }
}
