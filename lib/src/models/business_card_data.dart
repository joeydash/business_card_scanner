class BusinessCardData {
  // Personal Information
  final String? personName;
  final String? jobTitle;
  final String? pronouns;
  
  // Contact Information
  final List<String> emails;
  final List<String> phones;
  final List<String> websites;
  final String? linkedIn;
  final String? twitter;
  
  // Company Information
  final String? companyName;
  final String? department;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  
  // Additional
  final String? fax;
  final String? tagline;
  
  // Original OCR text
  final String rawText;
  
  // Confidence scores (optional)
  final Map<String, double>? confidenceScores;

  BusinessCardData({
    this.personName,
    this.jobTitle,
    this.pronouns,
    this.emails = const [],
    this.phones = const [],
    this.websites = const [],
    this.linkedIn,
    this.twitter,
    this.companyName,
    this.department,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.fax,
    this.tagline,
    required this.rawText,
    this.confidenceScores,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'personName': personName,
    'jobTitle': jobTitle,
    'pronouns': pronouns,
    'emails': emails,
    'phones': phones,
    'websites': websites,
    'linkedIn': linkedIn,
    'twitter': twitter,
    'companyName': companyName,
    'department': department,
    'address': address,
    'city': city,
    'state': state,
    'postalCode': postalCode,
    'country': country,
    'fax': fax,
    'tagline': tagline,
    'rawText': rawText,
    'confidenceScores': confidenceScores,
  };

  // Create from JSON
  factory BusinessCardData.fromJson(Map<String, dynamic> json) {
    return BusinessCardData(
      personName: json['personName'],
      jobTitle: json['jobTitle'],
      pronouns: json['pronouns'],
      emails: List<String>.from(json['emails'] ?? []),
      phones: List<String>.from(json['phones'] ?? []),
      websites: List<String>.from(json['websites'] ?? []),
      linkedIn: json['linkedIn'],
      twitter: json['twitter'],
      companyName: json['companyName'],
      department: json['department'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      fax: json['fax'],
      tagline: json['tagline'],
      rawText: json['rawText'] ?? '',
      confidenceScores: json['confidenceScores'] != null
          ? Map<String, double>.from(json['confidenceScores'])
          : null,
    );
  }

  // Copy with method
  BusinessCardData copyWith({
    String? personName,
    String? jobTitle,
    String? pronouns,
    List<String>? emails,
    List<String>? phones,
    List<String>? websites,
    String? linkedIn,
    String? twitter,
    String? companyName,
    String? department,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? fax,
    String? tagline,
    String? rawText,
    Map<String, double>? confidenceScores,
  }) {
    return BusinessCardData(
      personName: personName ?? this.personName,
      jobTitle: jobTitle ?? this.jobTitle,
      pronouns: pronouns ?? this.pronouns,
      emails: emails ?? this.emails,
      phones: phones ?? this.phones,
      websites: websites ?? this.websites,
      linkedIn: linkedIn ?? this.linkedIn,
      twitter: twitter ?? this.twitter,
      companyName: companyName ?? this.companyName,
      department: department ?? this.department,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      fax: fax ?? this.fax,
      tagline: tagline ?? this.tagline,
      rawText: rawText ?? this.rawText,
      confidenceScores: confidenceScores ?? this.confidenceScores,
    );
  }
}
