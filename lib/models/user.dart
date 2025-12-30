class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? avatarUrl;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Role> roles;
  final List<Permission> permissions;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.avatarUrl,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
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
          ? DateTime.parse(json['email_verified_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
