import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _flashController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();

    // Logo controller — zoom in then mega zoom to fill screen
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Text controller — fade + slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Flash controller — white flash at the end
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Phase 1 (0–40%): logo fades in and scales to normal size
    // Phase 2 (60–100%): logo zooms out massively to cover screen
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 30.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 40,
      ),
    ]).animate(_logoController);

    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_logoController);

    // Text fade + slide up — plays during phase 1 pause
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // White flash fades in as zoom completes
    _flashOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Small delay before starting
    await Future.delayed(const Duration(milliseconds: 300));

    // Start logo animation
    _logoController.forward();

    // Text appears after logo pops in (40% of 2800ms = 1120ms)
    await Future.delayed(const Duration(milliseconds: 900));
    _textController.forward();

    // Wait for zoom-out phase to start, then flash
    await Future.delayed(const Duration(milliseconds: 1400));
    _flashController.forward();

    // Navigate to login
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Stack(
        children: [
          // Animated background rings (pulse effect)
          Center(child: _buildPulseRings()),

          // Main logo zoom
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (_, __) => Transform.scale(
                scale: _logoScale.value,
                child: Opacity(
                  opacity: _logoOpacity.value.clamp(0.0, 1.0),
                  child: _buildLogo(),
                ),
              ),
            ),
          ),

          // Text below logo
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textController,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _textSlide.value),
                  child: _buildText(),
                ),
              ),
            ),
          ),

          // White flash overlay
          AnimatedBuilder(
            animation: _flashController,
            builder: (_, __) => Opacity(
              opacity: _flashOpacity.value,
              child: Container(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() => Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: const Color(0xFF42A5F5).withOpacity(0.6),
              blurRadius: 60,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'assets/logo/logo.png',
            fit: BoxFit.cover,
          ),
          // ✅ Once you have your logo, replace Icon with:
          // Image.asset('assets/logo/logo.png', fit: BoxFit.cover)
        ),
      );

  Widget _buildPulseRings() => AnimatedBuilder(
        animation: _logoController,
        builder: (_, __) {
          // Rings only visible during the hold phase (not during zoom-out)
          final progress = _logoController.value;
          final ringOpacity = progress < 0.6
              ? (progress * 2).clamp(0.0, 0.3)
              : ((1.0 - progress) * 3).clamp(0.0, 0.3);
          return Stack(
            alignment: Alignment.center,
            children: [
              _ring(200, ringOpacity * 0.5),
              _ring(300, ringOpacity * 0.3),
              _ring(400, ringOpacity * 0.15),
            ],
          );
        },
      );

  Widget _ring(double size, double opacity) => Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
          ),
        ),
      );

  Widget _buildText() => Column(
        children: [
          Text(
            'SOLAR MONITOR',
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Smart Energy Management',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 30),
          // Loading dots
          _buildLoadingDots(),
        ],
      );

  Widget _buildLoadingDots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) => _Dot(delay: i * 200)),
      );
}

// Animated bouncing dot
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _anim.value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
}
