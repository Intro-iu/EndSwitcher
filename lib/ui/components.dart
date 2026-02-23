import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// 终末地风格按钮
/// 固定大小，内带黑色描边，左侧细线(两端带圆点)自适应，右对齐文字与无底色图标
/// 中右侧背景绘有灰色等高线纹理
/// 确认状态 (isPrimary=true) 是黄色，取消状态 (isPrimary=false) 是白色，前景色均使用黑色
/// 按住时整体变暗
class EndfieldButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const EndfieldButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isPrimary = true,
  });

  @override
  State<EndfieldButton> createState() => _EndfieldButtonState();
}

class _EndfieldButtonState extends State<EndfieldButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary ? EndfieldColors.primary : Colors.white;
    const fgColor = Colors.black;
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 180,
          height: 36,
          decoration: BoxDecoration(
            color: _isPressed
                ? Color.lerp(bgColor, Colors.black, 0.15)!
                : bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (widget.isPrimary && !_isPressed)
                BoxShadow(
                  color: EndfieldColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            children: [
              // 中右侧灰色等高线纹理
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CustomPaint(painter: _ButtonContourPainter()),
                ),
              ),
              // 按钮内部靠近边缘的黑色描边线框
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: fgColor, width: 1.2),
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                ),
              ),
              // 内容居中排列
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Row(
                    children: [
                      // 左侧带圆点端点的细线
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, left: 4),
                          child: CustomPaint(
                            painter: _DottedLinePainter(color: fgColor),
                            size: const Size(double.infinity, 6),
                          ),
                        ),
                      ),
                      // 文字靠右对齐
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: fgColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 最右侧无底色无边框图标
                      Icon(widget.icon, color: fgColor, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 左侧细线：两端带小圆点，中间连一条极细线
class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const dotRadius = 1.2;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 左端小圆点
    canvas.drawCircle(Offset(dotRadius, y), dotRadius, dotPaint);
    // 右端小圆点
    canvas.drawCircle(Offset(size.width - dotRadius, y), dotRadius, dotPaint);
    // 中间连线
    canvas.drawLine(
      Offset(dotRadius * 2 + 1, y),
      Offset(size.width - dotRadius * 2 - 1, y),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 按钮中右侧背景灰色等高线纹理
class _ButtonContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 以按钮右侧偏上位置为圆心，绘制一系列同心弧线
    final center = Offset(size.width * 0.78, size.height * 0.35);
    for (double r = 8; r < 50; r += 6) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -pi * 0.6,
        pi * 0.8,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 带有轴测图传送带指引、箭头流动效果的工业风背景
class AnimatedIndustrialBackground extends StatefulWidget {
  final Widget child;
  const AnimatedIndustrialBackground({super.key, required this.child});

  @override
  State<AnimatedIndustrialBackground> createState() =>
      _AnimatedIndustrialBackgroundState();
}

class _AnimatedIndustrialBackgroundState
    extends State<AnimatedIndustrialBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: EndfieldColors.background),
        // 渲染轴测图传送带背景与等高线
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _IsometricTechPainter(_controller.value),
              );
            },
          ),
        ),
        // 前景 UI 装饰：纯白色无边框斜线正方形 (只有右上角保留，加大斜线间距与宽度)
        Positioned(
          top: 32,
          right: 40,
          child: CustomPaint(
            size: const Size(80, 80),
            painter: _ForegroundHachuredSquarePainter(),
          ),
        ),
        // 主内容叠加
        widget.child,
      ],
    );
  }
}

