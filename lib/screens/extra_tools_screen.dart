import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

class SslScanScreen extends StatefulWidget {
  final String host;
  const SslScanScreen({super.key, required this.host});

  @override
  State<SslScanScreen> createState() => _SslScanScreenState();
}

class _SslScanScreenState extends State<SslScanScreen> {
  final List<String> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    final host = widget.host.trim();
    _add('SSL Scan: $host');
    _add('');
    if (host.isEmpty) {
      _add('Error: Host is empty');
      setState(() => _loading = false);
      return;
    }

    try {
      final socket = await SecureSocket.connect(
        host,
        443,
        timeout: const Duration(seconds: 8),
      );
      _add('TLS handshake: success');
      _add('Selected protocol: ${socket.selectedProtocol ?? 'n/a'}');
      _add('Peer: ${socket.remoteAddress.address}:${socket.remotePort}');
      final cert = socket.peerCertificate;
      if (cert != null) {
        _add('Certificate subject: ${cert.subject}');
        _add('Certificate issuer : ${cert.issuer}');
        _add('Valid from: ${cert.startValidity}');
        _add('Valid to  : ${cert.endValidity}');
        _add('SHA1      : ${cert.sha1}');
      } else {
        _add('Certificate: unavailable');
      }
      await socket.close();
      _add('');
      _add('SSL scan complete.');
    } catch (e) {
      _add('Error: $e');
    }

    setState(() => _loading = false);
  }

  void _add(String s) => setState(() => _lines.add(s));

  @override
  Widget build(BuildContext context) {
    return _ToolTerminalScreen(
      title: 'SSL Scan: ${widget.host}',
      lines: _lines,
      loading: _loading,
    );
  }
}

class SubnetScanScreen extends StatefulWidget {
  final String host;
  const SubnetScanScreen({super.key, required this.host});

  @override
  State<SubnetScanScreen> createState() => _SubnetScanScreenState();
}

class _SubnetScanScreenState extends State<SubnetScanScreen> {
  final List<String> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scanSubnet();
  }

  Future<void> _scanSubnet() async {
    final baseIp = widget.host.trim();
    _add('Subnet Scan (/24 sample): $baseIp');
    _add('Checking first 32 hosts with TCP/80 connect...');
    _add('');

    final parts = baseIp.split('.');
    if (parts.length != 4) {
      _add('Error: use IPv4 address format, e.g. 192.168.1.1');
      setState(() => _loading = false);
      return;
    }
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';

    int up = 0;
    for (int i = 1; i <= 32; i++) {
      final ip = '$prefix.$i';
      try {
        final s = await Socket.connect(
          ip,
          80,
          timeout: const Duration(milliseconds: 250),
        );
        _add('$ip  UP');
        up++;
        await s.close();
      } catch (_) {
        _add('$ip  down');
      }
    }

    _add('');
    _add('Scan done. Hosts up: $up/32');
    setState(() => _loading = false);
  }

  void _add(String s) => setState(() => _lines.add(s));

  @override
  Widget build(BuildContext context) {
    return _ToolTerminalScreen(
      title: 'Subnet Scan',
      lines: _lines,
      loading: _loading,
    );
  }
}

class DigScreen extends StatefulWidget {
  final String host;
  const DigScreen({super.key, required this.host});

  @override
  State<DigScreen> createState() => _DigScreenState();
}

class _DigScreenState extends State<DigScreen> {
  final List<String> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _dig();
  }

  Future<void> _dig() async {
    final host = widget.host.trim();
    _add('dig $host +short');
    _add('');

    if (host.isEmpty) {
      _add('Error: Host is empty');
      setState(() => _loading = false);
      return;
    }

    try {
      final types = ['A', 'AAAA', 'MX', 'NS', 'TXT'];
      for (final type in types) {
        final uri = Uri.parse(
          'https://dns.google/resolve?name=$host&type=$type',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 8));
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final ans = (data['Answer'] as List?) ?? [];
        _add('[$type]');
        if (ans.isEmpty) {
          _add('  <no answer>');
        } else {
          for (final a in ans) {
            _add('  ${a['data']}');
          }
        }
        _add('');
      }
    } catch (e) {
      _add('Error: $e');
    }

    setState(() => _loading = false);
  }

  void _add(String s) => setState(() => _lines.add(s));

  @override
  Widget build(BuildContext context) {
    return _ToolTerminalScreen(
      title: 'Dig: ${widget.host}',
      lines: _lines,
      loading: _loading,
    );
  }
}

