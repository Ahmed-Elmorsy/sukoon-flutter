import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';

class PublishApartmentScreen extends StatefulWidget {
  const PublishApartmentScreen({super.key});

  @override
  State<PublishApartmentScreen> createState() => _PublishApartmentScreenState();
}

class _PublishApartmentScreenState extends State<PublishApartmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _priceController       = TextEditingController();
  final _insuranceController   = TextEditingController();
  final _capacityController    = TextEditingController();
  final _roomsController       = TextEditingController(text: '2');
  final _bedsController        = TextEditingController(text: '2');
  final _rentDurationController= TextEditingController(text: '6');
  final _latController         = TextEditingController(text: '30.0444');
  final _lngController         = TextEditingController(text: '31.2357');

  String _genderAllowed = 'any';
  bool _hasAc        = false;
  bool _hasWater     = false;
  bool _hasGas       = false;
  bool _isFurnished  = false;
  bool _loading      = false;
  Set<Marker> _markers = {};

  // Admin: owner selection
  bool get _isAdmin => AuthSession.instance.role == 'admin';
  List<Map<String, dynamic>> _owners = [];
  int? _selectedOwnerId;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('selected'),
        position: LatLng(
          double.tryParse(_latController.text) ?? 30.0444,
          double.tryParse(_lngController.text) ?? 31.2357,
        ),
      ),
    };
    if (_isAdmin) _loadOwners();
  }

  Future<void> _loadOwners() async {
    try {
      final res = await ApiService.getOwners(AuthSession.instance.token);
      if (res['status'] == 200 && mounted) {
        setState(() => _owners = (res['body'] as List).cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _priceController.dispose();
    _insuranceController.dispose();
    _capacityController.dispose();
    _roomsController.dispose();
    _bedsController.dispose();
    _rentDurationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _publishApartment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fields = <String, String>{
          'price':          _priceController.text.trim(),
          'insurance':      _insuranceController.text.trim(),
          'capacity':       _capacityController.text.trim(),
          'male_count':     '0',
          'female_count':   '0',
          'gender_allowed': _genderAllowed,
          'rooms_count':    _roomsController.text.trim(),
          'beds_count':     _bedsController.text.trim(),
          'has_ac':         _hasAc ? '1' : '0',
          'has_water':      _hasWater ? '1' : '0',
          'has_gas':        _hasGas ? '1' : '0',
          'is_furnished':   _isFurnished ? '1' : '0',
          'status':         'open',
          'verification_status': 'pending',
          'rent_duration':  _rentDurationController.text.trim(),
          'latitude':       _latController.text.trim(),
          'longitude':      _lngController.text.trim(),
      };
      if (_isAdmin && _selectedOwnerId != null) {
        fields['owner_id'] = _selectedOwnerId.toString();
      }
      final res = await ApiService.createApartment(
        AuthSession.instance.token,
        fields,
      );
      if (!mounted) return;
      if (res['status'] == 201 || res['status'] == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🎉 Published!', textAlign: TextAlign.center),
            content: const Text(
              'Your apartment has been submitted for review.',
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      } else {
        final msg = res['body']['message'] ?? 'Failed to publish';
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
          'Publish Apartment',
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
              // Admin: Owner Picker
              if (_isAdmin) ...[
                const Text('Assign to Owner', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedOwnerId,
                      hint: const Text('Select owner...'),
                      isExpanded: true,
                      items: _owners.map((o) => DropdownMenuItem<int>(
                        value: o['id'] as int,
                        child: Text('${o['name']} (${o['email']})'),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedOwnerId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Price & Insurance
              Row(children: [
                Expanded(child: _buildField('Price / Month (EGP)', _priceController, hint: 'e.g. 3500')),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Insurance (EGP)', _insuranceController, hint: 'e.g. 700')),
              ]),
              const SizedBox(height: 20),
              // Capacity & Rent Duration
              Row(children: [
                Expanded(child: _buildField('Capacity (persons)', _capacityController, hint: 'e.g. 4')),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Rent Duration (months)', _rentDurationController, hint: 'e.g. 6')),
              ]),
              const SizedBox(height: 20),
              // Rooms & Beds
              Row(children: [
                Expanded(child: _buildField('Rooms', _roomsController, hint: 'e.g. 3')),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Beds', _bedsController, hint: 'e.g. 4')),
              ]),
              const SizedBox(height: 20),
              // Gender Allowed
              _buildLabel('Gender Allowed'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _genderAllowed,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'any',    child: Text('Any')),
                  DropdownMenuItem(value: 'male',   child: Text('Male only')),
                  DropdownMenuItem(value: 'female', child: Text('Female only')),
                ],
                onChanged: (v) => setState(() => _genderAllowed = v ?? 'any'),
              ),
              const SizedBox(height: 20),
              // Location
              _buildLabel('Location'),
              const SizedBox(height: 8),
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[  
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          double.tryParse(_latController.text) ?? 30.0444,
                          double.tryParse(_lngController.text) ?? 31.2357,
                        ),
                        zoom: 12,
                      ),
                      markers: _markers,
                      onTap: (pos) {
                        setState(() {
                          _latController.text =
                              pos.latitude.toStringAsFixed(6);
                          _lngController.text =
                              pos.longitude.toStringAsFixed(6);
                          _markers = {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: pos,
                            ),
                          };
                        });
                      },
                      zoomControlsEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_latController.text}, ${_lngController.text}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textGrey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ] else ...[  
                Row(children: [
                  Expanded(
                      child: _buildField('Latitude', _latController,
                          hint: '30.0444')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildField('Longitude', _lngController,
                          hint: '31.2357')),
                ]),
              ],
              const SizedBox(height: 20),
              // Amenity toggles
              _buildLabel('Amenities'),
              const SizedBox(height: 12),
              _buildToggleRow('AC',        _hasAc,       (v) => setState(() => _hasAc = v)),
              _buildToggleRow('Water',     _hasWater,    (v) => setState(() => _hasWater = v)),
              _buildToggleRow('Gas',       _hasGas,      (v) => setState(() => _hasGas = v)),
              _buildToggleRow('Furnished', _isFurnished, (v) => setState(() => _isFurnished = v)),
              const SizedBox(height: 32),
              // Publish Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _publishApartment,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Publish Apartment'),
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

  Widget _buildField(String label, TextEditingController ctrl, {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: hint),
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

