import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
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
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  Set<Marker> _markers = {};

  Uint8List? _deedBytes;
  String? _deedName;
  final List<Uint8List> _photoBytesList = [];
  final List<String> _photoNamesList = [];
  final List<String> _deletePhotoIds = [];
  late List<Map<String, dynamic>> _existingPhotos;

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
    _latController = TextEditingController(text: apt.latitude?.toString() ?? '30.0444');
    _lngController = TextEditingController(text: apt.longitude?.toString() ?? '31.2357');
    
    if (apt.latitude != null && apt.longitude != null) {
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: LatLng(apt.latitude!, apt.longitude!),
        ),
      };
    }
    
    _existingPhotos = List<Map<String, dynamic>>.from(apt.rawPhotos);
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
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickDeed() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _deedBytes = result.files.single.bytes;
        _deedName = result.files.single.name;
      });
    }
  }

  Future<void> _pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      setState(() {
        for (final file in result.files) {
          if (file.bytes != null) {
            _photoBytesList.add(file.bytes!);
            _photoNamesList.add(file.name);
          }
        }
      });
    }
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
        'latitude': _latController.text.trim(),
        'longitude': _lngController.text.trim(),
        'location': '${_latController.text.trim()}, ${_lngController.text.trim()}',
      };
      final id = int.tryParse(widget.apartment.id) ?? 0;
      final res = await ApiService.updateApartment(
        token: AuthSession.instance.token,
        id: id,
        fields: fields,
        documentBytes: _deedBytes,
        documentName: _deedName,
        photoBytesList: _photoBytesList,
        photoNamesList: _photoNamesList,
        deletePhotos: _deletePhotoIds,
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
              _buildLabel('Location Coordinate (GPS)'),
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
                        zoom: 13,
                      ),
                      markers: _markers,
                      onTap: (pos) {
                        setState(() {
                          _latController.text = pos.latitude.toStringAsFixed(6);
                          _lngController.text = pos.longitude.toStringAsFixed(6);
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
                  const Icon(Icons.location_on, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_latController.text}, ${_lngController.text}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ] else ...[
                Row(children: [
                  Expanded(child: _buildField('Latitude', _latController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('Longitude', _lngController)),
                ]),
              ],
              const SizedBox(height: 20),
              _buildLabel('Amenities'),
              const SizedBox(height: 12),
              _buildToggleRow('AC', _hasAc, (v) => setState(() => _hasAc = v)),
              _buildToggleRow('Water', _hasWater, (v) => setState(() => _hasWater = v)),
              _buildToggleRow('Gas', _hasGas, (v) => setState(() => _hasGas = v)),
              _buildToggleRow('Furnished', _isFurnished, (v) => setState(() => _isFurnished = v)),
              const SizedBox(height: 20),
              _buildLabel('Ownership Deed (Verification Document)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDeed,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _deedBytes != null
                          ? AppTheme.primaryBlue
                          : AppTheme.lightGrey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _deedBytes != null
                            ? Icons.check_circle_outline
                            : Icons.attach_file_outlined,
                        color: _deedBytes != null
                            ? AppTheme.primaryBlue
                            : AppTheme.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _deedBytes != null
                              ? (_deedName ?? 'ownership_deed.pdf')
                              : 'Tap to update ownership deed PDF/Image',
                          style: TextStyle(
                            fontSize: 14,
                            color: _deedBytes != null
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
              const SizedBox(height: 20),
              _buildLabel('Apartment Photos'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                  label: const Text('Add New Photos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_existingPhotos.isNotEmpty || _photoBytesList.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._existingPhotos.map((photo) {
                        final photoId = photo['id']?.toString() ?? '';
                        final photoUrl = photo['url']?.toString() ?? '';
                        return Stack(
                          key: ValueKey('existing_$photoId'),
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.lightGrey),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              top: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _existingPhotos.removeWhere((p) => p['id'] == photo['id']);
                                    if (photoId.isNotEmpty) {
                                      _deletePhotoIds.add(photoId);
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.delete, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      ...List.generate(_photoBytesList.length, (idx) {
                        return Stack(
                          key: ValueKey('new_$idx'),
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.lightGrey),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(
                                  _photoBytesList[idx],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              top: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _photoBytesList.removeAt(idx);
                                    _photoNamesList.removeAt(idx);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
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