class _ForegroundHachuredSquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // 宽度变大一点点

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    const spacing = 12.0; // 间距变大
    // 从左下往右上斜伸 ///
    for (double i = -size.width; i <= size.width * 2; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.width, 0),
        linePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IsometricTechPainter extends CustomPainter {
  final double progress;

  _IsometricTechPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // 平移到中心，旋转并缩放形成等轴测视角 (Isometric Projection)
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.scale(1.0, 0.5);
    canvas.rotate(pi / 4);

    final techPaint = Paint()
      ..color = EndfieldColors.textSecondary.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 1. 斜线正方形 (///)
    // 在轴测空间中绘制一些带有斜线填充的科幻数据区块
    _drawHachuredSquare(canvas, const Offset(-300, -200), 120);
    _drawHachuredSquare(canvas, const Offset(200, 150), 80);
    _drawHachuredSquare(canvas, const Offset(-100, 400), 160);
    _drawHachuredSquare(canvas, const Offset(350, -350), 100);

    // 2. 细腻的传送细带 (微小的流动箭头与物流正方体)
    final arrowPaint = Paint()
      ..color = EndfieldColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final dimArrowPaint = Paint()
      ..color = EndfieldColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    // 绘制物流箱 (哑光灰色)
    final boxPaintFill = Paint()
      ..color = EndfieldColors.textSecondary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final boxPaintStroke = Paint()
      ..color = EndfieldColors.textSecondary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final boxPaintTopFill = Paint()
      ..color = EndfieldColors.textDark.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const double arrowSpacing = 30.0;
    // 每隔几个箭头放置一个箱子
    const int boxInterval = 6;
    const double boxSize = 24.0; // 在平面里画的方形边长 (因为等下缩放过了会变成正交透视的立方体顶面)
    const double boxHeight = 20.0; // 箱子上升的假象 Z轴 (在Y负向)

    // 在绘图之前我们注意，整个画布已经是等轴测视角：旋转和平移后它是一个平躺的地板。
    // 但是，如果要画具有立体高度的箱子，需要手动抵消平面的旋转或者沿着“向上”轴画。
    // 因为 canvas 目前仅执行了 2D 的平坦变换，要制造 3D 箱子需要在这上面做假的 2.5D 平移。

    // 修正动画回退问题：
    // 我们需要确保位移在经过 boxInterval 个箭头时刚好闭合一个周期，所以这里的偏移距离直接由一个统一的周期长度决定。
    final cycleDistance = boxInterval * arrowSpacing;
    final cycleOffset = progress * cycleDistance;

    // X轴方向极细流动带与箱子
    for (int i = 0; i < 80; i++) {
      double cx = -1500 + (i * arrowSpacing) + cycleOffset;
      double cy = 180.0;

      // 如果碰到了箱子的索引位置，画一个虚拟的立体箱子取代箭头
      if (i % boxInterval == 0) {
        // 保存一下当前状态
        canvas.save();
        canvas.translate(cx, cy);

        // 立方体底面在地板上就是个正方形 (因为当前全局矩阵把正方形拉成了菱形)
        // 顶面就是沿着全局的"屏幕Y"往上偏移
        // 但是当前坐标系已经旋转了 pi/4，屏幕向上的方向在这个坐标系里是向 (-1, -1) 方向延伸。

        final Offset upDir = const Offset(-1, -1) * boxHeight * 0.707 * 2;

        // 顶面路径
        final topPath = Path()
          ..moveTo(-boxSize / 2 + upDir.dx, -boxSize / 2 + upDir.dy)
          ..lineTo(boxSize / 2 + upDir.dx, -boxSize / 2 + upDir.dy)
          ..lineTo(boxSize / 2 + upDir.dx, boxSize / 2 + upDir.dy)
          ..lineTo(-boxSize / 2 + upDir.dx, boxSize / 2 + upDir.dy)
          ..close();

        canvas.drawPath(topPath, boxPaintTopFill);
        canvas.drawPath(topPath, boxPaintStroke);

        // 侧面线条 (连接底面和顶面的四个角)
        final corners = [
          const Offset(-boxSize / 2, -boxSize / 2),
          const Offset(boxSize / 2, -boxSize / 2),
          const Offset(boxSize / 2, boxSize / 2),
          const Offset(-boxSize / 2, boxSize / 2),
        ];

        for (var corner in corners) {
          canvas.drawLine(corner, corner + upDir, boxPaintStroke);
        }

        // 底面
        final bottomPath = Path()
          ..moveTo(-boxSize / 2, -boxSize / 2)
          ..lineTo(boxSize / 2, -boxSize / 2)
          ..lineTo(boxSize / 2, boxSize / 2)
          ..lineTo(-boxSize / 2, boxSize / 2)
          ..close();
        canvas.drawPath(bottomPath, boxPaintFill);

        canvas.restore();
      } else {
        // 画极小的流动箭头
        double s = 5.0;
        final path1 = Path()
          ..moveTo(cx - s, cy - s)
          ..lineTo(cx, cy)
          ..lineTo(cx - s, cy + s);
        canvas.drawPath(path1, arrowPaint);
      }

      // 下方平行的暗色流动带 (普通箭头)
      double ccy = 200.0;
      double s = 5.0;
      final path2 = Path()
        ..moveTo(cx - s, ccy - s)
        ..lineTo(cx, ccy)
        ..lineTo(cx - s, ccy + s);
      canvas.drawPath(path2, dimArrowPaint);
    }

    // Y轴方向极细流动带与箱子
    for (int i = 0; i < 80; i++) {
      double cx = -250.0;
      double cy = 1500 - (i * arrowSpacing) - cycleOffset;

      if (i % boxInterval == 4) {
        // 错开箱子索引
        canvas.save();
        canvas.translate(cx, cy);

        final Offset upDir = const Offset(-1, -1) * boxHeight * 0.707 * 2;

        final topPath = Path()
          ..moveTo(-boxSize / 2 + upDir.dx, -boxSize / 2 + upDir.dy)
          ..lineTo(boxSize / 2 + upDir.dx, -boxSize / 2 + upDir.dy)
          ..lineTo(boxSize / 2 + upDir.dx, boxSize / 2 + upDir.dy)
          ..lineTo(-boxSize / 2 + upDir.dx, boxSize / 2 + upDir.dy)
          ..close();

        canvas.drawPath(topPath, boxPaintTopFill);
        canvas.drawPath(topPath, boxPaintStroke);

        final corners = [
          const Offset(-boxSize / 2, -boxSize / 2),
          const Offset(boxSize / 2, -boxSize / 2),
          const Offset(boxSize / 2, boxSize / 2),
          const Offset(-boxSize / 2, boxSize / 2),
        ];

        for (var corner in corners) {
          canvas.drawLine(corner, corner + upDir, boxPaintStroke);
        }

        final bottomPath = Path()
          ..moveTo(-boxSize / 2, -boxSize / 2)
          ..lineTo(boxSize / 2, -boxSize / 2)
          ..lineTo(boxSize / 2, boxSize / 2)
          ..lineTo(-boxSize / 2, boxSize / 2)
          ..close();
        canvas.drawPath(bottomPath, boxPaintFill);

        canvas.restore();
      } else {
        double s = 5.0;
        final path1 = Path()
          ..moveTo(cx - s, cy + s)
          ..lineTo(cx, cy - s)
          ..lineTo(cx + s, cy + s);
        canvas.drawPath(path1, arrowPaint);
      }
    }

    // 3. 纤细半调点阵 (Halftone dots)
    final dotPaint = Paint()
      ..color = EndfieldColors.textSecondary.withValues(alpha: 0.1);
    // 左上角区域点阵
    for (int i = 0; i < 15; i++) {
      for (int j = 0; j < 15; j++) {
        // 交错排布
        if ((i + j) % 2 != 0) continue;
        canvas.drawCircle(
          Offset(-500.0 + i * 15, -400.0 + j * 15),
          1.0,
          dotPaint,
        );
      }
    }
    // 右下角区域点阵
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 15; j++) {
        if ((i + j) % 2 != 0) continue;
        canvas.drawCircle(
          Offset(400.0 + i * 15, 300.0 + j * 15),
          1.0,
          dotPaint,
        );
      }
    }

    // 中心微弱的同心圆环阵列
    canvas.drawCircle(Offset.zero, 180, techPaint);
    canvas.drawCircle(Offset.zero, 240, techPaint..strokeWidth = 0.5);
    canvas.drawCircle(Offset.zero, 300, techPaint..strokeWidth = 0.2);

    // 极细的十字准星标线
    canvas.drawLine(
      const Offset(-400, 0),
      const Offset(400, 0),
      techPaint..color = EndfieldColors.primary.withValues(alpha: 0.05),
    );
    canvas.drawLine(
      const Offset(0, -400),
      const Offset(0, 400),
      techPaint..color = EndfieldColors.primary.withValues(alpha: 0.05),
    );

    // 恢复绘制灰色等高线图 (Contour lines) (在轴测空间平面上)
    final contourPaint = Paint()
      ..color = EndfieldColors.textSecondary.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final contourPath = Path();
    contourPath.moveTo(-800, -500);
    contourPath.quadraticBezierTo(-400, -800, 0, -300);
    contourPath.quadraticBezierTo(500, 200, 1000, -600);

    contourPath.moveTo(-900, -400);
    contourPath.quadraticBezierTo(-500, -700, -100, -200);
    contourPath.quadraticBezierTo(400, 300, 900, -500);

    contourPath.moveTo(-1000, -300);
    contourPath.quadraticBezierTo(-600, -600, -200, -100);
    contourPath.quadraticBezierTo(300, 400, 800, -400);

    canvas.drawPath(contourPath, contourPaint);

    canvas.restore();

    // 4. 屏幕2D空间的 HUD 对焦框，更为精致
    final hudPaint = Paint()
      ..color = EndfieldColors.textSecondary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final hudAccent = Paint()
      ..color = EndfieldColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const len = 16.0;
    const padding = 32.0;
    final w = size.width;
    final h = size.height;

    // 左上角框与点缀
    canvas.drawPath(
      Path()
        ..moveTo(padding + len, padding)
        ..lineTo(padding, padding)
        ..lineTo(padding, padding + len),
      hudPaint,
    );
    canvas.drawRect(Rect.fromLTWH(padding - 2, padding - 2, 4, 4), hudAccent);

    // 右上角框
    canvas.drawPath(
      Path()
        ..moveTo(w - padding - len, padding)
        ..lineTo(w - padding, padding)
        ..lineTo(w - padding, padding + len),
      hudPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w - padding - 2, padding - 2, 4, 4),
      hudAccent,
    );

    // 左下角框
    canvas.drawPath(
      Path()
        ..moveTo(padding + len, h - padding)
        ..lineTo(padding, h - padding)
        ..lineTo(padding, h - padding - len),
      hudPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(padding - 2, h - padding - 2, 4, 4),
      hudAccent,
    );

    // 右下角框
    canvas.drawPath(
      Path()
        ..moveTo(w - padding - len, h - padding)
        ..lineTo(w - padding, h - padding)
        ..lineTo(w - padding, h - padding - len),
      hudPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w - padding - 2, h - padding - 2, 4, 4),
      hudAccent,
    );
  }

  // 辅助函数：绘制斜线 /// 正方形区块
  void _drawHachuredSquare(Canvas canvas, Offset topLeft, double size) {
    final rectPaint = Paint()
      ..color = EndfieldColors.textSecondary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = EndfieldColors.textSecondary.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, size, size);
    canvas.drawRect(rect, rectPaint);

    canvas.save();
    canvas.clipRect(rect);
    const spacing = 6.0;
    // 从左下往右上斜伸 ///
    for (double i = -size; i <= size * 2; i += spacing) {
      canvas.drawLine(
        Offset(topLeft.dx + i, topLeft.dy + size),
        Offset(topLeft.dx + i + size, topLeft.dy),
        linePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IsometricTechPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 统一的页面标题组件
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 32, color: EndfieldColors.primary),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 48,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: EndfieldColors.primary),
        ),
      ],
    );
  }
}

/// 统一的末日工业风 SnackBar 提示
void showEndfieldSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? EndfieldColors.danger : EndfieldColors.primary,
      content: Text(
        message,
        style: TextStyle(
          color: isError ? Colors.white : EndfieldColors.textDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
