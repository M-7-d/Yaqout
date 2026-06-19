// Domain entity — no dependency on Supabase or any package
class UserEntity {
  final String id;
  final String email;
  final String role; // buyer | seller | admin
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? address;
  final String? shopDescription;
  final bool verifiedSeller;
  final DateTime? createdAt;

  const UserEntity({
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

  bool get isBuyer  => role == 'buyer';
  bool get isSeller => role == 'seller';
  bool get isAdmin  => role == 'admin';

  UserEntity copyWith({
    String? email,
    String? role,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? address,
    String? shopDescription,
    bool? verifiedSeller,
  }) =>
      UserEntity(
        id: id,
        email: email ?? this.email,
        role: role ?? this.role,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        shopDescription: shopDescription ?? this.shopDescription,
        verifiedSeller: verifiedSeller ?? this.verifiedSeller,
        createdAt: createdAt,
      );
}
