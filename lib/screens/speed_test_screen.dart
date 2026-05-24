import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen>
    with SingleTickerProviderStateMixin {
  // ── State ───────────────────────────────────────────────────────────────
  _TestStatus _status = _TestStatus.idle;
  double _downloadMbps = 0;
  double _uploadMbps = 0;
  double _pingMs = 0;
  String _log = '';
  double _progress = 0; // 0..1

  late AnimationController _gaugeCtrl;
  late Animation<double> _gaugeAnim;
  double _gaugeTarget = 0;

  // Cloudflare Speed Test endpoints (no API key required)
  static const String _cfBase = 'https://speed.cloudflare.com';
  static const int _downloadBytes = 10 * 1024 * 1024; // 10 MB
  static const int _uploadBytes = 5 * 1024 * 1024;   //  5 MB

  @override
  void initState() {
    super.initState();
    _gaugeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _gaugeAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _gaugeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _gaugeCtrl.dispose();
    super.dispose();
  }

  // ── Animate gauge ───────────────────────────────────────────────────────
  void _animateGauge(double target) {
    _gaugeTarget = target;
    _gaugeAnim = Tween<double>(begin: _gaugeAnim.value, end: target).animate(
        CurvedAnimation(parent: _gaugeCtrl, curve: Curves.easeOut));
    _gaugeCtrl
      ..reset()
      ..forward();
  }

  void _addLog(String msg) {
    setState(() => _log += '$msg\n');
  }

  // ── Run full test ───────────────────────────────────────────────────────
  Future<void> _runTest() async {
    setState(() {
      _status = _TestStatus.running;
      _downloadMbps = 0;
      _uploadMbps = 0;
      _pingMs = 0;
      _progress = 0;
      _log = '';
    });
    _animateGauge(0);

    try {
      // 1. Ping (latency)
      _addLog('📡 Measuring latency...');
      _pingMs = await _measurePing();
      setState(() => _progress = 0.2);
      _addLog('   Latency: ${_pingMs.toStringAsFixed(1)} ms');

      // 2. Download
      _addLog('⬇️  Testing download speed...');
      _downloadMbps = await _measureDownload();
      setState(() {
        _progress = 0.7;
      });
      _animateGauge(_downloadMbps.clamp(0, 200) / 200);
      _addLog(
          '   Download: ${_downloadMbps.toStringAsFixed(2)} Mbps');

      // 3. Upload
      _addLog('⬆️  Testing upload speed...');
      _uploadMbps = await _measureUpload();
      setState(() => _progress = 1.0);
      _addLog('   Upload: ${_uploadMbps.toStringAsFixed(2)} Mbps');

      setState(() => _status = _TestStatus.done);
      _addLog('\n✅ Test complete!');
    } catch (e) {
      _addLog('\n❌ Error: $e');
      setState(() => _status = _TestStatus.error);
    }
  }

  // ── Latency ─────────────────────────────────────────────────────────────
  Future<double> _measurePing() async {
    const int samples = 5;
    double total = 0;
    for (int i = 0; i < samples; i++) {
      final sw = Stopwatch()..start();
      await http.head(Uri.parse('$_cfBase/__down?bytes=0'));
      sw.stop();
      total += sw.elapsedMilliseconds;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return total / samples;
  }

  // ── Download ─────────────────────────────────────────────────────────────
  Future<double> _measureDownload() async {
    final url = Uri.parse('$_cfBase/__down?bytes=$_downloadBytes');
    final sw = Stopwatch()..start();
    final response = await http.get(url);
    sw.stop();
    final bytes = response.bodyBytes.length;
    final seconds = sw.elapsedMilliseconds / 1000.0;
    return (bytes * 8) / (seconds * 1e6); // Mbps
  }

  // ── Upload ───────────────────────────────────────────────────────────────
  Future<double> _measureUpload() async {
    final data = List<int>.generate(_uploadBytes, (i) => i % 256);
    final url = Uri.parse('$_cfBase/__up');
    final sw = Stopwatch()..start();
    await http.post(url, body: data);
    sw.stop();
    final seconds = sw.elapsedMilliseconds / 1000.0;
    return (_uploadBytes * 8) / (seconds * 1e6); // Mbps
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF4DB6C8) : AppTheme.primary;

    return Scaffold(
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Speed Test',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceMono',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.speed, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Gauge ───────────────────────────────────────────────────────
            _buildGauge(color),
            const SizedBox(height: 20),

            // ── Stat cards ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                  label: 'Download',
                  value: _downloadMbps > 0
                      ? _downloadMbps.toStringAsFixed(1)
                      : '--',
                  unit: 'Mbps',
                  icon: Icons.arrow_downward,
                  color: color,
                  isDark: isDark,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                  label: 'Upload',
                  value:
                      _uploadMbps > 0 ? _uploadMbps.toStringAsFixed(1) : '--',
                  unit: 'Mbps',
                  icon: Icons.arrow_upward,
                  color: AppTheme.accent,
                  isDark: isDark,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                  label: 'Latency',
                  value: _pingMs > 0 ? _pingMs.toStringAsFixed(0) : '--',
                  unit: 'ms',
                  icon: Icons.network_ping,
                  color: const Color(0xFF9C27B0),
                  isDark: isDark,
                )),
              ],
            ),
            const SizedBox(height: 20),

            // ── Progress bar ────────────────────────────────────────────────
            if (_status == _TestStatus.running) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Start button ─────────────────────────────────────────────────
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _status == _TestStatus.running ? null : _runTest,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _status == _TestStatus.running
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF006B7A), Color(0xFF00838F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: _status == _TestStatus.running
                        ? (isDark ? Colors.grey[800] : Colors.grey[300])
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _status == _TestStatus.running
                        ? null
                        : [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_status == _TestStatus.running)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.play_arrow, color: Colors.white,
                            size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _status == _TestStatus.running
                            ? 'Testing...'
                            : _status == _TestStatus.done
                                ? 'Run Again'
                                : 'Start Speed Test',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'SpaceMono',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Info note ───────────────────────────────────────────────────
            const SizedBox(height: 12),
            Text(
              'Powered by Cloudflare Speed Test\nResults may vary by network conditions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),

            // ── Log ─────────────────────────────────────────────────────────
            if (_log.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  _log.trim(),
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Gauge widget ──────────────────────────────────────────────────────────
  Widget _buildGauge(Color color) {
    return AnimatedBuilder(
      animation: _gaugeAnim,
      builder: (_, __) {
        return Center(
          child: SizedBox(
            width: 220,
            height: 120,
            child: CustomPaint(
              painter: _GaugePainter(
                progress: _gaugeAnim.value,
                color: color,
                accent: AppTheme.accent,
              ),
              child: Align(
                alignment: const Alignment(0, 0.6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _status == _TestStatus.idle
                          ? '—'
                          : _status == _TestStatus.running
                              ? _downloadMbps > 0
                                  ? _downloadMbps.toStringAsFixed(1)
                                  : '...'
                              : _downloadMbps.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      'Mbps Download',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Gauge painter ─────────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final Color accent;

  const _GaugePainter(
      {required this.progress, required this.color, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.9;
    final radius = size.width * 0.48;
    const startAngle = 3.14159; // π  (left)
    const sweepFull = 3.14159;  // π  (half circle)

    // Background arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepFull,
      false,
      bgPaint,
    );

    // Filled arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..shader = LinearGradient(
          colors: [color, accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepFull * progress,
        false,
        fgPaint,
      );
    }

    // Tick marks
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 10; i++) {
      final angle = 3.14159 + (3.14159 * i / 10);
      final cos = _cos(angle);
      final sin = _sin(angle);
      canvas.drawLine(
        Offset(cx + (radius - 8) * cos, cy + (radius - 8) * sin),
        Offset(cx + (radius + 2) * cos, cy + (radius + 2) * sin),
        tickPaint,
      );
    }
  }

  double _cos(double a) => a == 3.14159 ? -1 : (a == 0 ? 1 : _approxCos(a));
  double _sin(double a) => _approxSin(a);
  double _approxCos(double a) => _approxSin(a + 1.5708);
  double _approxSin(double a) {
    // Bhaskara I approximation
    a = a % 6.28318;
    if (a < 0) a += 6.28318;
    final b = a > 3.14159 ? a - 3.14159 : a;
    final s = (16 * b * (3.14159 - b)) / (5 * 3.14159 * 3.14159 - 4 * b * (3.14159 - b));
    return a > 3.14159 ? -s : s;
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TestStatus { idle, running, done, error }
