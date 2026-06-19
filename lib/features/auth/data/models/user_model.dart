import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.fullName,
    super.avatarUrl,
    super.phone,
    super.address,
    super.shopDescription,
    super.verifiedSeller,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'phone': phone,
        'address': address,
        'shop_description': shopDescription,
        'verified': verifiedSeller,
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        role: role,
        fullName: fullName,
        avatarUrl: avatarUrl,
        phone: phone,
        address: address,
        shopDescription: shopDescription,
        verifiedSeller: verifiedSeller,
        createdAt: createdAt,
      );
}
