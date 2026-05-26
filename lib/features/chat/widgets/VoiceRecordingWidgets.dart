import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

// ==========================================
// WIDGET CON: Chấm đỏ nhấp nháy
// ==========================================
class BlinkingDot extends StatefulWidget {
  const BlinkingDot({super.key});

  @override
  State<BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController, 
      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))
    );
  }
}

// ==========================================
// WIDGET CON: Sóng âm tự chế (Waveform)
// ==========================================
class VoiceWaveform extends StatefulWidget {
  final Color primaryColor;
  const VoiceWaveform({super.key, required this.primaryColor});

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform> {
  late Timer _timer;
  final Random _random = Random();
  List<double> _heights = List.generate(30, (index) => 5.0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _heights = List.generate(30, (index) => _random.nextDouble() * 25 + 5);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _heights.map((height) => AnimatedContainer(
          duration: const Duration(milliseconds: 150), 
          width: 4, height: height, 
          decoration: BoxDecoration(color: widget.primaryColor.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4))
        )).toList(),
      ),
    );
  }
}