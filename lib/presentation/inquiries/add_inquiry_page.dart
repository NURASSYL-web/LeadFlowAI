import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/salon_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../data/models/inquiry_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AddInquiryPage extends StatefulWidget {
  final String salonId;
  const AddInquiryPage({super.key, required this.salonId});
  @override
  State<AddInquiryPage> createState() => _AddInquiryPageState();
}

class _AddInquiryPageState extends State<AddInquiryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _replyCtrl = TextEditingController();
  String _intentType = 'General Question';
  String _status = 'New';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  void _generateReply() {
    final salon = context.read<SalonProvider>();
    final reply = salon.generateSuggestedReply(_messageCtrl.text, _intentType);
    setState(() => _replyCtrl.text = reply);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final inquiry = InquiryModel(
      inquiryId: '',
      salonId: widget.salonId,
      customerName: _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      channel: 'manual',
      message: _messageCtrl.text.trim(),
      intentType: _intentType,
      status: _status,
      suggestedReply:
          _replyCtrl.text.trim().isEmpty ? null : _replyCtrl.text.trim(),
      unreadCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await context.read<InquiryProvider>().addInquiry(inquiry);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Inquiry added!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Inquiry'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Add',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'Customer Info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    prefixIcon: Icon(Icons.person_outlined)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const _SectionLabel(label: 'Inquiry Details'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _intentType,
                decoration: const InputDecoration(
                    labelText: 'Intent Type',
                    prefixIcon: Icon(Icons.category_outlined)),
                items: AppConstants.intentTypes
                    .map((t) =>
                        DropdownMenuItem<String>(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _intentType = v!;
                  if (_messageCtrl.text.isNotEmpty) _generateReply();
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                    labelText: 'Status', prefixIcon: Icon(Icons.flag_outlined)),
                items: AppConstants.inquiryStatuses
                    .map((s) => DropdownMenuItem<String>(
                          value: s,
                          child: Row(children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: statusColor(s),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(s),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Customer Message *',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.message_outlined)),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                onChanged: (_) {},
              ),
              const SizedBox(height: 20),
              const _SectionLabel(label: 'Suggested Reply'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const Icon(Icons.auto_awesome,
                                color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Text('AI Suggested Reply',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 13)),
                          ]),
                          TextButton.icon(
                            onPressed: _generateReply,
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('Generate',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: TextFormField(
                        controller: _replyCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Tap Generate to create reply based on your salon services...',
                          fillColor: AppColors.primarySurface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.primary)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
                      : const Text('Add Inquiry'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.primary)),
    ]);
  }
}
