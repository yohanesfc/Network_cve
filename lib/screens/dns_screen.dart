import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../main.dart';

// ===== DNS Screen =====
class DnsScreen extends StatefulWidget {
  final String host;
  final bool isReverse;
  const DnsScreen({super.key, required this.host, this.isReverse = false});

  @override
  State<DnsScreen> createState() => _DnsScreenState();
}

class _DnsScreenState extends State<DnsScreen> {
  final List<String> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    _addLine(widget.isReverse
        ? 'Reverse DNS lookup: ${widget.host}'
        : 'DNS lookup: ${widget.host}');
    try {
      // Use Google DNS-over-HTTPS as fallback
      final type = widget.isReverse ? 'PTR' : 'A';
      final query = widget.isReverse
          ? '${widget.host.split('.').reversed.join('.')}.in-addr.arpa'
          : widget.host;
      final uri = Uri.parse(
          'https://dns.google/resolve?name=$query&type=$type');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      final data = json.decode(resp.body);
      final answers = data['Answer'] as List? ?? [];
      if (answers.isEmpty) {
        _addLine('No records found.');
      } else {
        for (final a in answers) {
          _addLine('${a['name']} → ${a['data']} (TTL: ${a['TTL']}s)');
        }
      }
    } catch (e) {
      _addLine('Error: $e');
    }
    setState(() => _loading = false);
  }

  void _addLine(String l) => setState(() => _lines.add(l));

  @override
  Widget build(BuildContext context) => _TerminalScreen(
        title: widget.isReverse ? 'Reverse DNS' : 'DNS Lookup',
        lines: _lines,
        loading: _loading,
      );
}

// ===== Traceroute Screen =====
class TracerouteScreen extends StatefulWidget {
  final String host;
  const TracerouteScreen({super.key, required this.host});
  @override
  State<TracerouteScreen> createState() => _TracerouteScreenState();
}

class _TracerouteScreenState extends State<TracerouteScreen> {
  final List<String> _lines = ['Traceroute is not available on mobile.', '',
      'Tip: Use a desktop tool like tracert (Windows) or traceroute (Linux/Mac).'];

  @override
  Widget build(BuildContext context) => _TerminalScreen(
        title: 'Traceroute: ${widget.host}',
        lines: _lines,
        loading: false,
      );
}

// ===== Port Scan Screen =====
class PortScanScreen extends StatefulWidget {
  final String host;
  const PortScanScreen({super.key, required this.host});
  @override
  State<PortScanScreen> createState() => _PortScanScreenState();
}

class _PortScanScreenState extends State<PortScanScreen> {
  final List<String> _lines = [];
  bool _loading = true;
  final _commonPorts = [21, 22, 23, 25, 53, 80, 110, 143, 443, 445, 3306, 3389, 5432, 8080, 8443];

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    _addLine('Port scan: ${widget.host}');
    _addLine('Checking ${_commonPorts.length} common ports...');
    _addLine('');

    for (final port in _commonPorts) {
      try {
        final sock = await Socket.connect(
          widget.host, port,
          timeout: const Duration(milliseconds: 800),
        );
        _addLine('  [$port] OPEN');
        await sock.close();
      } catch (_) {
        _addLine('  [$port] closed');
      }
    }
    _addLine('');
    _addLine('Scan complete.');
    setState(() => _loading = false);
  }

  void _addLine(String l) => setState(() => _lines.add(l));

  @override
  Widget build(BuildContext context) => _TerminalScreen(
        title: 'Port Scan: ${widget.host}',
        lines: _lines,
        loading: _loading,
      );
}

// ===== Network Info Screen =====
class NetworkInfoScreen extends StatefulWidget {
  const NetworkInfoScreen({super.key});
  @override
  State<NetworkInfoScreen> createState() => _NetworkInfoScreenState();
}

