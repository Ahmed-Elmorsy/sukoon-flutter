class Apartment {
  final String id;
  final String title;
  final String address;
  final String description;
  final double pricePerMonth;
  final int rooms;
  final int bathrooms;
  final double areaSqm;
  final String type; // 'studio', 'apartment', 'villa', 'duplex'
  final List<String> amenities;
  final List<String> imageUrls;
  final String ownerName;
  final String status; // 'available', 'rented', 'pending'
  final bool isJoined;
  final double? latitude;
  final double? longitude;
  final int capacity;
  final int occupantsCount;

  int get freeSpots => (capacity - occupantsCount).clamp(0, capacity);
  bool get isFull => freeSpots == 0 && capacity > 0;

  const Apartment({
    required this.id,
    required this.title,
    required this.address,
    this.description = '',
    required this.pricePerMonth,
    this.rooms = 1,
    this.bathrooms = 1,
    this.areaSqm = 50,
    this.type = 'apartment',
    this.amenities = const [],
    this.imageUrls = const [],
    this.ownerName = 'Owner',
    this.status = 'available',
    this.isJoined = false,
    this.latitude,
    this.longitude,
    this.capacity = 1,
    this.occupantsCount = 0,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'].toString(),
      title: 'Apartment #${json['id']}',
      address: json['location'] != null ? json['location'].toString() : 'Cairo, Egypt',
      description: '',
      pricePerMonth: double.tryParse(json['price'].toString()) ?? 0,
      rooms: json['rooms_count'] ?? 1,
      bathrooms: 1,
      areaSqm: 50,
      type: 'apartment',
      amenities: [
        if (json['has_ac'] == true) 'AC',
        if (json['has_water'] == true) 'Water',
        if (json['has_gas'] == true) 'Gas',
        if (json['is_furnished'] == true) 'Furnished',
      ],
      ownerName: 'Owner #${json['owner_id']}',
      status: _mapStatus(json['status']),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      capacity: json['capacity'] ?? 1,
      occupantsCount: json['occupants_count'] ?? (json['male_count'] ?? 0) + (json['female_count'] ?? 0),
    );
  }

  static String _mapStatus(dynamic raw) {
    final s = (raw ?? 'open').toString();
    switch (s) {
      case 'open': return 'available';
      case 'full': return 'rented';
      case 'closed': return 'rented';
      default: return s;
    }
  }

  static List<Apartment> mockApartments = [
    const Apartment(
      id: '1',
      title: 'Modern Studio in Downtown',
      address: 'Al Maadi, Cairo, Egypt',
      description:
          'A beautifully furnished modern studio apartment located in the heart of downtown. Features high ceilings, natural lighting, and premium finishes throughout.',
      pricePerMonth: 3500,
      rooms: 1,
      bathrooms: 1,
      areaSqm: 45,
      type: 'studio',
      amenities: ['WiFi', 'AC', 'Parking', 'Gym'],
      ownerName: 'Ahmed Hassan',
      status: 'available',
    ),
    const Apartment(
      id: '2',
      title: 'Spacious 2BR Apartment',
      address: 'Zamalek, Cairo, Egypt',
      description:
          'Spacious two-bedroom apartment with a large living area, modern kitchen, and balcony with Nile views. Located in a quiet residential area.',
      pricePerMonth: 7000,
      rooms: 2,
      bathrooms: 1,
      areaSqm: 95,
      type: 'apartment',
      amenities: ['WiFi', 'AC', 'Parking', 'Pool', 'Security'],
      ownerName: 'Sara Mohamed',
      status: 'available',
    ),
    const Apartment(
      id: '3',
      title: 'Cozy Room in Shared Villa',
      address: 'New Cairo, Egypt',
      description:
          'A cozy private room in a shared villa with access to common areas including kitchen, living room, and garden. Great for students and young professionals.',
      pricePerMonth: 2000,
      rooms: 1,
      bathrooms: 1,
      areaSqm: 25,
      type: 'villa',
      amenities: ['WiFi', 'Garden', 'Laundry', 'Kitchen'],
      ownerName: 'Omar Ali',
      status: 'available',
    ),
    const Apartment(
      id: '4',
      title: 'Luxury 3BR Duplex',
      address: 'Sheikh Zayed, Giza, Egypt',
      description:
          'Premium duplex apartment with three bedrooms, two living areas, a fully equipped kitchen, and a private terrace. Located in a gated community.',
      pricePerMonth: 12000,
      rooms: 3,
      bathrooms: 2,
      areaSqm: 180,
      type: 'duplex',
      amenities: ['WiFi', 'AC', 'Parking', 'Pool', 'Gym', 'Security', 'Garden'],
      ownerName: 'Fatima Khaled',
      status: 'rented',
    ),
  ];
}

