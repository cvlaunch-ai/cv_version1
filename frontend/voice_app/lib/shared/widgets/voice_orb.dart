import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceOrb extends StatefulWidget {
  final bool isListening;
  const VoiceOrb({super.key, this.isListening = false});

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double orbSize = 280;
    return SizedBox(
      width: 600,
      height: orbSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _waveCtrl,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(600, orbSize),
                painter: _WaveMeshPainter(
                  progress: _waveCtrl.value,
                  cyanColor: const Color(0xFF00D8F0),
                  pinkColor: const Color(0xFFFF2D8A),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              return Container(
                width: orbSize - 40,
                height: orbSize - 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00D8F0).withOpacity(0.8 + (_pulseCtrl.value * 0.2)),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D8F0).withOpacity(0.3 + (_pulseCtrl.value * 0.2)),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WaveMeshPainter extends CustomPainter {
  final double progress;
  final Color cyanColor;
  final Color pinkColor;

  _WaveMeshPainter({required this.progress, required this.cyanColor, required this.pinkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double width = size.width;
    final double p = progress * 2 * 3.14159;

    // Cyan Waves
    for (int i = 0; i < 12; i++) {
      final double amp = 40 + (i * 5);
      final double freq = 1.2 + (i * 0.05);
      final double phase = p + (i * 0.2);
      _drawWave(canvas, size, midY, amp, freq, phase, cyanColor.withOpacity(0.1 + (i * 0.02)));
    }

    // Pink Waves
    for (int i = 0; i < 8; i++) {
      final double amp = 30 + (i * 8);
      final double freq = 1.5 + (i * 0.1);
      final double phase = p + 3.14 + (i * 0.3);
      _drawWave(canvas, size, midY, amp, freq, phase, pinkColor.withOpacity(0.08 + (i * 0.02)));
    }
  }

  void _drawWave(Canvas canvas, Size size, double midY, double amp, double freq, double phase, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    for (double x = 0; x <= size.width; x += 2) {
      double envelope = 1.0 - (2 * (x / size.width - 0.5)).abs();
      envelope = envelope * envelope; 

      final double y = midY + math.sin((x / size.width * 2 * 3.14 * freq) + phase) * amp * envelope;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
