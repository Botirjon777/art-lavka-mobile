import 'package:meta/meta.dart';

import '../utils/json.dart';

/// Platform-wide role. Drives RLS and which app/features a user can reach.
enum UserRole { customer, designer, operations, moderator, admin }

/// A registered account. Identity is the phone number (SPEC §8); email optional.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.languageCode = 'ru',
  });

  final String id;
  final String phone;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String languageCode;
  final UserRole role;
  final DateTime createdAt;

  /// `true` once the first-login profile completion step is satisfied.
  bool get hasCompletedProfile => (fullName ?? '').trim().isNotEmpty;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    phone: json['phone'] as String? ?? '',
    email: Json.stringOrNull(json['email']),
    fullName: Json.stringOrNull(json['full_name']),
    avatarUrl: Json.stringOrNull(json['avatar_url']),
    languageCode: json['language_code'] as String? ?? 'ru',
    role: Json.enumByName(UserRole.values, json['role'], UserRole.customer),
    createdAt: Json.date(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'language_code': languageCode,
    'role': role.name,
    'created_at': createdAt.toIso8601String(),
  };

  AppUser copyWith({
    String? email,
    String? fullName,
    String? avatarUrl,
    String? languageCode,
    UserRole? role,
  }) => AppUser(
    id: id,
    phone: phone,
    createdAt: createdAt,
    email: email ?? this.email,
    fullName: fullName ?? this.fullName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    languageCode: languageCode ?? this.languageCode,
    role: role ?? this.role,
  );
}
