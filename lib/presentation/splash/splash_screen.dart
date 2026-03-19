import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/salon_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../providers/whatsapp_connection_provider.dart';
import '../auth/sign_in_page.dart';
import '../dashboard/dashboard_page.dart';
import '../salon/salon_setup_page.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialization;
    if (authProvider.status == AuthStatus.loading) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.status == AuthStatus.authenticated) {
      final salonProvider = context.read<SalonProvider>();
      salonProvider.loadSalon(authProvider.user!.uid).then((_) {
        if (!mounted) return;
        if (salonProvider.hasSalon) {
          context
              .read<InquiryProvider>()
              .listenInquiries(
                salonId: salonProvider.salon!.salonId,
                ownerUid: salonProvider.salon!.ownerUid,
              );
          context
              .read<WhatsAppConnectionProvider>()
              .syncFromSalon(salonProvider.salon)
              .whenComplete(() {
            if (!mounted) {
              return;
            }
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          });
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => const SalonSetupPage(isOnboarding: true)));
        }
      });
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignInPage()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: SvgPicture.asset(
                      'assets/icons/leadflow_mark.svg',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('LeadFlow AI',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Smart inbox for beauty salons',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 60),
                  const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                          color: Colors.white54, strokeWidth: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
