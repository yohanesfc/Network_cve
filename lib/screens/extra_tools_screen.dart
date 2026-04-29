import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

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

class BinaryCalculatorScreen extends StatefulWidget {
  const BinaryCalculatorScreen({super.key});

  @override
  State<BinaryCalculatorScreen> createState() => _BinaryCalculatorScreenState();
}

class _BinaryCalculatorScreenState extends State<BinaryCalculatorScreen> {
  final TextEditingController _binToDecCtrl = TextEditingController();
  final TextEditingController _decToBinCtrl = TextEditingController();
  final TextEditingController _binA = TextEditingController();
  final TextEditingController _binB = TextEditingController();
  String _op = '+';

  String _binToDecResult = '-';
  String _decToBinResult = '-';
  String _arithResult = '-';

  @override
  void dispose() {
    _binToDecCtrl.dispose();
    _decToBinCtrl.dispose();
    _binA.dispose();
    _binB.dispose();
    super.dispose();
  }

  bool _isBinary(String v) => RegExp(r'^[01]+$').hasMatch(v);

  void _calcBinToDec() {
    final v = _binToDecCtrl.text.trim();
    if (!_isBinary(v)) {
      setState(() => _binToDecResult = 'Invalid binary input');
      return;
    }
    setState(() => _binToDecResult = int.parse(v, radix: 2).toString());
  }

  void _calcDecToBin() {
    final v = int.tryParse(_decToBinCtrl.text.trim());
    if (v == null || v < 0) {
      setState(() => _decToBinResult = 'Invalid decimal input');
      return;
    }
    setState(() => _decToBinResult = v.toRadixString(2));
  }

  void _calcArith() {
    final aText = _binA.text.trim();
    final bText = _binB.text.trim();
    if (!_isBinary(aText) || !_isBinary(bText)) {
      setState(() => _arithResult = 'Invalid binary input');
      return;
    }

    final a = int.parse(aText, radix: 2);
    final b = int.parse(bText, radix: 2);

    if (_op == '/' && b == 0) {
      setState(() => _arithResult = 'Division by zero');
      return;
    }

    int result;
    switch (_op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '*':
        result = a * b;
        break;
      case '/':
        result = a ~/ b;
        break;
      default:
        result = 0;
    }

    final sign = result < 0 ? '-' : '';
    final absVal = result.abs().toRadixString(2);
    setState(() => _arithResult = '$sign$absVal (${result.toString()})');
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Binary Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Binary → Decimal'),
          TextField(
            controller: _binToDecCtrl,
            decoration: const InputDecoration(
              labelText: 'Binary Value',
              hintText: '10101010',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _calcBinToDec, child: const Text('Calculate')),
          const SizedBox(height: 6),
          SelectableText('Result: $_binToDecResult'),
          const SizedBox(height: 20),

          _sectionTitle('Decimal → Binary'),
          TextField(
            controller: _decToBinCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Decimal Value',
              hintText: '170',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _calcDecToBin, child: const Text('Calculate')),
          const SizedBox(height: 6),
          SelectableText('Result: $_decToBinResult'),
          const SizedBox(height: 20),

          _sectionTitle('Binary arithmetic (add/subtract/multiply/divide)'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _binA,
                  decoration: const InputDecoration(labelText: 'Binary A'),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _op,
                items: const ['+', '-', '*', '/']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _op = v ?? '+'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _binB,
                  decoration: const InputDecoration(labelText: 'Binary B'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _calcArith, child: const Text('Calculate')),
          const SizedBox(height: 6),
          SelectableText('Result: $_arithResult'),
        ],
      ),
    );
  }
}

class RdapScreen extends StatefulWidget {
  final String host;
  const RdapScreen({super.key, required this.host});

  @override
  State<RdapScreen> createState() => _RdapScreenState();
}

class _RdapScreenState extends State<RdapScreen> {
  final List<String> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  bool _isIp(String input) {
    return RegExp(r'^[0-9]{1,3}(\.[0-9]{1,3}){3}$').hasMatch(input) ||
        input.contains(':');
  }

