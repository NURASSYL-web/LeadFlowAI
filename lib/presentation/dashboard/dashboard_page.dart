import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../providers/salon_provider.dart';
import '../inquiries/inquiry_list_page.dart';
import '../profile/profile_page.dart';
import '../salon/salon_setup_page.dart';
import '../services/services_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    _HomeTab(onOpenChats: () => _selectTab(1)),
    const InquiryListPage(),
    const ServicesPage(),
    const ProfilePage(),
  ];

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Чаты',
            ),
            NavigationDestination(
              icon: Icon(Icons.content_cut_outlined),
              selectedIcon: Icon(Icons.content_cut),
              label: 'Услуги',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onOpenChats});

  final VoidCallback onOpenChats;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final salon = context.watch<SalonProvider>();
    final inquiries = context.watch<InquiryProvider>();
    final counts = inquiries.statusCounts;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/leadflow_mark.svg',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 10),
            const Text('LeadFlow AI'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.user != null) {
            await salon.loadSalon(auth.user!.uid);
            if (salon.salon != null && context.mounted) {
              context.read<InquiryProvider>().listenInquiries(
                    salonId: salon.salon!.salonId,
                    ownerUid: salon.salon!.ownerUid,
                  );
            }
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _GreetingCard(
              greeting: _greeting(),
              user: auth.user?.name ?? 'User',
              salon: salon.salon?.businessName,
            ),
            const SizedBox(height: 16),
            _StatsSection(
              counts: counts,
              total: inquiries.inquiries.length,
            ),
            const SizedBox(height: 16),
            _QuickActionsSection(
              onOpenChats: onOpenChats,
            ),
            const SizedBox(height: 16),
            _RecentChatsSection(
              inquiries: inquiries.inquiries.take(5).toList(),
              onOpenChats: onOpenChats,
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Доброе утро';
    }
    if (hour < 18) {
      return 'Добрый день';
    }
    return 'Добрый вечер';
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.greeting,
    required this.user,
    required this.salon,
  });

  final String greeting;
  final String user;
  final String? salon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $user',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            salon ?? 'Настрой профиль салона, чтобы включить AI-автоматизацию.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: 14),
          Text(
            DateFormat('EEEE, d MMMM').format(DateTime.now()),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.counts,
    required this.total,
  });

  final Map<String, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final items = [
      _HomeMetric(
        label: 'Всего',
        value: total.toString(),
        color: AppColors.primary,
      ),
      _HomeMetric(
        label: 'Новые',
        value: (counts['New'] ?? 0).toString(),
        color: AppColors.statusNew,
      ),
      _HomeMetric(
        label: 'В работе',
        value: (counts['In Progress'] ?? 0).toString(),
        color: AppColors.statusInProgress,
      ),
      _HomeMetric(
        label: 'Ожидают',
        value: (counts['Awaiting Client'] ?? 0).toString(),
        color: AppColors.statusAwaiting,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Главная', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) => items[index],
        ),
      ],
    );
  }
}

class _HomeMetric extends StatelessWidget {
  const _HomeMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color.withValues(alpha: 0.88),
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.onOpenChats,
  });

  final VoidCallback onOpenChats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Быстрые действия',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _ActionCard(
              icon: Icons.forum_outlined,
              label: 'Открыть чаты',
              color: AppColors.primary,
              onTap: onOpenChats,
            ),
            _ActionCard(
              icon: Icons.storefront_outlined,
              label: 'Профиль салона',
              color: AppColors.accent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalonSetupPage()),
              ),
            ),
            _ActionCard(
              icon: Icons.content_cut_outlined,
              label: 'Услуги',
              color: AppColors.statusBooked,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServicesPage()),
              ),
            ),
            _ActionCard(
              icon: Icons.link_outlined,
              label: 'Подключить Telegram',
              color: AppColors.statusInProgress,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalonSetupPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _RecentChatsSection extends StatelessWidget {
  const _RecentChatsSection({
    required this.inquiries,
    required this.onOpenChats,
  });

  final List<dynamic> inquiries;
  final VoidCallback onOpenChats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Последние чаты',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            TextButton(
              onPressed: onOpenChats,
              child: const Text('Все'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (inquiries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
                'Чаты из Telegram появятся здесь после синхронизации.'),
          )
        else
          ...inquiries.map(
            (inquiry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        inquiry.customerName.isEmpty
                            ? '?'
                            : inquiry.customerName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inquiry.customerName,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            inquiry.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
