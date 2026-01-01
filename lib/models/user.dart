import '../utils/timezone_utils.dart';

class User {
  final int id;
  final String name;
  final String? email; // Nullable untuk partial data (partner)
  final String? phone;
  final String? avatar;
  final String? avatarUrl;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt; // Nullable untuk partial data
  final DateTime? updatedAt; // Nullable untuk partial data
  final List<Role> roles;
  final List<Permission> permissions;

  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.avatarUrl,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.roles = const [],
    this.permissions = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      avatarUrl: json['avatar_url'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['email_verified_at'])
          : null,
      createdAt: json['created_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['updated_at'])
          : null,
      roles: json['roles'] != null
          ? (json['roles'] as List).map((r) => Role.fromJson(r)).toList()
          : [],
      permissions: json['permissions'] != null
          ? (json['permissions'] as List).map((p) => Permission.fromJson(p)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'avatar_url': avatarUrl,
  };

  bool hasRole(String roleName) {
    return roles.any((role) => role.name == roleName);
  }

  bool hasPermission(String permissionName) {
    return permissions.any((perm) => perm.name == permissionName);
  }

  bool get isAdmin => hasRole('admin');
  bool get isPartner => hasRole('partner');
  bool get isUser => hasRole('user');
}

class Role {
  final int? id;
  final String name;
  final String? guardName;

  Role({this.id, required this.name, this.guardName});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      guardName: json['guard_name'],
    );
  }
}

class Permission {
  final int? id;
  final String name;
  final String? guardName;

  Permission({this.id, required this.name, this.guardName});

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'],
      name: json['name'],
      guardName: json['guard_name'],
    );
  }
}
