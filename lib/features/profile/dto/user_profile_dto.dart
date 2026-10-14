class CareerPathProgressDto {
  final String id;
  final String title;
  final int progress;

  const CareerPathProgressDto({
    required this.id,
    required this.title,
    required this.progress,
  });

  factory CareerPathProgressDto.fromJson(Map<String, dynamic> json) {
    return CareerPathProgressDto(
      id: json['id'] as String,
      title: json['title'] as String,
      progress: json['progress'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'progress': progress,
    };
  }
}

class UserProfileDto {
  final String id;
  final String name;
  final String? username;
  final String email;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final List<CareerPathProgressDto> careerPaths;

  const UserProfileDto({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.profilePictureUrl,
    required this.createdAt,
    required this.careerPaths,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String?,
      email: json['email'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      careerPaths: (json['careerPaths'] as List<dynamic>?)
              ?.map((e) => CareerPathProgressDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (username != null) 'username': username,
      'email': email,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt.toIso8601String(),
      'careerPaths': careerPaths.map((e) => e.toJson()).toList(),
    };
  }
}
