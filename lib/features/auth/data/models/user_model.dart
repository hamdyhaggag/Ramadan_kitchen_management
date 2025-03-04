class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final String role;
  String? fcmToken;

  UserModel({
    required this.uid,
    this.fcmToken,
    required this.email,
    required this.name,
    required this.phoneNumber,
    this.role = 'user',
  });
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        fcmToken: json['fcmToken'] as String?,
        uid: json['uid'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String? ?? '',
        role: json['role'] as String? ?? 'user',
      );

  toMap() => {
        'fcmToken': fcmToken,
        'uid': uid,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'role': role,
      };
}
