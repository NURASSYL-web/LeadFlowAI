import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/salon_provider.dart';
import '../../data/models/faq_model.dart';
import '../../core/theme/app_theme.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final salon = context.watch<SalonProvider>();
    final faqs = salon.faqs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ & Quick Answers'),
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showFaqDialog(context, null))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _showFaqDialog(context, null),
          child: const Icon(Icons.add)),
      body: faqs.isEmpty
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const Icon(Icons.quiz_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No FAQs yet',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Add answers to common questions',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                      onPressed: () => _showFaqDialog(context, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Add FAQ')),
                ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: faqs.length,
              itemBuilder: (_, i) => _FaqCard(faq: faqs[i]),
            ),
    );
  }

  void _showFaqDialog(BuildContext context, FaqModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FaqForm(existing: existing),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final FaqModel faq;
  const _FaqCard({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.quiz_outlined,
              color: AppColors.primary, size: 18),
        ),
        title:
            Text(faq.question, style: Theme.of(context).textTheme.titleMedium),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textSecondary),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _FaqForm(existing: faq),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined,
                size: 18, color: AppColors.statusLost),
            onPressed: () => _confirmDelete(context),
          ),
        ]),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10)),
            child:
                Text(faq.answer, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete FAQ'),
        content: const Text('Are you sure you want to delete this FAQ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.statusLost),
            onPressed: () {
              context.read<SalonProvider>().deleteFaq(faq.faqId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FaqForm extends StatefulWidget {
  final FaqModel? existing;
  const _FaqForm({this.existing});
  @override
  State<_FaqForm> createState() => _FaqFormState();
}

class _FaqFormState extends State<_FaqForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionCtrl;
  late final TextEditingController _answerCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _questionCtrl =
        TextEditingController(text: widget.existing?.question ?? '');
    _answerCtrl = TextEditingController(text: widget.existing?.answer ?? '');
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    final salonProvider = context.read<SalonProvider>();
    final faq = FaqModel(
      faqId: widget.existing?.faqId ?? '',
      salonId: salonProvider.salon!.salonId,
      question: _questionCtrl.text.trim(),
      answer: _answerCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    if (widget.existing == null) {
      await salonProvider.addFaq(faq);
    } else {
      await salonProvider.updateFaq(faq);
    }
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.existing == null ? 'Add FAQ' : 'Edit FAQ',
                    style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _questionCtrl,
              decoration: const InputDecoration(
                  labelText: 'Question *',
                  hintText: 'e.g. Do you offer discounts?'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _answerCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Answer *', alignLabelWithHint: true),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save FAQ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
