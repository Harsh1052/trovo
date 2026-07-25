import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum HuntDifficulty { easy, medium, hard }

class HuntModel extends Equatable {
  const HuntModel({
    required this.huntId,
    required this.title,
    required this.description,
    required this.city,
    required this.gardenName,
    required this.difficulty,
    required this.durationMinutes,
    required this.checkpointCount,
    required this.isFree,
    required this.price,
    required this.coverImageUrl,
    required this.startLatitude,
    required this.startLongitude,
    required this.isActive,
    required this.createdAt,
  });

  final String huntId;
  final String title;
  final String description;
  final String city;

  /// The named garden / location where the hunt takes place.
  final String gardenName;

  final HuntDifficulty difficulty;
  final int durationMinutes;
  final int checkpointCount;

  /// True = players can play without purchasing.
  final bool isFree;

  /// Price in the smallest currency unit (e.g. cents). 0 for free hunts.
  final int price;

  /// Cover image URL. Empty string when no image is configured.
  final String coverImageUrl;

  final double startLatitude;
  final double startLongitude;

  /// False = hunt is hidden / disabled in the app.
  final bool isActive;

  final DateTime createdAt;

  // ── Computed / display helpers ────────────────────────────────────────────

  /// Human-readable duration: "45 min" or "1 h 30 min".
  String get formattedDuration {
    if (durationMinutes < 60) return '$durationMinutes min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  /// Human-readable price: "Free" or "\$4.99" (price stored in cents).
  String get formattedPrice {
    if (isFree || price == 0) return 'Free';
    final dollars = price / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// Capitalised difficulty label for display (e.g. "Easy", "Medium", "Hard").
  String get difficultyLabel =>
      '${difficulty.name[0].toUpperCase()}${difficulty.name.substring(1)}';

  /// Convenience: whether this hunt has a valid cover image.
  bool get hasCoverImage => coverImageUrl.isNotEmpty;

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory HuntModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HuntModel.fromJson({'huntId': doc.id, ...data});
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }..remove('huntId');
  }

  // ── JSON ──────────────────────────────────────────────────────────────────

  factory HuntModel.fromJson(Map<String, dynamic> json) {
    return HuntModel(
      huntId: json['huntId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      city: json['city'] as String? ?? '',
      gardenName: json['gardenName'] as String? ?? '',
      difficulty: HuntDifficulty.values.firstWhere(
        (d) => d.name == (json['difficulty'] as String? ?? ''),
        orElse: () => HuntDifficulty.medium,
      ),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      checkpointCount: json['checkpointCount'] as int? ?? 0,
      isFree: json['isFree'] as bool? ?? true,
      price: json['price'] as int? ?? 0,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      startLatitude: (json['startLatitude'] as num?)?.toDouble() ?? 0.0,
      startLongitude: (json['startLongitude'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'huntId': huntId,
        'title': title,
        'description': description,
        'city': city,
        'gardenName': gardenName,
        'difficulty': difficulty.name,
        'durationMinutes': durationMinutes,
        'checkpointCount': checkpointCount,
        'isFree': isFree,
        'price': price,
        'coverImageUrl': coverImageUrl,
        'startLatitude': startLatitude,
        'startLongitude': startLongitude,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  HuntModel copyWith({
    String? title,
    String? description,
    String? city,
    String? gardenName,
    HuntDifficulty? difficulty,
    int? durationMinutes,
    int? checkpointCount,
    bool? isFree,
    int? price,
    String? coverImageUrl,
    double? startLatitude,
    double? startLongitude,
    bool? isActive,
  }) =>
      HuntModel(
        huntId: huntId,
        title: title ?? this.title,
        description: description ?? this.description,
        city: city ?? this.city,
        gardenName: gardenName ?? this.gardenName,
        difficulty: difficulty ?? this.difficulty,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        checkpointCount: checkpointCount ?? this.checkpointCount,
        isFree: isFree ?? this.isFree,
        price: price ?? this.price,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        startLatitude: startLatitude ?? this.startLatitude,
        startLongitude: startLongitude ?? this.startLongitude,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  // ── Equatable ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        huntId,
        title,
        description,
        city,
        gardenName,
        difficulty,
        durationMinutes,
        checkpointCount,
        isFree,
        price,
        coverImageUrl,
        startLatitude,
        startLongitude,
        isActive,
        createdAt,
      ];
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
