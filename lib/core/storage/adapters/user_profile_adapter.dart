import 'package:hive/hive.dart';

part 'user_profile_adapter.g.dart';

@HiveType(typeId: 2)
class HiveUserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String role;

  @HiveField(3)
  final String? fullName;

  @HiveField(4)
  final String? avatarUrl;

  @HiveField(5)
  final String? phone;

  @HiveField(6)
  final String? address;

  @HiveField(7)
  final String? shopDescription;

  @HiveField(8)
  final bool verifiedSeller;

  @HiveField(9)
  final DateTime? createdAt;

  HiveUserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.address,
    this.shopDescription,
    this.verifiedSeller = false,
    this.createdAt,
  });

  factory HiveUserProfile.fromJson(Map<String, dynamic> json) {
    return HiveUserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'buyer',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      shopDescription: json['shop_description'] as String?,
      verifiedSeller: json['verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'address': address,
      'shop_description': shopDescription,
      'verified': verifiedSeller,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
