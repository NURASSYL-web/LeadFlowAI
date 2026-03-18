import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/models/whatsapp_connection_state.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/inquiry_provider.dart';
import '../../providers/salon_provider.dart';
import '../../providers/whatsapp_connection_provider.dart';
import '../auth/sign_in_page.dart';
import '../faq/faq_page.dart';
import '../salon/salon_setup_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final salon = context.read<SalonProvider>().salon;
    context.read<WhatsAppConnectionProvider>().syncFromSalon(salon);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final salonProvider = context.watch<SalonProvider>();
    final whatsappState = context.watch<WhatsAppConnectionProvider>().state;
    final profile = auth.user == null
        ? null
        : UserProfileModel.fromUser(
            auth.user!,
            businessName: salonProvider.salon?.businessName,
            phone: salonProvider.salon?.phone,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (profile != null) _ProfileHeader(profile: profile),
            const SizedBox(height: 16),
            _WhatsAppConnectionCard(state: whatsappState),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Бизнес',
              children: [
                _ActionTile(
                  icon: Icons.storefront_outlined,
                  title: salonProvider.salon?.businessName ?? 'Настроить салон',
                  subtitle: salonProvider.salon?.businessType ??
                      'Добавь данные компании и график работы',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalonSetupPage()),
                  ),
                ),
                _ActionTile(
                  icon: Icons.schedule_outlined,
                  title: salonProvider.salon?.workingHours ?? 'График работы',
                  subtitle: salonProvider.salon?.address ??
                      'Укажи адрес и рабочие часы',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalonSetupPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionCard(
              title: 'AI и автоматизация',
              children: [
                _StaticTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'AI auto-replies',
                  subtitle:
                      'Ответы генерируются через backend AI API по реальным сообщениям',
                ),
                _StaticTile(
                  icon: Icons.tune_outlined,
                  title: 'AI settings',
                  subtitle:
                      'Для live-ответов нужен секрет OPENAI_API_KEY в Firebase Functions',
                ),
                _StaticTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  subtitle:
                      'Push-логика пока не подключена, экран готов к расширению',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Ещё',
              children: [
                _ActionTile(
                  icon: Icons.quiz_outlined,
                  title: 'FAQ',
                  subtitle: 'Частые вопросы и ответы для бизнеса',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaqPage()),
                  ),
                ),
                const _StaticTile(
                  icon: Icons.language_outlined,
                  title: 'Язык',
                  subtitle: 'Русский / English',
                ),
                const _StaticTile(
                  icon: Icons.bar_chart_outlined,
                  title: 'Последняя синхронизация',
                  subtitle: 'Показывается в статусе Telegram Bot',
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout, color: AppColors.statusLost),
              label: const Text('Выйти',
                  style: TextStyle(color: AppColors.statusLost)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.statusLost),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта'),
        content: const Text('Ты действительно хочешь выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.statusLost),
            onPressed: () async {
              Navigator.pop(ctx);
              context.read<SalonProvider>().clear();
              context.read<InquiryProvider>().clear();
              await context.read<app_auth.AuthProvider>().signOut();
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInPage()),
                (route) => false,
              );
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              profile.fullName.isEmpty
                  ? '?'
                  : profile.fullName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                if ((profile.businessName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.businessName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppConnectionCard extends StatelessWidget {
  const _WhatsAppConnectionCard({required this.state});

  final WhatsAppConnectionState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state.status) {
      WhatsAppConnectionStatus.connected => AppColors.statusBooked,
      WhatsAppConnectionStatus.syncing => AppColors.statusInProgress,
      WhatsAppConnectionStatus.error => AppColors.statusLost,
      WhatsAppConnectionStatus.disconnected => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.chat_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Telegram Bot',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      state.label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((state.errorMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if ((state.connectedNumber ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Бот: ${state.connectedNumber}'),
          ],
          if (state.lastSyncedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Последняя синхронизация: ${DateFormat('dd.MM.yyyy HH:mm').format(state.lastSyncedAt!)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: () => context
                .read<WhatsAppConnectionProvider>()
                .reconnect(context.read<SalonProvider>().salon),
            child: Text(state.isConnected ? 'Переподключить' : 'Подключить'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _StaticTile extends StatelessWidget {
  const _StaticTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
