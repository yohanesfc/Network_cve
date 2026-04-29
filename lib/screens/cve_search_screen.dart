import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/nvd_service.dart';
import '../models/cve_model.dart';
import '../main.dart';
import 'cve_detail_screen.dart';

class CveSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const CveSearchScreen({super.key, this.initialQuery});

  @override
  State<CveSearchScreen> createState() => _CveSearchScreenState();
}

class _CveSearchScreenState extends State<CveSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final NvdService _nvdService = NvdService();

  List<CveItem> _results = [];
  List<CveItem> _newsFeed = [];
  bool _isLoading = false;
  bool _isFeedLoading = false;
  String? _error;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNewsFeed();
    if (widget.initialQuery != null) {
      _searchCtrl.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNewsFeed() async {
    if (!mounted) return;
    setState(() => _isFeedLoading = true);
    try {
      final items = await _nvdService.getRecentCves();
      if (!mounted) return;
      setState(() {
        _newsFeed = items;
        _isFeedLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFeedLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty || !mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentQuery = query.trim();
    });
    try {
      final results = await _nvdService.searchCves(query.trim());
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFFAF8F6),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'CVE',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceMono',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Search',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.accent,
          tabs: const [
            Tab(text: 'News Feed'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                // Filter icon
                IconButton(
                  icon: Icon(Icons.tune, color: Colors.grey[600]),
                  onPressed: () => _showFilterSheet(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : const Color(0xFFF0EEEC),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'try searching "Log4J2" or "CVE-2021-44228"',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontFamily: 'SpaceMono',
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: _search,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Search button
                GestureDetector(
                  onTap: () => _search(_searchCtrl.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewsFeed(),
                _buildSearchResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsFeed() {
    if (_isFeedLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.accent),
            SizedBox(height: 12),
            Text(
              'Loading latest CVEs...',
              style: TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_newsFeed.isEmpty) {
      return _buildEmptyState(isFeed: true);
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _loadNewsFeed,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _newsFeed.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _CveCard(
          item: _newsFeed[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CveDetailScreen(cve: _newsFeed[i]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.accent),
            const SizedBox(height: 12),
            Text(
              'Searching "$_currentQuery"...',
              style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _search(_currentQuery),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_currentQuery.isEmpty) {
      return _buildEmptyState(isFeed: false);
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.grey[400], size: 64),
            const SizedBox(height: 12),
            Text(
              'No CVEs found for "$_currentQuery"',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '${_results.length} result(s) for "$_currentQuery"',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _CveCard(
              item: _results[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CveDetailScreen(cve: _results[i]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required bool isFeed}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFeed ? Icons.feed : Icons.manage_search,
              color: AppTheme.accent,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFeed ? 'Pull to refresh news feed' : 'Search for CVEs',
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFeed
                ? 'Latest vulnerabilities from NVD'
                : 'Try: "Apache", "Log4J2", "CVE-2021-44228"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Powered by',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'NIST National Vulnerability Database',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'CVE Search uses NVD API and is not\nendorsed or certified by NIST/NVD.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter CVEs',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']
                  .map((s) => FilterChip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        selected: false,
                        onSelected: (_) {},
                        selectedColor: AppTheme.accent.withOpacity(0.2),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== CVE Card Widget =====
class _CveCard extends StatelessWidget {
  final CveItem item;
  final VoidCallback onTap;

  const _CveCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreColor = _scoreColor(item.cvssScore);

    return Material(
      color: isDark ? AppTheme.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.cvssScore?.toStringAsFixed(1) ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'SpaceMono',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.cveId,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  // Severity label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.severity,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9,
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 11, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    item.publishedDate,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (item.cwes.isNotEmpty)
                    ...item.cwes.take(2).map((cwe) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cwe,
                              style: const TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 9,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 9.0) return const Color(0xFF8B0000);
    if (score >= 7.0) return const Color(0xFFD44000);
    if (score >= 4.0) return const Color(0xFFE69500);
    return const Color(0xFF2E7D32);
  }
}
