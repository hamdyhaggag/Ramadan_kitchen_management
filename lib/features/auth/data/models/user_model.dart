class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    this.role = 'user',
  });
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'],
        role: json['role'] as String? ?? 'user',
      );

  toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'role': role,
      };
}
