class CveItem {
  final String cveId;
  final String description;
  final double? cvssScore;
  final String severity;
  final String publishedDate;
  final String lastModifiedDate;
  final List<String> cwes;

  // CVSS v3 details
  final String? attackVector;
  final String? attackComplexity;
  final String? privilegesRequired;
  final String? userInteraction;
  final String? scope;
  final String? confidentiality;
  final String? integrity;
  final String? availability;

  const CveItem({
    required this.cveId,
    required this.description,
    this.cvssScore,
    required this.severity,
    required this.publishedDate,
    required this.lastModifiedDate,
    this.cwes = const [],
    this.attackVector,
    this.attackComplexity,
    this.privilegesRequired,
    this.userInteraction,
    this.scope,
    this.confidentiality,
    this.integrity,
    this.availability,
  });

  factory CveItem.fromJson(Map<String, dynamic> json) {
    final cve = json['cve'] as Map<String, dynamic>? ?? json;
    final id = cve['id'] as String? ?? '';

    // Description
    final descriptions = cve['descriptions'] as List? ?? [];
    final enDesc = descriptions.firstWhere(
      (d) => d['lang'] == 'en',
      orElse: () => descriptions.isNotEmpty ? descriptions[0] : {'value': ''},
    );
    final description = enDesc['value'] as String? ?? 'No description available.';

    // CVSS scores
    final metrics = cve['metrics'] as Map<String, dynamic>? ?? {};
    final cvssV31 = (metrics['cvssMetricV31'] as List?)?.firstOrNull;
    final cvssV3 = cvssV31 ?? (metrics['cvssMetricV30'] as List?)?.firstOrNull;
    final cvssData = cvssV3?['cvssData'] as Map<String, dynamic>? ?? {};
    final baseScore = (cvssData['baseScore'] as num?)?.toDouble();
    final baseSeverity = cvssV3?['cvssData']?['baseSeverity'] as String? ??
        _severityFromScore(baseScore);

    // CWEs
    final weaknesses = cve['weaknesses'] as List? ?? [];
    final cwes = <String>[];
    for (final w in weaknesses) {
      final descs = w['description'] as List? ?? [];
      for (final d in descs) {
        final val = d['value'] as String? ?? '';
        if (val.startsWith('CWE-')) cwes.add(val);
      }
    }

    // Dates
    String formatDate(String? raw) {
      if (raw == null) return '-';
      try {
        final dt = DateTime.parse(raw);
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        return raw.length > 10 ? raw.substring(0, 10) : raw;
      }
    }

    return CveItem(
      cveId: id,
      description: description,
      cvssScore: baseScore,
      severity: baseSeverity,
      publishedDate: formatDate(cve['published'] as String?),
      lastModifiedDate: formatDate(cve['lastModified'] as String?),
      cwes: cwes.toSet().toList(),
      attackVector: cvssData['attackVector'] as String?,
      attackComplexity: cvssData['attackComplexity'] as String?,
      privilegesRequired: cvssData['privilegesRequired'] as String?,
      userInteraction: cvssData['userInteraction'] as String?,
      scope: cvssData['scope'] as String?,
      confidentiality: cvssData['confidentialityImpact'] as String?,
      integrity: cvssData['integrityImpact'] as String?,
      availability: cvssData['availabilityImpact'] as String?,
    );
  }

  static String _severityFromScore(double? score) {
    if (score == null) return 'UNKNOWN';
    if (score >= 9.0) return 'CRITICAL';
    if (score >= 7.0) return 'HIGH';
    if (score >= 4.0) return 'MEDIUM';
    return 'LOW';
  }
}