  Future<void> _lookup() async {
    final host = widget.host.trim();
    _add('RDAP Lookup: $host');
    _add('');

    if (host.isEmpty) {
      _add('Error: Host is empty');
      setState(() => _loading = false);
      return;
    }

    final isIp = _isIp(host);
    final endpoint = isIp
        ? 'https://rdap.org/ip/$host'
        : 'https://rdap.org/domain/$host';

    try {
      final resp = await http.get(Uri.parse(endpoint)).timeout(
            const Duration(seconds: 12),
          );

      _add('Endpoint: $endpoint');
      _add('HTTP: ${resp.statusCode}');
      _add('');

      if (resp.statusCode != 200) {
        _add('No RDAP data found.');
        setState(() => _loading = false);
        return;
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;

      _add('Handle: ${data['handle'] ?? '-'}');
      _add('Object: ${data['objectClassName'] ?? '-'}');
      _add('Name  : ${data['ldhName'] ?? data['name'] ?? host}');
      _add('');

      final status = data['status'] as List?;
      if (status != null && status.isNotEmpty) {
        _add('Status: ${status.join(', ')}');
      }

      final entities = data['entities'] as List?;
      if (entities != null && entities.isNotEmpty) {
        _add('Entities:');
        for (final e in entities.take(5)) {
          final m = e as Map<String, dynamic>;
          _add(' - ${m['handle'] ?? m['objectClassName'] ?? 'entity'}');
        }
      }

      final events = data['events'] as List?;
      if (events != null && events.isNotEmpty) {
        _add('');
        _add('Events:');
        for (final ev in events.take(8)) {
          final m = ev as Map<String, dynamic>;
          _add(
              ' - ${m['eventAction'] ?? '-'}: ${m['eventDate'] ?? '-'}');
        }
      }
    } catch (e) {
      _add('Error: $e');
    }

    setState(() => _loading = false);
  }

  void _add(String s) => setState(() => _lines.add(s));

  @override
  Widget build(BuildContext context) => _ToolTerminalScreen(
        title: 'RDAP: ${widget.host}',
        lines: _lines,
        loading: _loading,
      );
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

class HexCalculatorScreen extends StatefulWidget {
  const HexCalculatorScreen({super.key});

  @override
  State<HexCalculatorScreen> createState() => _HexCalculatorScreenState();
}

class _HexCalculatorScreenState extends State<HexCalculatorScreen> {
  final TextEditingController _hexToDecCtrl = TextEditingController();
  final TextEditingController _decToHexCtrl = TextEditingController();
  final TextEditingController _hexA = TextEditingController();
  final TextEditingController _hexB = TextEditingController();
  String _op = '+';

  String _hexToDecResult = '?';
  String _decToHexResult = '?';
  String _arithResult = '?';

  @override
  void dispose() {
    _hexToDecCtrl.dispose();
    _decToHexCtrl.dispose();
    _hexA.dispose();
    _hexB.dispose();
    super.dispose();
  }

  bool _isHex(String v) => RegExp(r'^[0-9a-fA-F]+$').hasMatch(v);

  void _calcHexToDec() {
    final v = _hexToDecCtrl.text.trim();
    if (!_isHex(v)) {
      setState(() => _hexToDecResult = 'Invalid hex input');
      return;
    }
    try {
      setState(() => _hexToDecResult = int.parse(v, radix: 16).toString());
    } catch (e) {
      setState(() => _hexToDecResult = 'Error');
    }
  }

  void _clearHexToDec() {
    _hexToDecCtrl.clear();
    setState(() => _hexToDecResult = '?');
  }

  void _calcDecToHex() {
    final v = int.tryParse(_decToHexCtrl.text.trim());
    if (v == null || v < 0) {
      setState(() => _decToHexResult = 'Invalid decimal input');
      return;
    }
    setState(() => _decToHexResult = v.toRadixString(16).toUpperCase());
  }

  void _clearDecToHex() {
    _decToHexCtrl.clear();
    setState(() => _decToHexResult = '?');
  }

  void _calcArith() {
    final aText = _hexA.text.trim();
    final bText = _hexB.text.trim();
    if (!_isHex(aText) || !_isHex(bText)) {
      setState(() => _arithResult = 'Invalid hex input');
      return;
    }

    try {
      final a = int.parse(aText, radix: 16);
      final b = int.parse(bText, radix: 16);

      if (_op == '/' && b == 0) {
        setState(() => _arithResult = 'Division by zero');
        return;
      }

      int result;
      switch (_op) {
        case '+':
          result = a + b;
          break;
        case '-':
          result = a - b;
          break;
        case '*':
          result = a * b;
          break;
        case '/':
          result = a ~/ b;
          break;
        default:
          result = 0;
      }

      final sign = result < 0 ? '-' : '';
      final absVal = result.abs().toRadixString(16).toUpperCase();
      setState(() => _arithResult = '$sign$absVal');
    } catch (e) {
      setState(() => _arithResult = 'Error');
    }
  }

  void _clearArith() {
    _hexA.clear();
    _hexB.clear();
    setState(() => _arithResult = '?');
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      );

  Widget _buildBox(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black26
            : Colors.grey[200],
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hex Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Convert Hexadecimal Value to Decimal Value'),
          _buildBox([
            Row(
              children: [
                const Text('Hexadecimal Value: '),
                Expanded(
                  child: TextField(
                    controller: _hexToDecCtrl,
                    decoration: const InputDecoration(
                      hintText: 'DAD',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('= $_hexToDecResult', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _calcHexToDec,
                  icon: const Icon(Icons.play_circle_fill, size: 18),
                  label: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _clearHexToDec,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),

          _sectionTitle('Convert Decimal Value to Hexadecimal Value'),
          _buildBox([
            Row(
              children: [
                const Text('Decimal Value: '),
                Expanded(
                  child: TextField(
                    controller: _decToHexCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '170',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('= $_decToHexResult', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _calcDecToHex,
                  icon: const Icon(Icons.play_circle_fill, size: 18),
                  label: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _clearDecToHex,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),

          _sectionTitle('Hexadecimal Calculation—Add, Subtract, Multiply, or Divide'),
          _buildBox([
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hexA,
                    decoration: const InputDecoration(
                      hintText: '8AB',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _op,
                      isDense: true,
                      items: const ['+', '-', '*', '/']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _op = v ?? '+'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hexB,
                    decoration: const InputDecoration(
                      hintText: 'B78',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('= $_arithResult', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _calcArith,
                  icon: const Icon(Icons.play_circle_fill, size: 18),
                  label: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _clearArith,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class SubnetCalculatorScreen extends StatefulWidget {
  final String host;
  const SubnetCalculatorScreen({super.key, required this.host});

  @override
  State<SubnetCalculatorScreen> createState() => _SubnetCalculatorScreenState();
}

class _SubnetCalculatorScreenState extends State<SubnetCalculatorScreen> {
  final TextEditingController _input = TextEditingController();
  final List<String> _lines = [];

  @override
  void initState() {
    super.initState();
    _input.text = widget.host;
    if (_input.text.isNotEmpty) {
      _calculate();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _intToIp(int val) {
    return '${(val >> 24) & 255}.${(val >> 16) & 255}.${(val >> 8) & 255}.${val & 255}';
  }

  void _calculate() {
    _lines.clear();
    String input = _input.text.trim();
    if (input.isEmpty) {
      setState(() => _lines.add('Please enter an IP or IP/CIDR'));
      return;
    }

    if (!input.contains('/')) {
      input += "/24";
    }

    try {
      List<String> parts = input.split('/');
      if (parts.length != 2) throw Exception('Invalid format');
      String ipStr = parts[0];
      int prefix = int.parse(parts[1]);
      if (prefix < 0 || prefix > 32) throw Exception('Invalid prefix (0-32)');

      List<int> octets = ipStr.split('.').map((e) => int.parse(e)).toList();
      if (octets.length != 4) throw Exception('Invalid IPv4 address');
      for (var o in octets) {
        if (o < 0 || o > 255) throw Exception('Octet out of range (0-255)');
      }

      int ip = (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3];
      int mask = prefix == 0 ? 0 : ((0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF);
      
      int network = ip & mask;
      int broadcast = network | (~mask & 0xFFFFFFFF);
      
      num totalHosts = 1 << (32 - prefix);
      num usableHosts = prefix >= 31 ? 0 : totalHosts - 2;

      _lines.add('Input      : $input');
      _lines.add('IP Address : $ipStr');
      _lines.add('Netmask    : ${_intToIp(mask)} (/$prefix)');
      _lines.add('Network    : ${_intToIp(network)}');
      _lines.add('Broadcast  : ${_intToIp(broadcast)}');
      _lines.add('First IP   : ${prefix >= 31 ? 'N/A' : _intToIp(network + 1)}');
      _lines.add('Last IP    : ${prefix >= 31 ? 'N/A' : _intToIp(broadcast - 1)}');
      _lines.add('Total Hosts: $totalHosts');
      _lines.add('Usable     : $usableHosts');
    } catch (e) {
      _lines.add('Error parsing input.');
      _lines.add('Example format: 192.168.1.1 or 10.0.0.1/24');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subnet Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _input,
              decoration: const InputDecoration(
                labelText: 'IPv4 Address or CIDR (e.g. 192.168.1.1/24)',
                hintText: '192.168.1.1/24',
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Calculate'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black26
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _lines.join('\n'),
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  int _length = 32;
  bool _includeLower = true;
  bool _includeUpper = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _excludeAmbiguous = true;
  bool _excludeBrackets = true;
  bool _noRepeated = true;

  String _password = '';
  double _entropy = 0;

  final TextEditingController _lengthCtrl = TextEditingController(text: '32');

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    String lower = 'abcdefghijklmnopqrstuvwxyz';
    String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String numbers = '0123456789';
    String symbols = '!"#\$%&\'()*+,-./:;<=>?@[\\]^_{|}~';

    String ambiguous = 'il1Ll| o0O `\'-_":;.,';
    String brackets = '<>(){}[]';

    String pool = '';
    if (_includeLower) pool += lower;
    if (_includeUpper) pool += upper;
    if (_includeNumbers) pool += numbers;
    if (_includeSymbols) pool += symbols;

    if (_excludeAmbiguous) {
      for (var char in ambiguous.split('')) {
        pool = pool.replaceAll(char, '');
      }
    }
    if (_excludeBrackets) {
      for (var char in brackets.split('')) {
        pool = pool.replaceAll(char, '');
      }
    }

    if (pool.isEmpty) {
      setState(() {
        _password = 'Error: No characters available.';
        _entropy = 0;
      });
      return;
    }

    final rand = math.Random.secure();
    StringBuffer pwd = StringBuffer();
    String currentPool = pool;

    for (int i = 0; i < _length; i++) {
      if (currentPool.isEmpty) {
        if (_noRepeated) {
          break; // Stop generating if pool is empty
        }
      }
      int index = rand.nextInt(currentPool.length);
      String c = currentPool[index];
      pwd.write(c);
      if (_noRepeated) {
        currentPool = currentPool.replaceFirst(c, '');
      }
    }

    setState(() {
      _password = pwd.toString();
      _entropy = _password.length * (math.log(pool.length) / math.ln2);
    });
  }

  String _getStrength() {
    if (_entropy < 40) return 'Weak';
    if (_entropy < 60) return 'Good';
    if (_entropy < 80) return 'Strong';
    return 'Very Strong';
  }

  Color _getStrengthColor() {
    if (_entropy < 40) return Colors.red;
    if (_entropy < 60) return Colors.orange;
    if (_entropy < 80) return Colors.lightGreen;
    return Colors.green;
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _password));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Random Password Generator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'This tool can generate secure, strong, random passwords. To ensure security, the password is generated completely on your device without being sent across the Internet.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            color: Colors.green[800],
            padding: const EdgeInsets.all(8),
            child: const Text('Password', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  _password,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Password Strength: '),
                    Text(_getStrength(), style: TextStyle(color: _getStrengthColor(), fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    const Text('Password Entropy: '),
                    Text('${_entropy.toStringAsFixed(1)} bits'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Password'),
                    ),
                    TextButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Regenerate'),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.grey[200],
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Password Length: '),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _lengthCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        onChanged: (val) {
                          int? v = int.tryParse(val);
                          if (v != null && v > 0) {
                            setState(() => _length = v);
                            _generate();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _length.toDouble(),
                  min: 4,
                  max: 128,
                  onChanged: (val) {
                    setState(() {
                      _length = val.toInt();
                      _lengthCtrl.text = _length.toString();
                    });
                    _generate();
                  },
                ),
                _check('Include Lower Case (a-z)', _includeLower, (v) => setState(() => _includeLower = v!)),
                _check('Include Upper Case (A-Z)', _includeUpper, (v) => setState(() => _includeUpper = v!)),
                _check('Include Numbers (0-9)', _includeNumbers, (v) => setState(() => _includeNumbers = v!)),
                _check('Include Symbols (!"#\$%&\'()*+,-./:;<=>?@[\\]^_{|}~)', _includeSymbols, (v) => setState(() => _includeSymbols = v!)),
                _check('Exclude Ambiguous Characters (il1Ll| o0O `\'-_":;.,)', _excludeAmbiguous, (v) => setState(() => _excludeAmbiguous = v!)),
                _check('Exclude Brackets (<>()[])', _excludeBrackets, (v) => setState(() => _excludeBrackets = v!)),
                _check('No Repeated Characters', _noRepeated, (v) => setState(() => _noRepeated = v!)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.play_circle_fill, size: 18),
                  label: const Text('Generate', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _check(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) {
          onChanged(v);
          _generate();
        }),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
