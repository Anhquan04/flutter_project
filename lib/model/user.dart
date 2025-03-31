class User {
  final String username;
  final String phone;
  final String email;
  final String password;
  final DateTime dob;
  final String role;

  User({
    required this.username,
    required this.phone,
    required this.email,
    required this.password,
    required this.dob,
    this.role = 'user',
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'phone': phone,
      'email': email,
      'password': password,
      'dob': dob.toIso8601String(),
      'role': role,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      phone: json['phone'],
      email: json['email'],
      password: json['password'],
      dob: DateTime.parse(json['dob']),
      role: json['role'] ?? 'user',
    );
  }
}
