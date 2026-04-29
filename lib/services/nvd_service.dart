import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cve_model.dart';

class NvdService {
  static const String _baseUrl = 'https://services.nvd.nist.gov/rest/json/cves/2.0';
  
  // Optional: set your NVD API key here for higher rate limits
  // Get free key at: https://nvd.nist.gov/developers/request-an-api-key
  static const String? _apiKey = null; // '6d603b60-33dd-4ff0-8b1c-4a53444b0167';

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_apiKey != null) h['apiKey'] = _apiKey!;
    return h;
  }

  /// Search CVEs by keyword or CVE-ID
  Future<List<CveItem>> searchCves(String query) async {
    final String param;
    
    // Detect jika input adalah CVE-ID langsung
    if (RegExp(r'^CVE-\d{4}-\d+$', caseSensitive: false).hasMatch(query)) {
      param = 'cveId=${Uri.encodeComponent(query.toUpperCase())}';
    } else {
      param = 'keywordSearch=${Uri.encodeComponent(query)}&keywordExactMatch';
    }

    final uri = Uri.parse('$_baseUrl?$param&resultsPerPage=20');
    
    try {
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final vulns = data['vulnerabilities'] as List? ?? [];
        return vulns.map((v) => CveItem.fromJson(v as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('API rate limit tercapai. Coba lagi dalam beberapa detik.');
      } else {
        throw Exception('NVD API error: ${response.statusCode}');
      }
    } on Exception {
      rethrow;
    }
  }

  /// Get recent CVEs (news feed)
  Future<List<CveItem>> getRecentCves() async {
    // Ambil CVEs dari 7 hari terakhir dengan score tinggi
    final now = DateTime.now().toUtc();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final pubStartDate = _formatDateTime(weekAgo);
    final pubEndDate = _formatDateTime(now);

    final uri = Uri.parse(
      '$_baseUrl?pubStartDate=$pubStartDate&pubEndDate=$pubEndDate'
      '&cvssV3SeverityFilter=HIGH,CRITICAL&resultsPerPage=20',
    );

    try {
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final vulns = data['vulnerabilities'] as List? ?? [];
        final items = vulns
            .map((v) => CveItem.fromJson(v as Map<String, dynamic>))
            .toList();
        // Sort by score descending
        items.sort((a, b) => (b.cvssScore ?? 0).compareTo(a.cvssScore ?? 0));
        return items;
      } else {
        // Fallback: ambil CVEs terbaru tanpa filter date
        return _getFallbackFeed();
      }
    } catch (_) {
      return _getFallbackFeed();
    }
  }

  Future<List<CveItem>> _getFallbackFeed() async {
    final uri = Uri.parse(
      '$_baseUrl?cvssV3SeverityFilter=CRITICAL&resultsPerPage=15',
    );
    final response = await http.get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final vulns = data['vulnerabilities'] as List? ?? [];
      return vulns.map((v) => CveItem.fromJson(v as Map<String, dynamic>)).toList();
    }
    return [];
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}:00:00.000';
  }
}
