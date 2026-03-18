import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/inbox_message_model.dart';
import '../../data/models/inquiry_model.dart';
import '../../data/models/message_model.dart';
import '../../providers/inquiry_provider.dart';
import '../../providers/salon_provider.dart';
import '../../services/leadflow_backend_service.dart';
import '../../services/local_reply_service.dart';

class InquiryDetailPage extends StatefulWidget {
  const InquiryDetailPage({super.key, required this.inquiry});

  final InquiryModel inquiry;

  @override
  State<InquiryDetailPage> createState() => _InquiryDetailPageState();
}

class _InquiryDetailPageState extends State<InquiryDetailPage> {
  final LeadflowBackendService _backend = const LeadflowBackendService();
  final LocalReplyService _localReplyService = const LocalReplyService();
  String? _suggestedReply;
  bool _generating = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _suggestedReply = widget.inquiry.suggestedReply;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали чата'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<InboxMessageModel>>(
          stream: context
              .read<InquiryProvider>()
              .watchMessages(widget.inquiry.inquiryId),
          builder: (context, snapshot) {
            final inboxMessages = snapshot.data ?? const <InboxMessageModel>[];
            final messages =
                inboxMessages.map(MessageModel.fromInboxMessage).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _CustomerHeader(inquiry: widget.inquiry),
                const SizedBox(height: 16),
                _AutomationCard(
                  inquiry: widget.inquiry,
                  suggestedReply: _suggestedReply,
                  generating: _generating,
                  sending: _sending,
                  onGenerate: () => _generateReply(inboxMessages),
                  onSend: _suggestedReply?.trim().isNotEmpty == true
                      ? () => _sendReply(_suggestedReply!)
                      : null,
                ),
                const SizedBox(height: 16),
                _MessagesCard(messages: messages),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _generateReply(List<InboxMessageModel> messages) async {
    final salonProvider = context.read<SalonProvider>();
    final salon = salonProvider.salon;
    final latestMessage = messages.isNotEmpty
        ? messages.last.text.trim()
        : widget.inquiry.message.trim();

    if (salon == null || latestMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Сначала заполни профиль салона и дождись входящего сообщения.'),
        ),
      );
      return;
    }

    setState(() => _generating = true);
    final inquiryProvider = context.read<InquiryProvider>();
    try {
      final reply = _localReplyService.buildReply(
        latestMessage: latestMessage,
        businessName: salon.businessName,
        services: salonProvider.services,
        faqs: salonProvider.faqs,
      );
      if (!mounted) {
        return;
      }
      await inquiryProvider.updateSuggestedReply(
        widget.inquiry.inquiryId,
        reply,
      );
      if (!mounted) {
        return;
      }
      setState(() => _suggestedReply = reply);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.statusLost,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<void> _sendReply(String text) async {
    setState(() => _sending = true);
    try {
      await _backend.sendTelegramReply(
        conversationId: widget.inquiry.inquiryId,
        text: text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ответ отправлен в Telegram.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.statusLost,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.inquiry});

  final InquiryModel inquiry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              inquiry.customerName.isEmpty
                  ? '?'
                  : inquiry.customerName[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inquiry.customerName,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  inquiry.customerPhone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      label:
                          inquiry.channel == 'telegram' ? 'Telegram' : 'Lead',
                      color: AppColors.statusBooked,
                    ),
                    _Pill(
                        label: inquiry.status,
                        color: statusColor(inquiry.status)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutomationCard extends StatelessWidget {
  const _AutomationCard({
    required this.inquiry,
    required this.suggestedReply,
    required this.generating,
    required this.sending,
    required this.onGenerate,
    required this.onSend,
  });

  final InquiryModel inquiry;
  final String? suggestedReply;
  final bool generating;
  final bool sending;
  final Future<void> Function() onGenerate;
  final Future<void> Function()? onSend;

  @override
  Widget build(BuildContext context) {
    final hasReply = suggestedReply?.trim().isNotEmpty == true;

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
          Text('Автоответ', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: inquiry.status, color: AppColors.primary),
              _Pill(
                label: hasReply ? 'Ответ готов' : 'Нужен подбор',
                color: hasReply
                    ? AppColors.statusBooked
                    : AppColors.statusInProgress,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              hasReply
                  ? suggestedReply!
                  : 'Нажми "Сгенерировать", чтобы подобрать ответ из услуг и FAQ по текущему сообщению клиента.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: generating ? null : onGenerate,
                  child: generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(hasReply ? 'Перегенерировать' : 'Сгенерировать'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: sending || !hasReply || onSend == null
                      ? null
                      : () => onSend!.call(),
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Отправить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessagesCard extends StatelessWidget {
  const _MessagesCard({required this.messages});

  final List<MessageModel> messages;

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
          Text('История сообщений',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          if (messages.isEmpty)
            const Text('Пока нет синхронизированных сообщений.')
          else
            ...messages.map((message) => _MessageBubble(message: message)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    final inbound = message.direction != 'outbound';
    return Align(
      alignment: inbound ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: inbound ? AppColors.surfaceVariant : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text.isEmpty ? '[${message.type}]' : message.text),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd.MM • HH:mm').format(message.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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