class _NetworkInfoScreenState extends State<NetworkInfoScreen> {
  Map<String, String> _info = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Get public IP
      final resp = await http
          .get(Uri.parse('https://ipinfo.io/json'))
          .timeout(const Duration(seconds: 8));
      final data = json.decode(resp.body) as Map<String, dynamic>;
      setState(() {
        _info = {
          'Public IP': data['ip'] ?? '-',
          'Hostname': data['hostname'] ?? '-',
          'City': data['city'] ?? '-',
          'Region': data['region'] ?? '-',
          'Country': data['country'] ?? '-',
          'Organization': data['org'] ?? '-',
          'Timezone': data['timezone'] ?? '-',
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _info = {'Error': e.toString()};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Info')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _info.entries
                  .map((e) => Card(
                        child: ListTile(
                          title: Text(
                            e.key,
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 12,
                              color: AppTheme.primary,
                            ),
                          ),
                          trailing: Text(
                            e.value,
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

// ===== HTTP Headers Screen =====
class HttpHeadersScreen extends StatefulWidget {
  final String host;
  const HttpHeadersScreen({super.key, required this.host});
  @override
  State<HttpHeadersScreen> createState() => _HttpHeadersScreenState();
}

class _HttpHeadersScreenState extends State<HttpHeadersScreen> {
  final List<String> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final url = widget.host.startsWith('http')
        ? widget.host
        : 'https://${widget.host}';
    _addLine('HTTP Headers: $url');
    _addLine('');
    try {
      final resp = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      _addLine('Status: ${resp.statusCode}');
      _addLine('');
      resp.headers.forEach((k, v) => _addLine('$k: $v'));
    } catch (e) {
      _addLine('Error: $e');
    }
    setState(() => _loading = false);
  }

  void _addLine(String l) => setState(() => _lines.add(l));

  @override
  Widget build(BuildContext context) => _TerminalScreen(
        title: 'HTTP Headers',
        lines: _lines,
        loading: _loading,
      );
}

// ===== Whois Screen =====
class WhoisScreen extends StatefulWidget {
  final String host;
  const WhoisScreen({super.key, required this.host});
  @override
  State<WhoisScreen> createState() => _WhoisScreenState();
}

class _WhoisScreenState extends State<WhoisScreen> {
  String _result = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    try {
      final resp = await http
          .get(Uri.parse('https://rdap.verisign.com/com/v1/domain/${widget.host}'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final sb = StringBuffer();
        sb.writeln('Domain: ${data['ldhName'] ?? widget.host}');
        sb.writeln('Status: ${(data['status'] as List?)?.join(', ') ?? '-'}');
        final events = data['events'] as List? ?? [];
        for (final e in events) {
          sb.writeln('${e['eventAction']}: ${e['eventDate'] ?? '-'}');
        }
        setState(() {
          _result = sb.toString();
          _loading = false;
        });
      } else {
        setState(() {
          _result = 'No WHOIS data found for ${widget.host}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _TerminalScreen(
        title: 'Whois: ${widget.host}',
        lines: _result.split('\n'),
        loading: _loading,
      );
}

// ===== Geo Lookup Screen =====
class GeoLookupScreen extends StatefulWidget {
  final String host;
  const GeoLookupScreen({super.key, required this.host});
  @override
  State<GeoLookupScreen> createState() => _GeoLookupScreenState();
}

class _GeoLookupScreenState extends State<GeoLookupScreen> {
  Map<String, String> _info = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    try {
      final resp = await http
          .get(Uri.parse('https://ipinfo.io/${widget.host}/json'))
          .timeout(const Duration(seconds: 8));
      final data = json.decode(resp.body) as Map<String, dynamic>;
      setState(() {
        _info = {
          'IP': data['ip'] ?? '-',
          'City': data['city'] ?? '-',
          'Region': data['region'] ?? '-',
          'Country': data['country'] ?? '-',
          'Location': data['loc'] ?? '-',
          'Organization': data['org'] ?? '-',
          'Postal': data['postal'] ?? '-',
          'Timezone': data['timezone'] ?? '-',
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _info = {'Error': e.toString()};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Geo Lookup: ${widget.host}',
          style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 13),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _info.entries
                  .map((e) => Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: AppTheme.accent,
                          ),
                          title: Text(
                            e.key,
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            e.value,
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

// ===== Shared Terminal Screen Widget =====
class _TerminalScreen extends StatelessWidget {
  final String title;
  final List<String> lines;
  final bool loading;

  const _TerminalScreen({
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
          itemBuilder: (_, i) {
            final line = lines[i];
            Color color = const Color(0xFF58A6FF);
            if (line.contains('OPEN')) color = Colors.greenAccent;
            if (line.contains('Error') || line.contains('closed')) {
              color = Colors.grey[600]!;
            }
            if (line.contains('complete') || line.contains('statistics')) {
              color = Colors.yellowAccent;
            }
            return Text(
              line,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                color: color,
                height: 1.5,
              ),
            );
          },
        ),
      ),
    );
  }
}
