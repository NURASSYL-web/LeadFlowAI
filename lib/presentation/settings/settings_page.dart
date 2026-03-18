import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/salon_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/sign_in_page.dart';
import '../salon/salon_setup_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final salon = context.watch<SalonProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(
              name: user?.name ?? 'User',
              email: user?.email ?? '',
              avatarUrl: user?.avatarUrl,
              isVerified:
                  FirebaseAuth.instance.currentUser?.emailVerified ?? false,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Salon',
              children: [
                _SettingsTile(
                  icon: Icons.store_outlined,
                  title: salon.salon?.businessName ?? 'Set up salon',
                  subtitle: salon.salon?.businessType ?? 'No salon profile yet',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SalonSetupPage())),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Account',
              children: [
                _SettingsTile(
                  icon: Icons.person_outlined,
                  title: 'Profile',
                  subtitle: user?.email ?? '',
                  onTap: () => _showEditProfileDialog(context, auth),
                ),
                if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? true))
                  _SettingsTile(
                    icon: Icons.mark_email_unread_outlined,
                    title: 'Verify Email',
                    subtitle: 'Send verification email',
                    iconColor: AppColors.statusInProgress,
                    onTap: () async {
                      await FirebaseAuth.instance.currentUser
                          ?.sendEmailVerification();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Verification email sent!')));
                    },
                  ),
                _SettingsTile(
                  icon: Icons.lock_reset_outlined,
                  title: 'Reset Password',
                  subtitle: 'Send password reset email',
                  onTap: () async {
                    if (user?.email != null) {
                      await auth.sendPasswordReset(user!.email);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Password reset email sent!')));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'About',
              children: [
                _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'LeadFlow AI',
                    subtitle: 'Version 1.0.0',
                    onTap: () {}),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context, auth),
                  icon: const Icon(Icons.logout, color: AppColors.statusLost),
                  label: const Text('Sign Out',
                      style: TextStyle(color: AppColors.statusLost)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.statusLost),
                    foregroundColor: AppColors.statusLost,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, app_auth.AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.statusLost),
            onPressed: () async {
              Navigator.pop(ctx);
              context.read<SalonProvider>().clear();
              context.read<InquiryProvider>().clear();
              await auth.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInPage()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, app_auth.AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter your full name.')));
                return;
              }

              final success = await auth.updateProfile(name: name);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Profile updated!'
                      : 'Could not update profile. Try again.'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isVerified;
  const _ProfileHeader(
      {required this.name,
      required this.email,
      this.avatarUrl,
      required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800))
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(email,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isVerified
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isVerified ? '✓ Verified' : '⚠ Unverified',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        )),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    )),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  const _SettingsTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      onTap: onTap,
    );
  }
}
