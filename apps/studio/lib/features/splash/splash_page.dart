import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';

/// Intro splash: the Studio logo fades in (ease-in), holds, then fades out
/// (ease-out), then the router takes over (gated on `session.splashDone`).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 35,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
  ]).animate(_c);

  late final Animation<double> _scale = Tween(
    begin: 0.92,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_c);

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(appSessionProvider).completeSplash();
      }
    });
    if (reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(appSessionProvider).completeSplash(),
      );
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/logo/artlavka_studio_logo.png',
              width: 240,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
