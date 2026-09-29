Future<void> _toggleOverlay() async {
  try {
    final granted =
        await FlutterOverlayWindow.isPermissionGranted();

    if (!granted) {
      await FlutterOverlayWindow.requestPermission();
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

      return;
    }

    await FlutterOverlayWindow.showOverlay(
      height: 72,
      width: 72,
      alignment: OverlayAlignment.centerRight,
      flag: OverlayFlag.defaultFlag,
      enableDrag: true,
      overlayTitle: 'MR KOKO',
      overlayContent: 'Tap to scan market',
      positionGravity: PositionGravity.auto,
    );

    if (!mounted) return;

    setState(() {
      _overlayActive = true;
    });

    debugPrint('MR KOKO overlay started');

  } catch (e, stackTrace) {
    debugPrint('OVERLAY ERROR: $e');
    debugPrint('$stackTrace');

    if (!mounted) return;

    setState(() {
      _overlayActive = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Overlay failed: $e',
        ),
      ),
    );
  }
}
