import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _overlayGranted = false;
  bool _overlayActive = false;

  final DatabaseService _db = DatabaseService();

  int _savedCount = 0;
  List<Map<String, dynamic>> _history = [];

  static const Color kGreen = Color(0xFF00FF88);
  static const Color kRed = Color(0xFFFF2244);
  static const Color kGold = Color(0xFFFFD700);
  static const Color kBg = Color(0xFF020408);
  static const Color kPanel = Color(0xFF080D16);

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadHistory();
  }

  Future<void> _checkPermissions() async {
    try {
      final granted =
          await FlutterOverlayWindow.isPermissionGranted();

      if (!mounted) return;

      setState(() {
        _overlayGranted = granted;
      });
    } catch (e) {
      debugPrint('Permission check error: $e');
    }
  }

  Future<void> _requestOverlay() async {
    try {
      await FlutterOverlayWindow.requestPermission();
      await _checkPermissions();
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  Future<void> _toggleOverlay() async {
    try {
      if (!_overlayGranted) {
        await _requestOverlay();
        return;
      }

      final active =
          await FlutterOverlayWindow.isActive();

      if (active) {
        await FlutterOverlayWindow.closeOverlay();

        if (!mounted) return;

        setState(() {
          _overlayActive = false;
        });
      } else {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          height: 72,
          width: 72,
          alignment: OverlayAlignment.centerRight,
          flag: OverlayFlag.defaultFlag,
          overlayTitle: 'MR KOKO',
          overlayContent: 'MR KOKO Signal Pro',
          visibility:
              NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
        );

        if (!mounted) return;

        setState(() {
          _overlayActive = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('OVERLAY ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _overlayActive = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Overlay error: $e'),
        ),
      );
    }
  }

  Future<void> _loadHistory() async {
    try {
      await _db.init();

      final count = await _db.getSignalCount();
      final history = await _db.getSignals(limit: 30);

      if (!mounted) return;

      setState(() {
        _savedCount = count;
        _history = history;
      });
    } catch (e) {
      debugPrint('History error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildPermissionCard(),
                    const SizedBox(height: 12),
                    _buildHowToCard(),
                    const SizedBox(height: 12),
                    _buildStatsCard(),
                    if (_history.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildHistoryCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
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
                    size: 28,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'MR KOKO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'SIGNAL PRO',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$_savedCount',
                style: const TextStyle(
                  color: kGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'SAVED',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard() {
    return _card(
      'PERMISSIONS',
      [
        Row(
          children: [
            Icon(
              _overlayGranted
                  ? Icons.check_circle
                  : Icons.cancel,
              color:
                  _overlayGranted ? kGreen : kRed,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Display over other apps',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            if (!_overlayGranted)
              ElevatedButton(
                onPressed: _requestOverlay,
                child: const Text('GRANT'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHowToCard() {
    return _card(
      'FLOATING ICON',
      [
        const Text(
          'Launch the floating MR KOKO icon.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _toggleOverlay,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _overlayActive ? kRed : kGreen,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
              _overlayActive
                  ? 'HIDE FLOATING ICON'
                  : 'LAUNCH FLOATING ICON',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final buyCount = _history
        .where((e) => e['direction'] == 'buy')
        .length;

    final sellCount = _history
        .where((e) => e['direction'] == 'sell')
        .length;

    return _card(
      'SIGNAL STATS',
      [
        Row(
          children: [
            _statBox(
              'TOTAL',
              '$_savedCount',
              kGold,
            ),
            const SizedBox(width: 8),
            _statBox(
              'BUY',
              '$buyCount',
              kGreen,
            ),
            const SizedBox(width: 8),
            _statBox(
              'SELL',
              '$sellCount',
              kRed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statBox(
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return _card(
      'SIGNAL HISTORY',
      _history.take(10).map((item) {
        final isBuy =
            item['direction'] == 'buy';

        return ListTile(
          dense: true,
          leading: Icon(
            isBuy
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            color: isBuy ? kGreen : kRed,
          ),
          title: Text(
            isBuy ? 'BUY' : 'SELL',
            style: TextStyle(
              color: isBuy ? kGreen : kRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${item['timeframe'] ?? ''} · ${item['rule'] ?? ''}',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _card(
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF152030),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
