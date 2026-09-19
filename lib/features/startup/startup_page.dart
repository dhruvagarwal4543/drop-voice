import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/dv_logo.dart';

/// Splash/startup screen that silently re-authenticates,
/// then routes to /home (signed in) or /login (not signed in).
class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward().then((_) => _init());
  }

  Future<void> _init() async {
    // Minimum splash duration for cinematic effect
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // Already signed in with Google?
    final currentUser = _auth.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      context.go('/home');
      return;
    }

    // Try silent Google sign-in (reuse existing session)
    final silentUser = await _auth.signInSilently();
    if (!mounted) return;

    if (silentUser != null && !silentUser.isAnonymous) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dv.obsidian,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DvLogo(size: 40, showTagline: true),
              const SizedBox(height: Dv.s48),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: Dv.steel,
                  color: Dv.green,
                  minHeight: 2,
                ),
              ),
              const SizedBox(height: Dv.s16),
              Text(
                'ESTABLISHING SECURE LINK...',
                style: Dv.mono(size: 10, color: Dv.slate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
