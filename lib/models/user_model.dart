class UserModel {
  final String id;
  final String username;
  final String email;
  final String? imageUrl;
  final String? password;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.imageUrl,
    this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'imageUrl': imageUrl,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      imageUrl: map['imageUrl'],
      password: map['password'],
    );
  }
}
