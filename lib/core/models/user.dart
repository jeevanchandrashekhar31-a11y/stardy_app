class User {
  final String id;
  final String name;
  final String? username;
  final String email;
  final String? profilePictureUrl;

  const User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.profilePictureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String) {
      throw const FormatException('id missing or wrong type');
    }
    if (json['name'] is! String) {
      throw const FormatException('name missing or wrong type');
    }
    if (json['email'] is! String) {
      throw const FormatException('email missing or wrong type');
    }

    String? uName;
    if (json.containsKey('username') && json['username'] != null) {
      if (json['username'] is! String) {
        throw const FormatException('username must be a string');
      }
      uName = json['username'] as String;
    }

    String? pUrl;
    if (json.containsKey('profilePictureUrl') &&
        json['profilePictureUrl'] != null) {
      if (json['profilePictureUrl'] is! String) {
        throw const FormatException('profilePictureUrl must be a string');
      }
      pUrl = json['profilePictureUrl'] as String;
    }

    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      username: uName,
      email: json['email'] as String,
      profilePictureUrl: pUrl,
    );
  }
}
