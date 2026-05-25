import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DecorativeBackground extends StatelessWidget {
  final Widget child;
  final bool showTopLeftBubble;
  final bool showBottomRightBubble;
  final bool showTopRightBubble;
  final bool showBottomLeftBubble;

  const DecorativeBackground({
    super.key,
    required this.child,
    this.showTopLeftBubble = true,
    this.showBottomRightBubble = true,
    this.showTopRightBubble = false,
    this.showBottomLeftBubble = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(
          color: AppTheme.lightBackground,
        ),
        // Top-left purple bubble
        if (showTopLeftBubble)
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bubblePurple.withValues(alpha: 0.4),
              ),
            ),
          ),
        // Top-right purple bubble
        if (showTopRightBubble)
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bubblePurple.withValues(alpha: 0.4),
              ),
            ),
          ),
        // Bottom-right green bubble
        if (showBottomRightBubble)
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bubbleGreen.withValues(alpha: 0.4),
              ),
            ),
          ),
        // Bottom-left green bubble
        if (showBottomLeftBubble)
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bubbleGreen.withValues(alpha: 0.4),
              ),
            ),
          ),
        // Content
        child,
      ],
    );
  }
}
