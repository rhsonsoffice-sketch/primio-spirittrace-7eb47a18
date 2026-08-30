import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class TimelineConnector extends StatelessWidget {
  final bool hasResponse;
  final bool isFirst;
  final bool isLast;
  final Widget child;

  const TimelineConnector({
    super.key,
    required this.hasResponse,
    this.isFirst = false,
    this.isLast = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final dotColor = hasResponse ? appColors.glowSecondary : colors.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: AppTheme.spacingXl,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: AppTheme.borderDefault,
                      color: colors.outline.withOpacity(0.2),
                    ),
                  ),
                Container(
                  width: AppTheme.spacingSm,
                  height: AppTheme.spacingSm,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: hasResponse
                        ? [
                            BoxShadow(
                              color: dotColor.withOpacity(0.5),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: AppTheme.borderDefault,
                      color: colors.outline.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
