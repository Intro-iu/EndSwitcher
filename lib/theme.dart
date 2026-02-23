import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EndfieldColors {
  // 基础暗色调
  static const Color background = Color(0xFF141416);
  static const Color surface = Color(0xFF242528);
  static const Color surfaceLight = Color(0xFF383A40);

  // 工业黄/高对比度点缀色
  static const Color primary = Color(0xFFECF007); // 终末地标志性荧光黄
  static const Color primaryDark = Color(0xFFB8BA00); // 终末地黄的暗调
  static const Color accentCyan = Color(0xFF00E6F0); // 少数科幻全息蓝

  // 红色警示
  static const Color danger = Color(0xFFFF3B30);

  // 文字颜色
  static const Color textPrimary = Color(0xFFF3F3F3);
  static const Color textSecondary = Color(0xFF8A8C91);
  static const Color textDark = Color(0xFF0B0B0C);
}

class EndfieldTheme {
  static ThemeData get themeData {
    final baseTextTheme = GoogleFonts.rajdhaniTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: EndfieldColors.background,
      colorScheme: const ColorScheme.dark(
        primary: EndfieldColors.primary,
        surface: EndfieldColors.surface,
        error: EndfieldColors.danger,
        onPrimary: EndfieldColors.textDark,
        onSurface: EndfieldColors.textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      useMaterial3: true,
      cardTheme: const CardThemeData(
        color: EndfieldColors.surface,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EndfieldColors.primary,
          foregroundColor: EndfieldColors.textDark,
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EndfieldColors.primary,
          side: const BorderSide(color: EndfieldColors.primary, width: 2),
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: EndfieldColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: EndfieldColors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: EndfieldColors.textSecondary),
        floatingLabelStyle: TextStyle(color: EndfieldColors.primary),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: EndfieldColors.surface,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
    );
  }
}

// 工业风倒角遮罩容器
class BeveledContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double beveledSize;
  final bool isOutline;

  const BeveledContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.beveledSize = 12.0,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BeveledRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(beveledSize),
        bottomRight: Radius.circular(beveledSize),
      ),
    );

    return Container(
      margin: margin,
      padding: padding,
      decoration: ShapeDecoration(
        color: isOutline ? null : (color ?? EndfieldColors.surface),
        shape: isOutline
            ? shape.copyWith(
                side: BorderSide(
                  color: color ?? EndfieldColors.primary,
                  width: 2,
                ),
              )
            : shape,
      ),
      child: child,
    );
  }
}

// 带有扫描线/工业背景点缀的装饰
class IndustrialBackground extends StatelessWidget {
  final Widget child;
  const IndustrialBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 基础底色
        Container(color: EndfieldColors.background),
        // 装饰性格栅线条 (可使用 CustomPaint 绘制简单的斜线或者点阵)
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(painter: GridPainter()),
          ),
        ),
        // 主内容
        child,
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
