import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../widgets/tool_button.dart';
import '../widgets/host_input.dart';
import 'ping_result_screen.dart';
import 'dns_screen.dart';
import 'cve_search_screen.dart';
import 'extra_tools_screen.dart';
import 'speed_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _hostController = TextEditingController(
    text: '8.8.8.8',
  );

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _ping(String type) {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      _showError('Input Hostname or IP Address');
      return;
    }
    _navigate(PingResultScreen(host: host, pingType: type));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF4DB6C8) : AppTheme.primary;

    return Scaffold(
      // ── Gradient AppBar ──────────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006B7A), Color(0xFF004A55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: const Row(
              children: [
                Icon(Icons.network_ping, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Network + CVE Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'SpaceMono',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () =>
                    Share.share('Check out Network + CVE Tools app!'),
              ),
            ],
          ),
        ),
      ),

      drawer: _buildDrawer(isDark),

      // ── Body ─────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Host input
            HostInputWidget(controller: _hostController),
            const SizedBox(height: 20),

            // ── Ping ────────────────────────────────────────────────────────
            _buildSectionHeader('Ping', Icons.wifi_tethering, color),
            const SizedBox(height: 10),
            _buildPingRow(),
            const SizedBox(height: 22),

            // ── Network Diagnostics ─────────────────────────────────────────
            _buildSectionHeader('Network Diagnostics', Icons.network_check, color),
            const SizedBox(height: 10),
            _buildGrid([
              _ToolItem('DNS', Icons.dns, () {
                _navigate(DnsScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Traceroute', Icons.route, () {
                _navigate(TracerouteScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Dig', Icons.search, () {
                _navigate(DigScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Secure DNS', Icons.security, () {
                _navigate(SecureDnsScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Speed Test', Icons.speed, () {
                _navigate(const SpeedTestScreen());
              }),
              _ToolItem('HTTP Headers', Icons.http, () {
                _navigate(HttpHeadersScreen(host: _hostController.text.trim()));
              }),
            ]),
            const SizedBox(height: 22),

            // ── Scanning & Security ─────────────────────────────────────────
            _buildSectionHeader('Scanning & Security', Icons.shield, color),
            const SizedBox(height: 10),
            _buildGrid([
              _ToolItem('SSL Scan', Icons.lock, () {
                _navigate(SslScanScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Port Range', Icons.lan, () {
                _navigate(PortScanScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Subnet Scan', Icons.manage_search, () {
                _navigate(SubnetScanScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Spam Check', Icons.block, () {
                _navigate(SpamCheckScreen(host: _hostController.text.trim()));
              }),
            ]),
            const SizedBox(height: 22),

            // ── Network Info ────────────────────────────────────────────────
            _buildSectionHeader('Network Info', Icons.info_outline, color),
            const SizedBox(height: 10),
            _buildGrid([
              _ToolItem('Network Info', Icons.info, () {
                _navigate(const NetworkInfoScreen());
              }),
              _ToolItem('Geo Lookup', Icons.map, () {
                _navigate(GeoLookupScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Whois', Icons.person_search, () {
                _navigate(WhoisScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('RDAP', Icons.policy, () {
                _navigate(RdapScreen(host: _hostController.text.trim()));
              }),
            ]),
            const SizedBox(height: 22),

            // ── Calculators (grouped) ───────────────────────────────────────
            _buildSectionHeader('Calculators', Icons.calculate, color),
            const SizedBox(height: 10),
            _buildGrid([
              _ToolItem('Subnet Calc', Icons.calculate, () {
                _navigate(SubnetCalculatorScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Binary Calc', Icons.numbers, () {
                _navigate(const BinaryCalculatorScreen());
              }),
              _ToolItem('Hex Calc', Icons.functions, () {
                _navigate(const HexCalculatorScreen());
              }),
            ]),
            const SizedBox(height: 22),

            // ── Security Tools ──────────────────────────────────────────────
            _buildSectionHeader('Security Tools', Icons.password, color),
            const SizedBox(height: 10),
            _buildGrid([
              _ToolItem('Pass Generator', Icons.password, () {
                _navigate(const PasswordGeneratorScreen());
              }),
            ]),
            const SizedBox(height: 22),

            // ── CVE Search ──────────────────────────────────────────────────
            _buildSectionHeader('Vulnerability', Icons.bug_report, AppTheme.accent),
            const SizedBox(height: 10),
            _CveSearchButton(
              onTap: () => _navigate(const CveSearchScreen()),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.25), thickness: 1),
        ),
      ],
    );
  }

  // ── Ping row ─────────────────────────────────────────────────────────────
  Widget _buildPingRow() {
    return Row(
      children: [
        _buildPingButton('IPv4', Icons.computer, () => _ping('IPv4')),
        const SizedBox(width: 8),
        _buildPingButton('IPv6', Icons.devices, () => _ping('IPv6')),
        const SizedBox(width: 8),
        _buildPingButton('TCP', Icons.cable, () => _ping('TCP')),
      ],
    );
  }

  Widget _buildPingButton(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006B7A), Color(0xFF00838F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tool Grid ─────────────────────────────────────────────────────────────
  Widget _buildGrid(List<_ToolItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 100,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => ToolButton(
        label: items[i].label,
        icon: items[i].icon,
        onTap: items[i].onTap,
      ),
    );
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006B7A), Color(0xFF004A55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.network_ping, color: Colors.white, size: 36),
                SizedBox(height: 8),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'SpaceMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.dns, 'Servers', () {
            Navigator.pop(context);
            _showServersList();
          }),
//          _drawerItem(Icons.storage, 'DNS servers', () {
//            Navigator.pop(context);
//            _showDnsServersList();
//          }),
          _drawerItem(Icons.email, 'E-mail', () {
            Navigator.pop(context);
            _emailResults();
          }),
//          _drawerItem(Icons.save, 'Save', () {
//            Navigator.pop(context);
//            _saveResults();
//          }),
//         _drawerItem(Icons.close, 'Close all tabs', () {
//            Navigator.pop(context);
//            Navigator.popUntil(context, (route) => route.isFirst);
//          }),
          const Divider(),
          _drawerItem(Icons.settings, 'Preferences', () {
            Navigator.pop(context);
            _showPreferences();
          }),
          _drawerItem(Icons.help_outline, 'Help', () {
            Navigator.pop(context);
            _showHelp();
          }),
          _drawerItem(Icons.info, 'About / FAQ', () {
            Navigator.pop(context);
            _showAbout();
          }),
          _drawerItem(Icons.history, 'Version history', () {
            Navigator.pop(context);
            _showVersionHistory();
          }),
          const Divider(),
          // CVE Search in drawer too
          _drawerItem(
            Icons.bug_report,
            'CVE Search',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CveSearchScreen()),
              );
            },
            color: AppTheme.accent,
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primary, size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 13,
          color: color,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  void _showServersList() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _SimpleListSheet(
        title: 'Servers',
        items: const [
          'google.com',
          'cloudflare.com',
          'github.com',
          '1.1.1.1',
          '8.8.8.8',
        ],
        onItemTap: (val) {
          _hostController.text = val;
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDnsServersList() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _SimpleListSheet(
        title: 'DNS servers',
        items: const [
          '1.1.1.1 (Cloudflare)',
          '8.8.8.8 (Google)',
          '9.9.9.9 (Quad9)',
          '208.67.222.222 (OpenDNS)',
        ],
        onItemTap: (val) {
          _hostController.text = val.split(' ').first;
          Navigator.pop(context);
        },
      ),
    );
  }

  void _emailResults() {
    final host = _hostController.text.trim();
    final subject = Uri.encodeComponent('Network + CVE Tools — Report for $host');
    final body = Uri.encodeComponent(
      'Hello,\n\n'
      'I am sharing network results from Network + CVE Tools.\n\n'
      'Host / IP : $host\n\n'
      '— Sent via Network + CVE Tools',
    );
    final uri = Uri.parse('mailto:noc@yohanesfc.web.id?subject=$subject&body=$body');
    launchUrl(uri).catchError((_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email app found on this device.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    });
  }

  void _saveResults() {
    final host = _hostController.text.trim();
    final text = 'Network + CVE Tools\nHost / IP : $host';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPreferences() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Preferences'),
        content: const Text(
          'Preferences UI will be expanded in next update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Help'),
        content: const Text(
          'Enter host/IP, then run tools from grid.\nUse drawer for quick actions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About / FAQ'),
        content: const Text(
          'Network + CVE Tools\n'
          'A comprehensive network utility and CVE lookup application.\n\n'
          'We truly appreciate your time using this app. '
          'Should you have any questions, suggestions, or encounter any issues, '
          'please feel free to reach out to us — we\'d love to hear from you:\n'
          '📧 tac@yohanesfc.web.id\n\n'
          'If you find this app helpful and would like to support its continued development, '
          'your generosity would mean a great deal to us:\n'
          '🏦 BCA · 5000389341 · Yohanes Lengkong\n\n'
          'Thank you so much for your kind support! 🙏',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVersionHistory() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Version history'),
        content: const Text(
          'v1.0 - Base tools\nv1.1 - CVE Search integration\nv1.2 - Extra tools added',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SimpleListSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final ValueChanged<String> onItemTap;

  const _SimpleListSheet({
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (e) => ListTile(
                dense: true,
                leading: const Icon(Icons.chevron_right),
                title: Text(
                  e,
                  style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 12),
                ),
                onTap: () => onItemTap(e),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ToolItem(this.label, this.icon, this.onTap);
}

// ===== WIDGET TOMBOL CVE SEARCH KHUSUS =====
class _CveSearchButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CveSearchButton({required this.onTap});

  @override
  State<_CveSearchButton> createState() => _CveSearchButtonState();
}

class _CveSearchButtonState extends State<_CveSearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD44000), Color(0xFFFF6B35)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bug_report, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CVE Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'SpaceMono',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Powered by NIST NVD',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
