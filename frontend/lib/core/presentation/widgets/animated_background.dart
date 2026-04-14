import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:togli_app/app/theme/app_colors.dart';

class _Node {
  double x, y, vx, vy;
  final double r;
  bool on;
  double nextToggleTime;
  final Color color;

  _Node({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.on,
    required this.nextToggleTime,
    required this.color,
  });
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late List<_Node> _nodes;
  final Random _rng = Random();
  double _time = 0;

  static const _colors = [
    AppColors.coral,
    AppColors.teal,
    AppColors.green,
    AppColors.purple,
    AppColors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(100, (i) => _Node(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      vx: (_rng.nextDouble() - 0.5) * 0.0004,
      vy: (_rng.nextDouble() - 0.5) * 0.0004,
      r: 3.5 + _rng.nextDouble() * 4.5,
      on: _rng.nextBool(),
      nextToggleTime: 2 + _rng.nextDouble() * 6,
      color: _colors[i % _colors.length],
    ));
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    _time = elapsed.inMilliseconds / 1000.0;
    for (var n in _nodes) {
      n.x += n.vx;
      n.y += n.vy;
      if (n.x < -0.05) n.x = 1.05;
      if (n.x > 1.05) n.x = -0.05;
      if (n.y < -0.05) n.y = 1.05;
      if (n.y > 1.05) n.y = -0.05;
      if (_time >= n.nextToggleTime) {
        n.on = !n.on;
        n.nextToggleTime = _time + 3 + _rng.nextDouble() * 5;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _Painter(nodes: _nodes),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final List<_Node> nodes;
  static const _maxDist = 250.0;
  static const _maxDistSq = _maxDist * _maxDist;
  static const _bgColor = Color(0xFFF5F2EB);

  _Painter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Flat solid background — no gradient, no blending, no drift
    canvas.drawColor(_bgColor, BlendMode.src);

    // 2. Lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < nodes.length; i++) {
      final a = nodes[i];
      final ax = a.x * size.width;
      final ay = a.y * size.height;
      for (int j = i + 1; j < nodes.length; j++) {
        final b = nodes[j];
        final dx = ax - b.x * size.width;
        final dy = ay - b.y * size.height;
        final distSq = dx * dx + dy * dy;
        if (distSq > _maxDistSq) continue;
        final dist = sqrt(distSq);
        final alpha = (1.0 - dist / _maxDist) * 0.12;
        linePaint.color = Color.fromRGBO(45, 48, 71, alpha);
        canvas.drawLine(
          Offset(ax, ay),
          Offset(b.x * size.width, b.y * size.height),
          linePaint,
        );
      }
    }

    // 3. Nodes
    final nodePaint = Paint();
    for (var n in nodes) {
      nodePaint.color = n.on
          ? n.color.withOpacity(0.5)
          : const Color.fromRGBO(45, 48, 71, 0.06);
      canvas.drawCircle(
        Offset(n.x * size.width, n.y * size.height),
        n.r,
        nodePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
