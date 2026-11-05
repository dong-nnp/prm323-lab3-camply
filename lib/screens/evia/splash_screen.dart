import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_tokens.dart';
import '../../theme/splash_tokens.dart';
import '../../viewmodels/startup_view_model.dart';
import '../../widgets/evia_splash_logo.dart';

class EviaSplashScreen extends ConsumerStatefulWidget {
  const EviaSplashScreen({super.key});

  @override
  ConsumerState<EviaSplashScreen> createState() => _EviaSplashScreenState();
}

class _EviaSplashScreenState extends ConsumerState<EviaSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashTokens.duration,
  )..addStatusListener((_) => _scheduleNavigation());
  bool _started = false;
  bool _imageReady = false;
  bool _navigated = false;
  bool _navigationScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_imageReady && !_started) {
      _controller.forward();
      _started = true;
    }
  }

  void _scheduleNavigation() {
    if (!mounted || _navigated || _navigationScheduled || !_imageReady) return;
    if (!_controller.isCompleted) return;
    final destination = ref.read(startupDestinationProvider);
    if (destination == null) return;
    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationScheduled = false;
      if (!mounted || _navigated) return;
      // Recheck after the frame: auth may have changed since the callback queued.
      final current = ref.read(startupDestinationProvider);
      if (current == null) return;
      _navigated = true;
      context.go(current);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _markImageReady() {
    if (_imageReady) return;
    _imageReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_started) {
        _started = true;
        if (MediaQuery.disableAnimationsOf(context)) {
          _controller.value = 1;
        } else {
          _controller.forward();
        }
      }
      _scheduleNavigation();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(startupDestinationProvider, (_, _) => _scheduleNavigation());
    ref.watch(startupDestinationProvider);
    _scheduleNavigation();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.splashBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SplashTokens.logoWidth,
              ),
              child: EviaSplashLogo(
                animation: _controller,
                onReady: _markImageReady,
                reducedMotion: MediaQuery.disableAnimationsOf(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