class SecureDnsScreen extends StatefulWidget {
  final String host;
  const SecureDnsScreen({super.key, required this.host});

  @override
  State<SecureDnsScreen> createState() => _SecureDnsScreenState();
}

class _SecureDnsScreenState extends State<SecureDnsScreen> {
  final List<String> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final host = widget.host.trim();
    _add('Secure DNS check: $host');
    _add('');

    try {
      final uri = Uri.parse('https://dns.google/resolve?name=$host&type=A');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      final data = json.decode(resp.body) as Map<String, dynamic>;

      final ad = data['AD'] == true;
      final cd = data['CD'] == true;
      _add('DoH endpoint: dns.google');
      _add('DNSSEC AD flag: $ad');
      _add('Checking Disabled (CD): $cd');

      final status = data['Status'];
      _add('Response status: $status');

      if ((data['Answer'] as List?)?.isNotEmpty == true) {
        _add('Answer count: ${(data['Answer'] as List).length}');
      } else {
        _add('No answer records');
      }
    } catch (e) {
      _add('Error: $e');
    }

    setState(() => _loading = false);
  }

  void _add(String s) => setState(() => _lines.add(s));

  @override
  Widget build(BuildContext context) => _ToolTerminalScreen(
        title: 'Secure DNS',
        lines: _lines,
        loading: _loading,
      );
}

class IsItUpScreen extends StatefulWidget {
  final String host;
  const IsItUpScreen({super.key, required this.host});

  @override
  State<IsItUpScreen> createState() => _IsItUpScreenState();
}

class _IsItUpScreenState extends State<IsItUpScreen> {
  final List<String> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final host = widget.host.trim();
    _add('Uptime check: $host');
    _add('');

    if (host.isEmpty) {
      _add('Error: Host is empty');
      setState(() => _loading = false);
      return;
    }

    final urls = [
      'https://$host',
      'http://$host',
    ];

    bool up = false;
    for (final u in urls) {
      try {
        final resp = await http
            .head(Uri.parse(u))
            .timeout(const Duration(seconds: 6));
        _add('$u -> HTTP ${resp.statusCode}');
        if (resp.statusCode < 500) up = true;
      } catch (e) {
        _add('$u -> failed ($e)');
      }
    }

    _add('');
    _add(up ? 'Result: UP' : 'Result: DOWN / unreachable');
    setState(() => _loading = false);
  }

  void _add(String s) => setState(() => _lines.add(s));

  @override
  Widget build(BuildContext context) => _ToolTerminalScreen(
        title: 'Is it up?',
        lines: _lines,
        loading: _loading,
      );
}

class IdnAceScreen extends StatefulWidget {
  final String host;
  const IdnAceScreen({super.key, required this.host});

  @override
  State<IdnAceScreen> createState() => _IdnAceScreenState();
}

class _IdnAceScreenState extends State<IdnAceScreen> {
  final TextEditingController _input = TextEditingController();
  String _output = '-';

  @override
  void initState() {
    super.initState();
    _input.text = widget.host;
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _convert() {
    final v = _input.text.trim();
    if (v.isEmpty) {
      setState(() => _output = 'Input is empty');
      return;
    }

    // Minimal practical conversion:
    // - if starts with xn-- : show decoded not implemented but keep explicit
    // - else: use Uri host normalization as ACE approximation
    if (v.startsWith('xn--')) {
      setState(() => _output = 'ACE input detected: $v');
      return;
    }

    try {
      final uri = Uri.parse('https://$v');
      setState(() => _output = 'ACE: ${uri.host}');
    } catch (e) {
      setState(() => _output = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IDN ↔ ACE'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _input,
              decoration: const InputDecoration(
                labelText: 'Domain',
                hintText: 'contoh: bücher.de / xn--bcher-kva.de',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _convert,
              child: const Text('Convert'),
            ),
            const SizedBox(height: 16),
            SelectableText(
              _output,
              style: const TextStyle(fontFamily: 'SpaceMono'),
            ),
          ],
        ),
      ),
    );
  }
}

class WakeOnLanScreen extends StatefulWidget {
  final String host;
  const WakeOnLanScreen({super.key, required this.host});

  @override
  State<WakeOnLanScreen> createState() => _WakeOnLanScreenState();
}

