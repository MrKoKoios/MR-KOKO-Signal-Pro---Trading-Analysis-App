import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../engine/signal_engine.dart';
import '../services/database_service.dart';

const _channel =
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

  late AnimationController _scanController;
  late AnimationController _pulseController;

  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;

  Timer? _logTimer;

  int _frameCount = 0;
  int _logIdx = 0;

  String _logMsg = 'Initialising scanner...';

  SignalResult? _lastSignal;

  String _selectedTF = '1M';

  bool _showTFPicker = false;

  static const Color kGreen = Color(0xFF00FF88);
  static const Color kRed = Color(0xFFFF2244);
  static const Color kGold = Color(0xFFFFD700);
  static const Color kBg = Color(0xFF020408);
  static const Color kPanel = Color(0xFF080D16);

  final List<String> _logs = [
    'Scanning market structure...',
    'SMC: Order Block detected',
    'ICT: FVG identified',
    'BOS confirmed on chart',
    'OTC AI pattern: reversal zone',
    'Support level mapped',
    'Liquidity sweep above high',
    'Price Action: Engulfing forming',
    'CHoCH detected — shift in structure',
    'OB Mitigation in progress...',
    'Demand zone: accumulation',
    'Multi-TF confluence: strong',
    'OTC volatility scan...',
    'Smart money footprint found',
    'Fibonacci 61.8% touch confirmed',
  ];

  int get _screenW =>
      (ui.window.physicalSize.width /
              ui.window.devicePixelRatio)
          .toInt();

  int get _screenH =>
      (ui.window.physicalSize.height /
              ui.window.devicePixelRatio)
          .toInt();

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scanAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_scanController);

    _pulseAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(_pulseController);

    _db.init();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _logTimer?.cancel();
    super.dispose();
  }

  Future<void> _expand() async {
    try {
      setState(() {
        _state = OverlayState.scanning;
      });

      await FlutterOverlayWindow.resizeOverlay(
        _screenW,
        _screenH,
        true,
      );

      await _startScan();
    } catch (e) {
      debugPrint('Expand error: $e');
    }
  }

  Future<void> _startScan() async {
    _frameCount = 0;
    _logIdx = 0;

    _engine.clear();

    try {
      await _channel.invokeMethod('startScan');
    } catch (e) {
      debugPrint(
        'Accessibility not connected: $e',
      );
    }

    _logTimer?.cancel();

    _logTimer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) {
        if (!mounted) return;

        setState(() {
          _logMsg =
              _logs[_logIdx % _logs.length];

          _logIdx++;
          _frameCount++;
        });
      },
    );
  }

  Future<void> _stopScan() async {
    _logTimer?.cancel();

    try {
      await _channel.invokeMethod('stopScan');
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _state = OverlayState.stopped;

      _logMsg =
          '✓ Scan complete — $_frameCount frames analysed';
    });
  }

  void _getSignal() {
    if (_showTFPicker) return;

    setState(() {
      _showTFPicker = true;
    });
  }

  void _pickTF(String tf) {
    _showTFPicker = false;

    final result =
        _engine.generateSignal(tf);

    _lastSignal = result;

    _db.saveSignal(result);

    setState(() {
      _state = OverlayState.signal;
      _selectedTF = tf;
    });
  }

  Future<void> _collapse() async {
    _logTimer?.cancel();

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
      debugPrint('Collapse error: $e');
    }

    if (!mounted) return;

    setState(() {
      _state = OverlayState.icon;
    });
  }

  Future<void> _reset() async {
    _logTimer?.cancel();

    _engine.clear();

    _frameCount = 0;
    _showTFPicker = false;

    setState(() {
      _state = OverlayState.scanning;
    });

    await _startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _state == OverlayState.icon
          ? _buildIcon()
          : _buildPanel(),
    );
  }

  Widget _buildIcon() {
    return GestureDetector(
      onTap: _expand,
      child: ScaleTransition(
        scale: _pulseAnim,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: kGreen,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: kGreen.withOpacity(.5),
                blurRadius: 16,
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
                  color: kGreen,
                  size: 30,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      color: kBg,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: _buildScanArea(),
            ),

            _buildStats(),

            _buildButtons(),

            if (_showTFPicker)
              _buildTFPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF152030),
          ),
        ),
      ),
      child: Row(
        children: [
          _logo(44),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'MR KOKO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'SIGNAL PRO · SCREEN SCAN',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white38,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color:
                    _state ==
                            OverlayState.scanning
                        ? kGreen
                        : Colors.white24,
              ),
            ),
            child: Text(
              _state ==
                      OverlayState.scanning
                  ? 'LIVE'
                  : _state ==
                          OverlayState.stopped
                      ? 'READY'
                      : _state ==
                              OverlayState.signal
                          ? 'SIGNAL'
                          : 'IDLE',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                color:
                    _state ==
                            OverlayState.scanning
                        ? kGreen
                        : Colors.white38,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: _collapse,
            child: const Icon(
              Icons.close,
              color: Colors.white38,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanArea() {
    return Stack(
      children: [
        CustomPaint(
          painter: _GridPainter(),
          child: const SizedBox.expand(),
        ),

        if (_state == OverlayState.scanning)
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (ctx, _) {
              final width =
                  MediaQuery.of(ctx).size.width;

              return Positioned(
                left:
                    _scanAnim.value *
                        (width - 6),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: kGreen,
                    boxShadow: [
                      BoxShadow(
                        color:
                            kGreen.withOpacity(.8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        if (_state == OverlayState.signal &&
            _lastSignal != null)
          _buildSignalOverlay(),

        ..._corners(),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            color: Colors.black87,
            child: Text(
              '[ ${_frameCount * 3} frames ] $_logMsg',
              style: const TextStyle(
                fontSize: 10,
                color: kGreen,
                letterSpacing: 1,
                fontFamily: 'monospace',
              ),
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalOverlay() {
    final signal = _lastSignal!;

    final isBuy =
        signal.direction ==
            SignalDirection.buy;

    final color =
        isBuy ? kGreen : kRed;

    return Container(
      color: Colors.black.withOpacity(.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBuy ? 'BUY' : 'SELL',
              style: TextStyle(
                fontSize: 52,
                fontWeight:
                    FontWeight.w900,
                color: color,
                letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '$_selectedTF CANDLE',
              style: const TextStyle(
                fontSize: 13,
                color: kGold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'CONFIDENCE: ${signal.confidence}%',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              signal.rule,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white38,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '✓ SAVED TO HISTORY',
              style: TextStyle(
                fontSize: 10,
                color: kGreen,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    const labels = [
      'SMC',
      'ICT',
      'PA',
      'OTC',
      'S&R',
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 6,
        ),
        itemCount: labels.length,
        itemBuilder: (_, index) {
          return Container(
            margin:
                const EdgeInsets.only(
              right: 6,
              top: 4,
              bottom: 4,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(8),
              border: Border.all(
                color: kGreen,
              ),
              color:
                  kGreen.withOpacity(.07),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  labels[index],
                  style: const TextStyle(
                    fontSize: 9,
                    color: kGreen,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  index.isEven
                      ? 'BULL'
                      : 'BEAR',
                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                    color: kGreen,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        6,
        0,
        6,
        8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _btn(
                  '▶ ANALYSE',
                  kGreen,
                  Colors.black,
                  _state ==
                              OverlayState.icon ||
                          _state ==
                              OverlayState.signal
                      ? _reset
                      : null,
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: _btn(
                  '■ STOP',
                  kRed,
                  Colors.white,
                  _state ==
                          OverlayState.scanning
                      ? _stopScan
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          _btn(
            '⚡ GET SIGNAL',
            kGold,
            Colors.black,
            _state ==
                    OverlayState.stopped
                ? _getSignal
                : null,
          ),

          const SizedBox(height: 4),

          _btn(
            '↺ RESET',
            Colors.transparent,
            Colors.white38,
            _reset,
            border:
                const Color(0xFF152030),
          ),
        ],
      ),
    );
  }

  Widget _btn(
    String label,
    Color bg,
    Color fg,
    VoidCallback? onTap, {
    Color? border,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration:
            const Duration(
          milliseconds: 200,
        ),
        opacity:
            onTap == null ? 0.3 : 1.0,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color:
                bg == Colors.transparent
                    ? Colors.transparent
                    : bg,
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color: border ?? bg,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
                color: fg,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTFPicker() {
    final timeframes = [
      {'tf': '5S', 'label': '5 SEC'},
      {'tf': '15S', 'label': '15 SEC'},
      {'tf': '20S', 'label': '20 SEC'},
      {'tf': '1M', 'label': '1 MIN'},
      {'tf': '5M', 'label': '5 MIN'},
      {'tf': '30M', 'label': '30 MIN'},
    ];

    return Container(
      color: const Color(0xFF0A1220),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const Text(
            'SELECT TIMEFRAME',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              letterSpacing: 2,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: timeframes.length,
            itemBuilder: (_, index) {
              return GestureDetector(
                onTap: () => _pickTF(
                  timeframes[index]['tf']!,
                ),
                child: Container(
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    border: Border.all(
                      color:
                          const Color(
                        0xFF152030,
                      ),
                    ),
                    color: kPanel,
                  ),
                  child: Center(
                    child: Text(
                      timeframes[index]
                          ['label']!,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              );
            },
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
          color: kGreen,
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
              color: kGreen,
            );
          },
        ),
      ),
    );
  }

  List<Widget> _corners() {
    const size = 16.0;
    const thickness = 2.0;

    return [
      Positioned(
        top: 6,
        left: 6,
        child: _corner(
          size,
          thickness,
          kGreen,
          top: true,
          left: true,
        ),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: _corner(
          size,
          thickness,
          kGreen,
          top: true,
          left: false,
        ),
      ),
      Positioned(
        bottom: 30,
        left: 6,
        child: _corner(
          size,
          thickness,
          kGreen,
          top: false,
          left: true,
        ),
      ),
      Positioned(
        bottom: 30,
        right: 6,
        child: _corner(
          size,
          thickness,
          kGreen,
          top: false,
          left: false,
        ),
      ),
    ];
  }

  Widget _corner(
    double size,
    double thickness,
    Color color, {
    required bool top,
    required bool left,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          thickness,
          color,
          top: top,
          left: left,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color =
          kGreen.withOpacity(.04)
      ..strokeWidth = 1;

    const step = 28.0;

    for (
      double x = 0;
      x < size.width;
      x += step
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (
      double y = 0;
      y < size.height;
      y += step
    ) {
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

class _CornerPainter
    extends CustomPainter {
  final double thickness;
  final Color color;
  final bool top;
  final bool left;

  _CornerPainter(
    this.thickness,
    this.color, {
    required this.top,
    required this.left,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (top && left) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
