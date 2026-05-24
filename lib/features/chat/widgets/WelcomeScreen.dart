import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum_rounded, size: 80, color: primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Chào mừng đến với Pro Chat',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn một đoạn chat hoặc bắt đầu cuộc trò chuyện mới.',
              style: TextStyle(fontSize: 15, color: textColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}