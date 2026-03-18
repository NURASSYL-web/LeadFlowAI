import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/salon_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../providers/whatsapp_connection_provider.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_page.dart';
import '../salon/salon_setup_page.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithEmail(
        _emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      await _navigateAfterAuth();
    } else {
      _showError(auth.error ?? 'Sign in failed');
    }
  }

  Future<void> _signInGoogle() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      await _navigateAfterAuth();
    } else if (auth.error != null) {
      _showError(auth.error!);
    }
  }

  Future<void> _navigateAfterAuth() async {
    final auth = context.read<AuthProvider>();
    final salon = context.read<SalonProvider>();
    await salon.loadSalon(auth.user!.uid);
    if (!mounted) return;
    if (salon.hasSalon) {
      context.read<InquiryProvider>().listenInquiries(
            salonId: salon.salon!.salonId,
            ownerUid: salon.salon!.ownerUid,
          );
      context.read<WhatsAppConnectionProvider>().syncFromSalon(salon.salon);
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const SalonSetupPage(isOnboarding: true)));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.statusLost));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 24),
              Text('Welcome back',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text('Sign in to your LeadFlow AI account',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showResetDialog,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signInEmail,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Sign In'),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      Text('or', style: Theme.of(context).textTheme.bodySmall),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _signInGoogle,
                  icon: const _GoogleLogo(),
                  label: const Text('Continue with Google'),
                ),
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignUpPage())),
                  child: const Text('Sign Up'),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await context
                  .read<AuthProvider>()
                  .sendPasswordReset(ctrl.text.trim());
              if (!context.mounted || !ctx.mounted) return;
              Navigator.of(ctx).pop();
              messenger.showSnackBar(
                  const SnackBar(content: Text('Password reset email sent!')));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708,
        3.1416, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 1.5708,
        1.5708, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.1416,
        0.7854, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.9270,
        0.7854, true, paint);
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);
    paint.color = const Color(0xFF4285F4);
    final rect = Rect.fromLTWH(
        center.dx, center.dy - radius * 0.15, radius * 0.8, radius * 0.3);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
