// Mirrors backend/prisma/schema.prisma `model User` — the fields returned
// by POST /auth/firebase and GET /users/me.
class DittoUser {
  const DittoUser({
    required this.id,
    required this.fullName,
    required this.role,
    required this.authProvider,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  factory DittoUser.fromJson(Map<String, dynamic> json) {
    return DittoUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      authProvider: json['authProvider'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String role;
  final String authProvider;
  final String? email;
  final String? phone;
  final String? avatarUrl;
}
