import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/apartment.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../services/recommender_service.dart';
import 'apartment_detail_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchController = TextEditingController();
  String _selectedType = 'all';
  RangeValues _priceRange = const RangeValues(0, 15000);
  int? _selectedRooms;
  bool? _prefersFurnished;
  bool _showFilters = false;
  List<Apartment> _allApartments = [];
  List<Apartment> _filteredApartments = [];
  bool _smartRankActive = false;
  bool _rankingLoading = false;
  Map<int, int> _rankMap = {};

  @override
  void initState() {
    super.initState();
    _loadFromApi();
  }

  Future<void> _loadFromApi() async {
    try {
      final res = await ApiService.getApartments(AuthSession.instance.token);
      if (res['status'] == 200 && mounted) {
        final list = res['body'] as List<dynamic>;
        final apts = list
            .map((j) => Apartment.fromJson(j as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.title.compareTo(b.title));
        setState(() {
          _allApartments      = apts;
          _filteredApartments = apts;
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _allApartments      = [];
      _filteredApartments = [];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredApartments = _allApartments.where((apt) {
        final matchesSearch = _searchController.text.isEmpty ||
            apt.title
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            apt.address
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        final matchesType =
            _selectedType == 'all' || apt.type == _selectedType;

        final matchesPrice = apt.pricePerMonth >= _priceRange.start &&
            apt.pricePerMonth <= _priceRange.end;

        final matchesFurnished = _prefersFurnished == null ||
            apt.amenities.contains('Furnished') == _prefersFurnished;

        final matchesRooms =
            _selectedRooms == null || apt.rooms == _selectedRooms;

        return matchesSearch && matchesType && matchesPrice && matchesRooms && matchesFurnished;
      }).toList();

      if (_smartRankActive && _rankMap.isNotEmpty) {
        _filteredApartments.sort((a, b) {
          final ra = _rankMap[int.tryParse(a.id) ?? -1] ?? 9999;
          final rb = _rankMap[int.tryParse(b.id) ?? -1] ?? 9999;
          return ra.compareTo(rb);
        });
      } else {
        _filteredApartments.sort((a, b) => a.title.compareTo(b.title));
      }
    });
  }

  Future<void> _smartRank() async {
    setState(() => _rankingLoading = true);

    final location = _searchController.text.trim().isEmpty
        ? 'Cairo'
        : _searchController.text.trim();

    final result = await RecommenderService.recommend(
      budgetMin: _priceRange.start,
      budgetMax: _priceRange.end,
      preferredLocation: location,
      prefersFurnished: _prefersFurnished == null ? null : (_prefersFurnished! ? 1 : 0),
      n: 50,
    );

    if (!mounted) return;

    if (result != null && result.recommendations.isNotEmpty) {
      setState(() {
        _rankMap = result.rankMap;
        _smartRankActive = true;
        _rankingLoading = false;
      });
      _applyFilters();
    } else {
      setState(() => _rankingLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not reach the recommender service'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Search Apartments',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Search by name or location...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.grey, size: 22),
                      filled: true,
                      fillColor: AppTheme.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _showFilters
                          ? AppTheme.primaryBlue
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _showFilters
                            ? AppTheme.primaryBlue
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: _showFilters ? Colors.white : AppTheme.textDark,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filter Panel
          if (_showFilters) _buildFilterPanel(),
          // Type Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildTypeChip('All', 'all'),
                _buildTypeChip('Studio', 'studio'),
                _buildTypeChip('Apartment', 'apartment'),
                _buildTypeChip('Villa', 'villa'),
                _buildTypeChip('Duplex', 'duplex'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredApartments.length} results found',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Results List
          Expanded(
            child: _filteredApartments.isEmpty
                ? _buildNoResults()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filteredApartments.length,
                    itemBuilder: (context, index) {
                      return _buildResultCard(
                          context, _filteredApartments[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Range (EGP)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 15000,
            divisions: 30,
            activeColor: AppTheme.primaryBlue,
            inactiveColor: AppTheme.lightGrey,
            labels: RangeLabels(
              '${_priceRange.start.toInt()}',
              '${_priceRange.end.toInt()}',
            ),
            onChanged: (values) {
              setState(() => _priceRange = values);
              _applyFilters();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EGP ${_priceRange.start.toInt()}',
                  style:
                      const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
              Text('EGP ${_priceRange.end.toInt()}',
                  style:
                      const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Number of Rooms',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [null, 1, 2, 3].map((rooms) {
              final isSelected = _selectedRooms == rooms;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedRooms = rooms);
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.lightGrey,
                      ),
                    ),
                    child: Text(
                      rooms == null ? 'Any' : '$rooms+',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textGrey,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Furnished',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Row(
            children: [null, true, false].map((val) {
              final isSelected = _prefersFurnished == val;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _prefersFurnished = val);
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AppTheme.primaryBlue : AppTheme.lightGrey),
                    ),
                    child: Text(
                      val == null ? 'Any' : val ? 'Yes' : 'No',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textGrey,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _rankingLoading ? null : _smartRank,
              icon: _rankingLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_smartRankActive ? 'Re-rank Results' : 'Smart Rank'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _smartRankActive
                    ? AppTheme.primaryBlue.withValues(alpha: 0.85)
                    : AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_smartRankActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 14, color: AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Results ranked by AI recommendation',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _smartRankActive = false;
                        _rankMap = {};
                      });
                      _applyFilters();
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _selectedType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedType = value);
          _applyFilters();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No apartments found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Apartment apt) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ApartmentDetailScreen(
              apartment: apt,
              isOwnerView: false,
            ),
          ),
        );
        if (changed == true) _loadFromApi();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bubblePurple.withValues(alpha: 0.25),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  const Center(
                      child: Text('🏠', style: TextStyle(fontSize: 44))),
                  // Price tag
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'EGP ${apt.pricePerMonth.toStringAsFixed(0)}/mo',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Favourite button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_outline,
                          color: AppTheme.textGrey, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apt.title,
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
                      Text(
                        apt.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildInfoTag(
                          Icons.bed_outlined, '${apt.rooms} Rooms'),
                      const SizedBox(width: 10),
                      _buildInfoTag(
                          Icons.people_outline, '${apt.freeSpots}/${apt.capacity} Free'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: apt.isFull
                              ? Colors.red.withValues(alpha: 0.15)
                              : AppTheme.bubbleGreen.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          apt.isFull ? 'Full' : 'Available',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: apt.isFull ? Colors.red : const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textGrey),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}

