class CertificateDto {
  final String id;
  final String courseId;
  final String courseTitle;
  final String title;
  final String? certificateUrl;
  final DateTime issuedAt;

  CertificateDto({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    this.certificateUrl,
    required this.issuedAt,
  });

  factory CertificateDto.fromJson(Map<String, dynamic> json) {
    return CertificateDto(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      courseTitle: json['courseTitle'] as String,
      title: json['title'] as String,
      certificateUrl: json['certificateUrl'] as String?,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
    );
  }
}
