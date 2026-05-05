import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

/// The Monolith - A deep focus widget
/// Only one task, one goal. Breathing background for calm.
class TheMonolith extends StatefulWidget {
  final String taskTitle;
  final VoidCallback onComplete;

  const TheMonolith({
    super.key,
    required this.taskTitle,
    required this.onComplete,
  });

  @override
  State<TheMonolith> createState() => _TheMonolithState();
}

class _TheMonolithState extends State<TheMonolith> with SingleTickerProviderStateMixin {
  int _secondsRemaining = 25 * 60; // 25 minutes Pomodoro
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() => _isRunning = !_isRunning);
    if (_isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          timer.cancel();
          widget.onComplete();
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  String _formatTime() {
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The breathing background for the Monolith
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulsating "Breath" layer
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 4000.ms,
                curve: Curves.easeInOutSine,
              ),

              // The Glass Monolith
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius2XLarge),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppTheme.getBlur(BlurDensity.high),
                    sigmaY: AppTheme.getBlur(BlurDensity.high),
                  ),
                  child: Container(
                    width: 280,
                    height: 400,
                    padding: const EdgeInsets.all(AppTheme.spaceXLarge),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radius2XLarge),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CURRENT GOAL',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppTheme.spaceLarge),
                        Text(
                          widget.taskTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 64),
                        Text(
                          _formatTime(),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 54,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 48),
                        GestureDetector(
                          onTap: _toggleTimer,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _isRunning ? Colors.transparent : AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _isRunning ? LucideIcons.pause : LucideIcons.play,
                              color: _isRunning ? AppTheme.primary : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 48),
          
          // Complete Action
          TextButton.icon(
            onPressed: widget.onComplete,
            icon: const Icon(LucideIcons.checkCircle2, size: 18),
            label: const Text('MARK AS DONE'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              textStyle: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }
}
