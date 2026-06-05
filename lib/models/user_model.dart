class RoleModel {
  final int roleId;
  final String roleName;

  RoleModel({required this.roleId, required this.roleName});

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        roleId: json['role_id'],
        roleName: json['role_name'],
      );
}

class UserModel {
  final String userId;
  final int roleId;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? avatar;
  final RoleModel? role;

  UserModel({
    required this.userId,
    required this.roleId,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatar,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['user_id'],
        roleId: json['role_id'],
        name: json['name'],
        email: json['email'],
        phoneNumber: json['phone_number'],
        avatar: json['avatar'],
        role: json['role'] != null ? RoleModel.fromJson(json['role']) : null,
      );

  bool get isAdmin => roleId == 1;
  bool get isKasir => roleId == 2;
}
