import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

/// Cycles through readiness labels for the app's own subsystems.
/// It never implies that audio is being captured or analysed.
class SystemStatusCycler extends StatefulWidget {
  const SystemStatusCycler({super.key});

  @override
  State<SystemStatusCycler> createState() => _SystemStatusCyclerState();
}

class _SystemStatusCyclerState extends State<SystemStatusCycler> {
  static const _keys = [
    'statusReady',
    'statusScanner',
    'statusAudio',
    'statusPattern',
    'statusListening',
    'statusMemory',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _keys.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey(_index),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppTheme.spacingSm,
            height: AppTheme.spacingSm,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appColors.success,
              boxShadow: [
                BoxShadow(
                  color: appColors.success.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Flexible(
            child: Text(
              context.l10n.t(_keys[_index]),
              textAlign: TextAlign.center,
              style: text.labelMedium?.copyWith(color: appColors.glowSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