class _WakeOnLanScreenState extends State<WakeOnLanScreen> {
  final TextEditingController _macCtrl = TextEditingController();
  final TextEditingController _broadcastCtrl =
      TextEditingController(text: '255.255.255.255');
  final TextEditingController _portCtrl = TextEditingController(text: '9');
  String _result = '-';

  @override
  void dispose() {
    _macCtrl.dispose();
    _broadcastCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  List<int>? _parseMac(String mac) {
    final cleaned = mac.replaceAll('-', ':').toLowerCase().trim();
    final parts = cleaned.split(':');
    if (parts.length != 6) return null;
    final bytes = <int>[];
    for (final p in parts) {
      final v = int.tryParse(p, radix: 16);
      if (v == null) return null;
      bytes.add(v);
    }
    return bytes;
  }

  Future<void> _sendMagicPacket() async {
    final mac = _parseMac(_macCtrl.text);
    if (mac == null) {
      setState(() => _result = 'Invalid MAC format');
      return;
    }

    final port = int.tryParse(_portCtrl.text) ?? 9;
    final packet = <int>[];
    packet.addAll(List.filled(6, 0xFF));
    for (int i = 0; i < 16; i++) {
      packet.addAll(mac);
    }

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(
        packet,
        InternetAddress(_broadcastCtrl.text.trim()),
        port,
      );
      socket.close();
      setState(() => _result = 'Magic packet sent successfully');
    } catch (e) {
      setState(() => _result = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wake on LAN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _macCtrl,
              decoration: const InputDecoration(
                labelText: 'MAC Address',
                hintText: 'AA:BB:CC:DD:EE:FF',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _broadcastCtrl,
              decoration: const InputDecoration(labelText: 'Broadcast IP'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _portCtrl,
              decoration: const InputDecoration(labelText: 'UDP Port'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _sendMagicPacket,
              child: const Text('Send Magic Packet'),
            ),
            const SizedBox(height: 16),
            SelectableText(
              _result,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpamCheckScreen extends StatefulWidget {
  final String host;
  const SpamCheckScreen({super.key, required this.host});

  @override
  State<SpamCheckScreen> createState() => _SpamCheckScreenState();
}

class _SpamCheckScreenState extends State<SpamCheckScreen> {
  final List<String> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final host = widget.host.trim();
    _add('Spam Check (basic): $host');
    _add('');

    // Basic checks: SPF/DMARC DNS TXT lookups
    final checks = <String, String>{
      'SPF': host,
      'DMARC': '_dmarc.$host',
    };

    try {
      for (final e in checks.entries) {
        final uri = Uri.parse(
          'https://dns.google/resolve?name=${e.value}&type=TXT',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 8));
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final answers = data['Answer'] as List? ?? [];
        _add('[${e.key}]');
        if (answers.isEmpty) {
          _add('  not found');
        } else {
          for (final a in answers) {
            _add('  ${a['data']}');
          }
        }
        _add('');
      }
      _add('Spam check complete.');
    } catch (e) {
      _add('Error: $e');
    }

    setState(() => _loading = false);
  }

  void _add(String s) => setState(() => _lines.add(s));

  @override
  Widget build(BuildContext context) => _ToolTerminalScreen(
        title: 'Spam Check',
        lines: _lines,
        loading: _loading,
      );
}

class PathMtuScreen extends StatefulWidget {
  final String host;
  const PathMtuScreen({super.key, required this.host});

  @override
  State<PathMtuScreen> createState() => _PathMtuScreenState();
}

class _PathMtuScreenState extends State<PathMtuScreen> {
  final List<String> _lines = [
    'Path MTU discovery requires low-level socket/ICMP controls.',
    'On mobile platforms this is limited by OS policies.',
    '',
    'Recommendation:',
    '- Use desktop tools (tracepath / ping -M do)',
    '- Or use server-side probing endpoint',
  ];

  @override
  Widget build(BuildContext context) => _ToolTerminalScreen(
        title: 'Path MTU: ${widget.host}',
        lines: _lines,
        loading: false,
      );
}

class _ToolTerminalScreen extends StatelessWidget {
  final String title;
  final List<String> lines;
  final bool loading;

  const _ToolTerminalScreen({
    required this.title,
    required this.lines,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 13),
        ),
        actions: [
          if (loading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Container(
        color: const Color(0xFF0D1117),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemCount: lines.length,
          itemBuilder: (_, i) => Text(
            lines[i],
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              color: lines[i].toLowerCase().contains('error')
                  ? Colors.redAccent
                  : Colors.greenAccent,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
