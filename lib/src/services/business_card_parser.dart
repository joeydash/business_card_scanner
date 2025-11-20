import '../models/business_card_data.dart';

class BusinessCardParser {
  // Regex patterns for entity extraction
  static final RegExp _emailPattern = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
  );

  static final RegExp _phonePattern = RegExp(
    r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
  );

  static final RegExp _websitePattern = RegExp(
    r'(https?://)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
  );

  static final RegExp _linkedInPattern = RegExp(
    r'linkedin\.com/in/[\w-]+',
    caseSensitive: false,
  );

  static final RegExp _twitterPattern = RegExp(
    r'@[\w]+|twitter\.com/[\w]+',
    caseSensitive: false,
  );

  // Common job title keywords
  static final List<String> _titleKeywords = [
    'ceo', 'cto', 'cfo', 'coo', 'president', 'vice president', 'vp',
    'director', 'manager', 'head', 'lead', 'senior', 'junior',
    'engineer', 'developer', 'designer', 'analyst', 'consultant',
    'specialist', 'coordinator', 'associate', 'executive', 'officer',
    'founder', 'co-founder', 'partner', 'owner', 'chief',
  ];

  // Company entity keywords
  static final List<String> _companyKeywords = [
    'inc', 'inc.', 'llc', 'ltd', 'ltd.', 'corp', 'corp.', 'corporation',
    'company', 'co.', 'group', 'enterprises', 'solutions', 'technologies',
    'tech', 'systems', 'services', 'consulting', 'partners',
  ];

  /// Parse business card text into structured data
  /// TODO: Replace with BERT NER model for better accuracy
  static BusinessCardData parse(String rawText) {
    final lines = rawText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    // Extract emails
    final emails = _extractEmails(rawText);
    
    // Extract phones
    final phones = _extractPhones(rawText);
    
    // Extract websites
    final websites = _extractWebsites(rawText);
    
    // Extract social media
    final linkedIn = _extractLinkedIn(rawText);
    final twitter = _extractTwitter(rawText);
    
    // Parse name, title, company using heuristics
    String? personName;
    String? jobTitle;
    String? companyName;
    
    if (lines.isNotEmpty) {
      // First non-empty line is usually the name
      personName = _extractName(lines);
      
      // Look for job title
      jobTitle = _extractJobTitle(lines);
      
      // Look for company name
      companyName = _extractCompanyName(lines);
    }

    return BusinessCardData(
      personName: personName,
      jobTitle: jobTitle,
      emails: emails,
      phones: phones,
      websites: websites,
      linkedIn: linkedIn,
      twitter: twitter,
      companyName: companyName,
      rawText: rawText,
    );
  }

  static List<String> _extractEmails(String text) {
    return _emailPattern.allMatches(text).map((m) => m.group(0)!).toList();
  }

  static List<String> _extractPhones(String text) {
    return _phonePattern.allMatches(text).map((m) => m.group(0)!.trim()).toList();
  }

  static List<String> _extractWebsites(String text) {
    return _websitePattern
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where((url) => !url.contains('linkedin.com') && !url.contains('twitter.com'))
        .toList();
  }

  static String? _extractLinkedIn(String text) {
    final match = _linkedInPattern.firstMatch(text);
    return match?.group(0);
  }

  static String? _extractTwitter(String text) {
    final match = _twitterPattern.firstMatch(text);
    return match?.group(0);
  }

  static String? _extractName(List<String> lines) {
    // First line is usually the name, unless it's a company or title
    if (lines.isEmpty) return null;
    
    final firstLine = lines[0].trim();
    
    // Skip if it looks like a company
    if (_looksLikeCompany(firstLine)) {
      return lines.length > 1 ? lines[1].trim() : null;
    }
    
    return firstLine;
  }

  static String? _extractJobTitle(List<String> lines) {
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Check if line contains title keywords
      if (_titleKeywords.any((keyword) => lowerLine.contains(keyword))) {
        return line.trim();
      }
    }
    return null;
  }

  static String? _extractCompanyName(List<String> lines) {
    for (final line in lines) {
      if (_looksLikeCompany(line)) {
        return line.trim();
      }
    }
    return null;
  }

  static bool _looksLikeCompany(String text) {
    final lowerText = text.toLowerCase();
    return _companyKeywords.any((keyword) => lowerText.contains(keyword));
  }
}
