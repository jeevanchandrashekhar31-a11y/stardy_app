class OpportunitySummary {
  final String id;
  final String title;
  final String company;
  final String? location;
  final String type; // INTERNSHIP, FREELANCE
  final String category; // CREATIVE, BUSINESS, TECH
  final bool isPaid;
  final String? logoUrl;
  final bool hasApplied;

  const OpportunitySummary({
    required this.id,
    required this.title,
    required this.company,
    this.location,
    required this.type,
    required this.category,
    required this.isPaid,
    this.logoUrl,
    required this.hasApplied,
  });

  factory OpportunitySummary.fromJson(Map<String, dynamic> json) {
    return OpportunitySummary(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      location: json['location'] as String?,
      type: json['type'] as String,
      category: json['category'] as String,
      isPaid: json['isPaid'] as bool? ?? false,
      logoUrl: json['logoUrl'] as String?,
      hasApplied: json['hasApplied'] as bool? ?? false,
    );
  }

  OpportunitySummary copyWith({
    bool? hasApplied,
  }) {
    return OpportunitySummary(
      id: id,
      title: title,
      company: company,
      location: location,
      type: type,
      category: category,
      isPaid: isPaid,
      logoUrl: logoUrl,
      hasApplied: hasApplied ?? this.hasApplied,
    );
  }
}

class OpportunityDetail {
  final OpportunitySummary summary;
  final String description;
  final String? applyUrl;

  const OpportunityDetail({
    required this.summary,
    required this.description,
    this.applyUrl,
  });

  factory OpportunityDetail.fromJson(Map<String, dynamic> json) {
    return OpportunityDetail(
      summary: OpportunitySummary.fromJson(json),
      description: json['description'] as String? ?? '',
      applyUrl: json['applyUrl'] as String?,
    );
  }
}

class OpportunityApplyResponse {
  final String status;
  final String appliedAt;

  const OpportunityApplyResponse({
    required this.status,
    required this.appliedAt,
  });

  factory OpportunityApplyResponse.fromJson(Map<String, dynamic> json) {
    return OpportunityApplyResponse(
      status: json['status'] as String,
      appliedAt: json['appliedAt'] as String,
    );
  }
}
