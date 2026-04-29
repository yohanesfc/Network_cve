import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';

class PingResultScreen extends StatefulWidget {
  final String host;
  final String pingType;

  const PingResultScreen({
    super.key,
    required this.host,
    required this.pingType,
  });

  @override
  State<PingResultScreen> createState() => _PingResultScreenState();
}

class _PingResultScreenState extends State<PingResultScreen> {
  final List<String> _lines = [];
  bool _running = true;
  StreamSubscription<PingData>? _pingSubscription;

  @override
  void initState() {
    super.initState();
    _startPing();
  }

  Future<void> _startPing() async {
    final ping = Ping(widget.host, count: 10);
    _addLine('PING ${widget.host} (${widget.pingType})');
    _addLine('');

    _pingSubscription = ping.stream.listen(
      (event) {
        if (event.error != null) {
          _addLine('Error: ${event.error}');
        } else if (event.response != null) {
          final r = event.response!;
          _addLine(
            '${r.seq != null ? 'icmp_seq=${r.seq}' : ''} '
            'time=${r.time?.inMilliseconds ?? '?'}ms '
            'ttl=${r.ttl ?? '?'}',
          );
        } else if (event.summary != null) {
          final s = event.summary!;
          _addLine('');
          _addLine('--- ${widget.host} ping statistics ---');
          final lost = s.transmitted - s.received;
          _addLine(
            '${s.transmitted} packets transmitted, ${s.received} received, '
            '$lost lost',
          );
          if (s.time != null) {
            _addLine('rtt min/avg/max = '
                '${s.time?.inMilliseconds ?? '-'}ms');
          }
          if (mounted) {
            setState(() => _running = false);
          }
        }
      },
      onError: (e) {
        _addLine('Error: $e');
        if (mounted) {
          setState(() => _running = false);
        }
      },
      onDone: () {
        if (mounted) {
          setState(() => _running = false);
        }
      },
    );
  }

  void _addLine(String line) {
    if (!mounted) return;
    setState(() => _lines.add(line));
  }

  @override
  void dispose() {
    _pingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ping: ${widget.host}',
          style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 14),
        ),
        actions: [
          if (_running)
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
        color: isDark ? Colors.black : const Color(0xFF1A1A1A),
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemCount: _lines.length,
          itemBuilder: (_, i) => Text(
            _lines[i],
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              color: _lines[i].contains('Error')
                  ? Colors.red[400]
                  : _lines[i].contains('statistics')
                      ? Colors.yellow[400]
                      : Colors.green[400],
            ),
          ),
        ),
      ),
    );
  }
}
