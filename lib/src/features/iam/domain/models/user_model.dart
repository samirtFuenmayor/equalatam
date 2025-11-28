class UserModel {
  final String id;
  final String name;
  final String email;
  final String roleId;
  final bool active;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
    this.active = true,
  });
}
