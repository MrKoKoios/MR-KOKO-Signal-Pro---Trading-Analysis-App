import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  bool _expanded = false;

  double _screenW = 340;
  double _screenH = 520;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _expand() async {
    try {
      await FlutterOverlayWindow.resizeOverlay(
        _screenW.toInt(),
        _screenH.toInt(),
        true,
      );

      if (!mounted) return;

      setState(() {
        _expanded = true;
      });
    } catch (e) {
      debugPrint('Expand error: $e');
    }
  }

  Future<void> _collapse() async {
    try {
      await FlutterOverlayWindow.resizeOverlay(
        72,
        72,
        true,
      );

      if (!mounted) return;

      setState(() {
        _expanded = false;
      });
    } catch (e) {
      debugPrint('Collapse error: $e');
    }
  }

  Future<void> _close() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('Close overlay error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return Material(
        color: Colors.transparent,
        child: Center(
          child: GestureDetector(
            onTap: _expand,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF020408),
                border: Border.all(
                  color: const Color(0xFF00FF88),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFF00FF88)
                            .withOpacity(.5),
                    blurRadius: 15,
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
                      color: Color(0xFF00FF88),
                      size: 30,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF080D16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00FF88),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _signalButton(),
                    const SizedBox(height: 12),
                    _infoBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'MR KOKO SIGNAL PRO',
              style: TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _collapse,
            icon: const Icon(
              Icons.minimize,
              color: Colors.white70,
            ),
          ),
          IconButton(
            onPressed: _close,
            icon: const Icon(
              Icons.close,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF00FF88),
          foregroundColor: Colors.black,
          padding:
              const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'ANALYSE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _infoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        children: [
          Text(
            'READY',
            style: TextStyle(
              color: Color(0xFF00FF88),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap ANALYSE to start.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
