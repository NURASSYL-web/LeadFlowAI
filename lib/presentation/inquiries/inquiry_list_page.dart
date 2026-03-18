import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/inquiry_model.dart';
import '../../providers/inquiry_provider.dart';
import 'inquiry_detail_page.dart';

class InquiryListPage extends StatefulWidget {
  const InquiryListPage({super.key});

  @override
  State<InquiryListPage> createState() => _InquiryListPageState();
}

class _InquiryListPageState extends State<InquiryListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'Все';

  static const List<String> _filters = [
    'Все',
    'New',
    'In Progress',
    'Awaiting Client',
    'Booked',
    'Lost',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InquiryProvider>();
    final chats = provider.inquiries
        .map(ChatModel.fromInquiry)
        .where(_matchesSearch)
        .where((chat) => _statusFilter == 'Все' || chat.status == _statusFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Поиск по имени, номеру или сообщению',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final selected = _statusFilter == filter;
                        return ChoiceChip(
                          label: Text(filter == 'Awaiting Client'
                              ? 'Ожидает клиента'
                              : filter),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _statusFilter = filter),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chats.isEmpty
                  ? const _EmptyChatsState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final inquiry = provider.inquiries.firstWhere(
                          (item) => item.inquiryId == chat.id,
                        );
                        return _ChatCard(
                          inquiry: inquiry,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesSearch(ChatModel chat) {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return chat.customerName.toLowerCase().contains(query) ||
        chat.customerPhone.toLowerCase().contains(query) ||
        chat.lastMessage.toLowerCase().contains(query);
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.inquiry,
  });

  final InquiryModel inquiry;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(inquiry.status);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InquiryDetailPage(inquiry: inquiry),
        ),
      ),
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
            Row(
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
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        inquiry.customerPhone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(inquiry.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              inquiry.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                    label: inquiry.channel == 'telegram' ? 'Telegram' : 'Lead',
                    color: AppColors.statusBooked),
                _Pill(label: inquiry.status, color: color),
                _Pill(
                  label: inquiry.suggestedReply?.trim().isNotEmpty == true
                      ? 'AI готов'
                      : 'AI не сгенерирован',
                  color: AppColors.primary,
                ),
                if (inquiry.unreadCount > 0)
                  _Pill(
                      label: '${inquiry.unreadCount} unread',
                      color: AppColors.statusLost),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                inquiry.suggestedReply?.trim().isNotEmpty == true
                    ? inquiry.suggestedReply!
                    : 'Открой чат, чтобы подобрать автоответ из услуг и FAQ.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyChatsState extends StatelessWidget {
  const _EmptyChatsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Пока нет чатов',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Как только сообщения из Telegram попадут в Firestore, они автоматически появятся здесь.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
