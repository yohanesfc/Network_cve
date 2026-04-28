import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cve_model.dart';
import '../main.dart';

class CveDetailScreen extends StatelessWidget {
  final CveItem cve;
  const CveDetailScreen({super.key, required this.cve});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreColor = _scoreColor(cve.cvssScore);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFFAF8F6),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scoreColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                cve.cvssScore?.toStringAsFixed(1) ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceMono',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              cve.cveId,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy CVE ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: cve.cveId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${cve.cveId} copied')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(
              '${cve.cveId}\nScore: ${cve.cvssScore}\n\n${cve.description}\n\nhttps://nvd.nist.gov/vuln/detail/${cve.cveId}',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Text(
                cve.description,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  height: 1.6,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CWE Section
            if (cve.cwes.isNotEmpty) ...[
              _sectionTitle('Common Weakness Enumeration Data', AppTheme.accent),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: cve.cwes
                    .map((cwe) => _CweChip(cwe: cwe, isDark: isDark))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // CVSS v3 Data
            _sectionTitle('CVSS v3 Data', AppTheme.accent),
            const SizedBox(height: 8),
            _buildCvssGrid(isDark),
            const SizedBox(height: 16),

            // Published / Modified
            _sectionTitle('Dates', AppTheme.primary),
            const SizedBox(height: 8),
            _InfoRow('Published', cve.publishedDate, isDark),
            const SizedBox(height: 4),
            _InfoRow('Last Modified', cve.lastModifiedDate, isDark),
            const SizedBox(height: 16),

            // NVD Link
            _sectionTitle('References', AppTheme.primary),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _launchNvd(cve.cveId),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(
                'View on NVD',
                style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: BorderSide(color: AppTheme.accent),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCvssGrid(bool isDark) {
    final items = [
      _CvssItem('Attack Vector', cve.attackVector ?? '-', Icons.hub),
      _CvssItem('Attack Complexity', cve.attackComplexity ?? '-', Icons.psychology),
      _CvssItem('Privileges Required', cve.privilegesRequired ?? '-', Icons.badge),
      _CvssItem('User Interaction', cve.userInteraction ?? '-', Icons.person),
      _CvssItem('Scope', cve.scope ?? '-', Icons.radar),
      _CvssItem('Confidentiality', cve.confidentiality ?? '-', Icons.visibility_off),
      _CvssItem('Integrity', cve.integrity ?? '-', Icons.verified_user),
      _CvssItem('Availability', cve.availability ?? '-', Icons.access_time),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                item.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceMono',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontFamily: 'SpaceMono',
                  fontSize: 8,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _InfoRow(String label, String value, bool isDark) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _launchNvd(String cveId) async {
    final url = Uri.parse('https://nvd.nist.gov/vuln/detail/$cveId');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Color _scoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 9.0) return const Color(0xFF8B0000);
    if (score >= 7.0) return const Color(0xFFD44000);
    if (score >= 4.0) return const Color(0xFFE69500);
    return const Color(0xFF2E7D32);
  }
}

class _CvssItem {
  final String label, value;
  final IconData icon;
  const _CvssItem(this.label, this.value, this.icon);
}

class _CweChip extends StatelessWidget {
  final String cwe;
  final bool isDark;
  const _CweChip({required this.cwe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bug_report, color: Colors.grey[400], size: 18),
          const SizedBox(width: 6),
          Text(
            cwe,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              color: Colors.grey[300],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
