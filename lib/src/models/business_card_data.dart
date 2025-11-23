import 'dart:convert';

class BusinessCardData {
  final int? id; // SQLite ID

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
  
  // Metadata
  final DateTime? scannedAt;
  final int? groupId;
  
  // Confidence scores (optional)
  final Map<String, double>? confidenceScores;

  BusinessCardData({
    this.id,
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
    this.scannedAt,
    this.groupId,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'jobTitle': jobTitle,
      'pronouns': pronouns,
      'emails': jsonEncode(emails),
      'phones': jsonEncode(phones),
      'websites': jsonEncode(websites),
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
      'confidenceScores': confidenceScores != null ? jsonEncode(confidenceScores) : null,
      'scannedAt': scannedAt?.toIso8601String(),
      'groupId': groupId,
    };
  }

  // Create from Map (SQLite)
  factory BusinessCardData.fromMap(Map<String, dynamic> map) {
    return BusinessCardData(
      id: map['id'],
      personName: map['personName'],
      jobTitle: map['jobTitle'],
      pronouns: map['pronouns'],
      emails: List<String>.from(jsonDecode(map['emails'] ?? '[]')),
      phones: List<String>.from(jsonDecode(map['phones'] ?? '[]')),
      websites: List<String>.from(jsonDecode(map['websites'] ?? '[]')),
      linkedIn: map['linkedIn'],
      twitter: map['twitter'],
      companyName: map['companyName'],
      department: map['department'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      postalCode: map['postalCode'],
      country: map['country'],
      fax: map['fax'],
      tagline: map['tagline'],
      rawText: map['rawText'] ?? '',
      confidenceScores: map['confidenceScores'] != null
          ? Map<String, double>.from(jsonDecode(map['confidenceScores']))
          : null,
      scannedAt: map['scannedAt'] != null 
          ? DateTime.parse(map['scannedAt']) 
          : null,
      groupId: map['groupId'],
    );
  }

  // Convert to JSON (Legacy/Export)
  Map<String, dynamic> toJson() => {
    'id': id,
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
    'scannedAt': scannedAt?.toIso8601String(),
  };

  // Create from JSON (Legacy/Export)
  factory BusinessCardData.fromJson(Map<String, dynamic> json) {
    return BusinessCardData(
      id: json['id'],
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
      scannedAt: json['scannedAt'] != null 
          ? DateTime.parse(json['scannedAt']) 
          : null,
    );
  }

  // Copy with method
  BusinessCardData copyWith({
    int? id,
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
    DateTime? scannedAt,
    int? groupId,
  }) {
    return BusinessCardData(
      id: id ?? this.id,
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
      scannedAt: scannedAt ?? this.scannedAt,
      groupId: groupId ?? this.groupId,
    );
  }
}
