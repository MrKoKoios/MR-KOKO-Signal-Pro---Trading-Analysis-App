import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../engine/signal_engine.dart';
import '../services/database_service.dart';

const MethodChannel _channel =
    MethodChannel('com.mrkoko.signalpro/accessibility');

enum OverlayState {
  icon,
  scanning,
  stopped,
  signal,
}

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen>
    with TickerProviderStateMixin {
  OverlayState _state = OverlayState.icon;

  final SignalEngine _engine = SignalEngine();
  final DatabaseService _db = DatabaseService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  Timer? _timer;

  int _frameCount = 0;
  int _logIndex = 0;

  String _message = 'Tap the icon to start';

  SignalResult? _lastSignal;

  String _selectedTF = '1M';

  bool _showTimeframes = false;

  static const Color green = Color(0xFF00FF88);
  static const Color red = Color(0xFFFF2244);
  static const Color gold = Color(0xFFFFD700);
  static const Color background = Color(0xFF020408);

  final List<String> _messages = [
    'Scanning market structure...',
    'SMC: Order Block detected',
    'ICT: FVG identified',
    'BOS confirmed',
    'OTC pattern scanning...',
    'Support level detected',
    'Liquidity sweep detected',
    'Price Action scanning...',
    'CHoCH detected',
    'Demand zone scanning...',
    'Multi-TF confluence checking...',
    'Smart money footprint scanning...',
  ];

  int get _screenWidth =>
      (ui.window.physicalSize.width / ui.window.devicePixelRatio)
          .toInt();

  int get _screenHeight =>
      (ui.window.physicalSize.height / ui.window.devicePixelRatio)
          .toInt();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(_pulseController);

    _db.init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    try {
      await FlutterOverlayWindow.resizeOverlay(
        _screenWidth,
        _screenHeight,
        true,
      );

      if (!mounted) return;

      setState(() {
        _state = OverlayState.scanning;
        _frameCount = 0;
        _message = 'Starting scanner...';
      });

      await _startScanning();
    } catch (e) {
      debugPrint('OPEN SCANNER ERROR: $e');

      if (!mounted) return;

      setState(() {
        _message = 'Scanner error';
      });
    }
  }

  Future<void> _startScanning() async {
    _timer?.cancel();

    _engine.clear();

    try {
      await _channel.invokeMethod('startScan');
    } catch (e) {
      debugPrint('START SCAN CHANNEL ERROR: $e');
    }

    _timer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) {
        if (!mounted) return;

        setState(() {
          _frameCount++;
          _message =
              _messages[_logIndex % _messages.length];
          _logIndex++;
        });
      },
    );
  }

  Future<void> _stopScanning() async {
    _timer?.cancel();

    try {
      await _channel.invokeMethod('stopScan');
    } catch (e) {
      debugPrint('STOP SCAN CHANNEL ERROR: $e');
    }

    if (!mounted) return;

    setState(() {
      _state = OverlayState.stopped;
      _message =
          'Scan complete — $_frameCount frames analysed';
    });
  }

  void _showSignalPicker() {
    if (_state != OverlayState.stopped) return;

    setState(() {
      _showTimeframes = true;
    });
  }

  void _generateSignal(String timeframe) {
    _showTimeframes = false;

    try {
      final result =
          _engine.generateSignal(timeframe);

      _lastSignal = result;

      _db.saveSignal(result);

      if (!mounted) return;

      setState(() {
        _selectedTF = timeframe;
        _state = OverlayState.signal;
      });
    } catch (e) {
      debugPrint('SIGNAL ERROR: $e');

      if (!mounted) return;

      setState(() {
        _message = 'Signal generation failed';
      });
    }
  }

  Future<void> _reset() async {
    _timer?.cancel();

    _engine.clear();

    setState(() {
      _showTimeframes = false;
      _frameCount = 0;
      _state = OverlayState.scanning;
      _message = 'Restarting scanner...';
    });

    await _startScanning();
  }

  Future<void> _closePanel() async {
    _timer?.cancel();

    try {
      await _channel.invokeMethod('stopScan');
    } catch (_) {}

    try {
      await FlutterOverlayWindow.resizeOverlay(
        72,
        72,
        true,
      );
    } catch (e) {
      debugPrint('CLOSE PANEL ERROR: $e');
    }

    if (!mounted) return;

    setState(() {
      _showTimeframes = false;
      _state = OverlayState.icon;
      _message = 'Tap the icon to start';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _state == OverlayState.icon
          ? _buildFloatingIcon()
          : _buildScannerPanel(),
    );
  }

  Widget _buildFloatingIcon() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openScanner,
      child: ScaleTransition(
        scale: _pulseAnim,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF050A10),
            border: Border.all(
              color: green,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(.55),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.bolt,
                  color: green,
                  size: 32,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerPanel() {
    return Container(
      color: background,
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _scanArea(),
            ),
            _statusBar(),
            _buttons(),
            if (_showTimeframes) _timeframePicker(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF152030),
          ),
        ),
      ),
      child: Row(
        children: [
          _logo(42),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'MR KOKO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'SIGNAL PRO',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _state == OverlayState.scanning
                ? 'LIVE'
                : _state == OverlayState.stopped
                    ? 'READY'
                    : 'SIGNAL',
            style: TextStyle(
              color:
                  _state == OverlayState.scanning
                      ? green
                      : gold,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _closePanel,
            child: const Icon(
              Icons.close,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanArea() {
    return Stack(
      children: [
        CustomPaint(
          painter: _GridPainter(),
          child: const SizedBox.expand(),
        ),

        if (_state == OverlayState.scanning)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.radar,
                  color: green,
                  size: 70,
                ),
                const SizedBox(height: 16),
                const Text(
                  'ANALYSING',
                  style: TextStyle(
                    color: green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_frameCount frames',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

        if (_state == OverlayState.stopped)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: green,
                  size: 70,
                ),
                SizedBox(height: 15),
                Text(
                  'SCAN COMPLETE',
                  style: TextStyle(
                    color: green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

        if (_state == OverlayState.signal &&
            _lastSignal != null)
          _signalView(),

        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: green,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _signalView() {
    final signal = _lastSignal!;

    final isBuy =
        signal.direction == SignalDirection.buy;

    final color = isBuy ? green : red;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isBuy ? 'BUY' : 'SELL',
            style: TextStyle(
              color: color,
              fontSize: 50,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$_selectedTF CANDLE',
            style: const TextStyle(
              color: gold,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'CONFIDENCE: ${signal.confidence}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 25,
            ),
            child: Text(
              signal.rule,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      color: const Color(0xFF080D16),
      child: Text(
        'FRAMES: $_frameCount',
        style: const TextStyle(
          color: green,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buttons() {
    return Padding(
      padding: const EdgeInsets.all(7),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _button(
                  '▶ ANALYSE',
                  green,
                  Colors.black,
                  _state == OverlayState.signal ||
                          _state == OverlayState.icon
                      ? _reset
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _button(
                  '■ STOP',
                  red,
                  Colors.white,
                  _state == OverlayState.scanning
                      ? _stopScanning
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _button(
            '⚡ GET SIGNAL',
            gold,
            Colors.black,
            _state == OverlayState.stopped
                ? _showSignalPicker
                : null,
          ),
          const SizedBox(height: 5),
          _button(
            '↺ RESET',
            Colors.transparent,
            Colors.white54,
            _reset,
            border: const Color(0xFF243040),
          ),
        ],
      ),
    );
  }

  Widget _button(
    String text,
    Color backgroundColor,
    Color textColor,
    VoidCallback? onTap, {
    Color? border,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .3 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color:
                backgroundColor == Colors.transparent
                    ? Colors.transparent
                    : backgroundColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: border ?? backgroundColor,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeframePicker() {
    const timeframes = [
      '5S',
      '15S',
      '20S',
      '1M',
      '5M',
      '30M',
    ];

    return Container(
      color: const Color(0xFF0A1220),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Text(
            'SELECT TIMEFRAME',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: timeframes.map((tf) {
              return GestureDetector(
                onTap: () => _generateSignal(tf),
                child: Container(
                  width: 85,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF080D16),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                      color: gold,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      tf,
                      style: const TextStyle(
                        color: gold,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _logo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: green,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.bolt,
              color: green,
            );
          },
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          _OverlayScreenState.green.withOpacity(.04)
      ..strokeWidth = 1;

    const step = 28.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
