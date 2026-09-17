import 'package:flutter/material.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/app_lock.dart';
import '../l10n/app_language.dart';

/// Covers every screen while the app is locked.
///
/// Sits above the navigator, so a dialog or a pushed screen is covered too.
/// What is underneath stays alive - a half-written diary entry survives a
/// lock - but it is hidden from sight and from the screen reader.
class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.lock, required this.child, super.key});

  final AppLock lock;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.lock.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.lock.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (widget.lock.locked) _ask();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        // Not while the system prompt itself is up: it backgrounds the app,
        // and counting that would lock again the moment it succeeds.
        if (!_asking) widget.lock.wentToBackground();
      case AppLifecycleState.resumed:
        widget.lock.cameBack();
      default:
        break;
    }
  }

  /// Asks once. A cancelled prompt leaves the button, never a loop of
  /// prompts the person cannot get out of.
  Future<void> _ask() async {
    if (_asking || !widget.lock.locked) return;
    _asking = true;
    try {
      await widget.lock.tryUnlock(reason: context.s.unlockReason);
    } finally {
      _asking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.lock.locked;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: locked,
          child: TickerMode(enabled: !locked, child: widget.child),
        ),
        if (locked) _LockedScreen(onUnlock: _ask),
      ],
    );
  }
}

class _LockedScreen extends StatelessWidget {
  const _LockedScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    return Material(
      color: theme.colors.bg,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: theme.colors.inkMuted),
              const SizedBox(height: VitalsSpacing.lg),
              Text(context.s.locked, style: theme.typography.title),
              const SizedBox(height: VitalsSpacing.xl),
              FilledButton(
                onPressed: onUnlock,
                child: Text(context.s.unlock),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
