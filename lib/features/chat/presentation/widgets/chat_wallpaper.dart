import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../theme/chat_theme.dart';

/// Subtle doodle-style wallpaper similar to WhatsApp chat background.
class ChatWallpaper extends StatelessWidget {
  final Widget child;

  const ChatWallpaper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: ChatTheme.wallpaper),
      child: CustomPaint(
        painter: _ChatWallpaperPainter(),
        child: child,
      ),
    );
  }
}

class _ChatWallpaperPainter extends CustomPainter {
  static const _icons = [
    Icons.chat_bubble_outline,
    Icons.favorite_border,
    Icons.star_border,
    Icons.shopping_bag_outlined,
    Icons.local_offer_outlined,
    Icons.camera_alt_outlined,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const spacing = 72.0;
    for (var row = 0; row < size.height / spacing + 1; row++) {
      for (var col = 0; col < size.width / spacing + 1; col++) {
        final x = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final y = row * spacing;
        final iconIndex = (row + col) % _icons.length;
        _drawIcon(canvas, Offset(x, y), _icons[iconIndex], paint);
      }
    }
  }

  void _drawIcon(Canvas canvas, Offset center, IconData icon, Paint paint) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 22,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: paint.color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
