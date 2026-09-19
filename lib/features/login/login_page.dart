import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/errors/app_exception.dart';
import '../../services/auth_service.dart';
import '../../widgets/dv_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _auth = AuthService();
  bool _isLoading = false;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _auth.signInWithGoogle();
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dv.obsidian,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dv.s32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  const Center(child: DvLogo(size: 48, showTagline: false)),
                  const SizedBox(height: Dv.s32),

                  // Headline
                  Text(
                    'YOUR SQUAD.',
                    style: Dv.display(size: 36),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'YOUR COMMS.',
                    style: Dv.display(size: 36, color: Dv.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dv.s16),
                  Text(
                    'Crystal-clear voice chat built for\ncompetitive gamers.',
                    style: Dv.body(color: Dv.ash, size: 15),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // Error
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(Dv.s12),
                      decoration: BoxDecoration(
                        color: Dv.crimson.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dv.r8),
                        border: Border.all(color: Dv.crimson.withValues(alpha: 0.4)),
                      ),
                      child: Text(_error!, style: Dv.body(color: Dv.crimson, size: 13), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: Dv.s16),
                  ],

                  // Google Sign-In Button
                  _GoogleButton(onPressed: _isLoading ? null : _signInWithGoogle, isLoading: _isLoading),

                  const SizedBox(height: Dv.s24),

                  Text(
                    'By continuing, you agree to DROPVOICE\'s\nTerms of Service and Privacy Policy.',
                    style: Dv.mono(size: 10, color: Dv.slate),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Dv.white,
          foregroundColor: Dv.obsidian,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dv.r12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Dv.obsidian),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" icon
                  const _GoogleIcon(),
                  const SizedBox(width: Dv.s12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Dv.obsidian,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Simplified Google G
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -1.57, 4.71, true, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 1.57, 1.57, true, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 3.14, 1.57, true, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -1.57, 1.57, true, paint);

    // White center
    paint.color = Colors.white;
    canvas.drawCircle(center, r * 0.65, paint);

    // Blue bar (the G cutout)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - r * 0.2, r * 0.9, r * 0.4),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
