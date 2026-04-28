import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../widgets/tool_button.dart';
import '../widgets/host_input.dart';
import 'ping_result_screen.dart';
import 'dns_screen.dart';
import 'cve_search_screen.dart';
import 'extra_tools_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _hostController = TextEditingController(
    text: '192.168.100.1',
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
      _showError('Masukkan host terlebih dahulu');
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

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Ping & Net'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share('Check out Ping & Net + CVE app!'),
          ),
        ],
      ),
      drawer: _buildDrawer(isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Host Input
            HostInputWidget(controller: _hostController),
            const SizedBox(height: 16),

            // Ping row
            Row(
              children: [
                const Text(
                  'Ping:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceMono',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ToolButton(
                    label: 'IPv4',
                    onTap: () => _ping('IPv4'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ToolButton(
                    label: 'IPv6',
                    onTap: () => _ping('IPv6'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ToolButton(
                    label: 'TCP',
                    onTap: () => _ping('TCP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tool Grid
            _buildGrid([
              _ToolItem('DNS', Icons.dns, () {
                _navigate(DnsScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Reverse DNS', Icons.swap_horiz, () {
                _navigate(DnsScreen(
                  host: _hostController.text.trim(),
                  isReverse: true,
                ));
              }),
              _ToolItem('Traceroute', Icons.route, () {
                _navigate(TracerouteScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('HTTP Headers', Icons.http, () {
                _navigate(HttpHeadersScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('SSL Scan', Icons.lock, () {
                _navigate(SslScanScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Port Range', Icons.lan, () {
                _navigate(PortScanScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Subnet Scan', Icons.network_check, () {
                _navigate(SubnetScanScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Network Info', Icons.info_outline, () {
                _navigate(const NetworkInfoScreen());
              }),
              _ToolItem('Dig', Icons.search, () {
                _navigate(DigScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Secure DNS', Icons.security, () {
                _navigate(SecureDnsScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Is it up?', Icons.check_circle_outline, () {
                _navigate(IsItUpScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Geo Lookup', Icons.map, () {
                _navigate(GeoLookupScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Whois', Icons.person_search, () {
                _navigate(WhoisScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('RDAP', Icons.policy, () {
                _showComingSoon('RDAP');
              }),
              _ToolItem('IDN ↔ ACE', Icons.translate, () {
                _navigate(IdnAceScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Wake on LAN', Icons.power, () {
                _navigate(WakeOnLanScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Spam Check', Icons.block, () {
                _navigate(SpamCheckScreen(host: _hostController.text.trim()));
              }),
              _ToolItem('Path MTU', Icons.straighten, () {
                _navigate(PathMtuScreen(host: _hostController.text.trim()));
              }),
            ]),

            const SizedBox(height: 12),

            // ===== CVE SEARCH BUTTON (NEW - HIGHLIGHTED) =====
            _CveSearchButton(
              onTap: () => _navigate(const CveSearchScreen()),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildGrid(List<_ToolItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
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
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primary),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.network_ping, color: Colors.white, size: 36),
                SizedBox(height: 8),
                Text(
                  'Ping & Net + CVE',
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
          _drawerItem(Icons.dns, 'List of servers', () {}),
          _drawerItem(Icons.storage, 'List of DNS servers', () {}),
          _drawerItem(Icons.email, 'Email results', () {}),
          _drawerItem(Icons.save, 'Save results', () {}),
          _drawerItem(Icons.close, 'Close all tabs', () {}),
          const Divider(),
          _drawerItem(Icons.settings, 'Preferences', () {}),
          _drawerItem(Icons.help_outline, 'Help', () {}),
          _drawerItem(Icons.info, 'About / FAQ', () {}),
          _drawerItem(Icons.history, 'Version history', () {}),
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
                  color: AppTheme.accent.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
