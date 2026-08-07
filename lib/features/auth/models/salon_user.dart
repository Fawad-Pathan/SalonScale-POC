import '../../../core/utils/json_helpers.dart';

class SalonUser {
  const SalonUser({
    required this.id,
    required this.salonId,
    required this.displayName,
    required this.isAnonymous,
  });

  final String id;
  final String salonId;
  final String displayName;
  final bool isAnonymous;

  factory SalonUser.fromJson(Map<String, dynamic> json) {
    return SalonUser(
      id: readString(json, 'id'),
      salonId: readString(json, 'salonId', fallback: 'demo_salon'),
      displayName: readString(json, 'displayName', fallback: 'Demo Stylist'),
      isAnonymous: readBool(json, 'isAnonymous', fallback: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salonId': salonId,
      'displayName': displayName,
      'isAnonymous': isAnonymous,
    };
  }

  SalonUser copyWith({
    String? id,
    String? salonId,
    String? displayName,
    bool? isAnonymous,
  }) {
    return SalonUser(
      id: id ?? this.id,
      salonId: salonId ?? this.salonId,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SalonUser &&
            other.id == id &&
            other.salonId == salonId &&
            other.displayName == displayName &&
            other.isAnonymous == isAnonymous;
  }

  @override
  int get hashCode => Object.hash(id, salonId, displayName, isAnonymous);
}
