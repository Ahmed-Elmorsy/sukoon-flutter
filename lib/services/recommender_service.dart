import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'app_logger.dart';

class RecommendedApartment {
  final int apartmentId;
  final double score;
  final double priceScore;
  final double locationScore;
  final double furnishedScore;
  final double affinityScore;

  const RecommendedApartment({
    required this.apartmentId,
    required this.score,
    this.priceScore = 0,
    this.locationScore = 0,
    this.furnishedScore = 0,
    this.affinityScore = 0,
  });

  factory RecommendedApartment.fromJson(Map<String, dynamic> json) {
    return RecommendedApartment(
      apartmentId: json['apartment_id'] ?? json['id'] ?? 0,
      score: (json['final_score'] ?? json['score'] ?? 0).toDouble(),
      priceScore: (json['price_score'] ?? 0).toDouble(),
      locationScore: (json['location_score'] ?? 0).toDouble(),
      furnishedScore: (json['furnished_score'] ?? 0).toDouble(),
      affinityScore: (json['affinity_score'] ?? 0).toDouble(),
    );
  }
}

class RecommenderResult {
  final List<RecommendedApartment> recommendations;
  final int totalApartments;
  final int totalRanked;
  final int totalExcluded;

  const RecommenderResult({
    required this.recommendations,
    this.totalApartments = 0,
    this.totalRanked = 0,
    this.totalExcluded = 0,
  });

  factory RecommenderResult.fromJson(Map<String, dynamic> json) {
    final recs = (json['recommendations'] as List<dynamic>? ?? [])
        .map((e) => RecommendedApartment.fromJson(e as Map<String, dynamic>))
        .toList();
    return RecommenderResult(
      recommendations: recs,
      totalApartments: json['total_apartments'] ?? 0,
      totalRanked: json['total_ranked'] ?? 0,
      totalExcluded: json['total_excluded'] ?? 0,
    );
  }

  /// Returns a map of apartment_id → rank index (0 = best).
  Map<int, int> get rankMap {
    final map = <int, int>{};
    for (var i = 0; i < recommendations.length; i++) {
      map[recommendations[i].apartmentId] = i;
    }
    return map;
  }
}

class RecommenderService {
  static String get _base => '${AppConfig.apiBaseUrl}/api/recommender';

  /// Call the ranking model with the user's current filter criteria.
  static Future<RecommenderResult?> recommend({
    required double budgetMin,
    required double budgetMax,
    required String preferredLocation,
    int? prefersFurnished,
    String userAffinityGroup = 'UNKNOWN',
    int n = 20,
  }) async {
    final url = '$_base/recommend';
    final body = {
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'preferred_location': preferredLocation,
      'prefers_furnished': prefersFurnished,
      'user_affinity_group': userAffinityGroup,
      'n': n,
    };

    try {
      AppLogger.instance.info('RECOMMENDER', 'POST $url');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        AppLogger.instance.info(
            'RECOMMENDER', 'Got ${json['total_ranked']} ranked apartments');
        return RecommenderResult.fromJson(json);
      }
      AppLogger.instance.error(
          'RECOMMENDER', 'Error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      AppLogger.instance.error('RECOMMENDER', 'Exception: $e');
      return null;
    }
  }
}
