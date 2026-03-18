import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/salon_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../providers/whatsapp_connection_provider.dart';
import '../../data/models/salon_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../dashboard/dashboard_page.dart';

class SalonSetupPage extends StatefulWidget {
  final bool isOnboarding;
  const SalonSetupPage({super.key, this.isOnboarding = false});
  @override
  State<SalonSetupPage> createState() => _SalonSetupPageState();
}

class _SalonSetupPageState extends State<SalonSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _whatsAppCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  String? _selectedType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final salon = context.read<SalonProvider>().salon;
    if (salon != null) {
      _nameCtrl.text = salon.businessName;
      _whatsAppCtrl.text = salon.whatsappNumber ?? '';
      _phoneCtrl.text = salon.phone ?? '';
      _addressCtrl.text = salon.address ?? '';
      _cityCtrl.text = salon.city ?? '';
      _hoursCtrl.text = salon.workingHours ?? '';
      _selectedType = salon.businessType;
    } else {
      final user = context.read<AuthProvider>().user;
      final registeredPhone = user?.phone ?? '';
      if (registeredPhone.isNotEmpty) {
        _phoneCtrl.text = registeredPhone;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _whatsAppCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a business type')));
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final salonProvider = context.read<SalonProvider>();
    final salon = SalonModel(
      salonId: salonProvider.salon?.salonId ?? '',
      ownerUid: auth.user!.uid,
      businessName: _nameCtrl.text.trim(),
      businessType: _selectedType!,
      whatsappNumber: _whatsAppCtrl.text.trim().isEmpty
          ? null
          : _normalizeTelegramHandle(_whatsAppCtrl.text),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      workingHours:
          _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
      createdAt: salonProvider.salon?.createdAt ?? DateTime.now(),
    );
    await salonProvider.createOrUpdateSalon(salon);
    if (!mounted) return;
    setState(() => _loading = false);
    if (salonProvider.salon != null) {
      final inquiryProvider = context.read<InquiryProvider>();
      final whatsappProvider = context.read<WhatsAppConnectionProvider>();
      inquiryProvider.listenInquiries(
        salonId: salonProvider.salon!.salonId,
        ownerUid: salonProvider.salon!.ownerUid,
      );
      await whatsappProvider.syncFromSalon(salonProvider.salon);
      if (!mounted) return;
    }
    if (widget.isOnboarding) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (r) => false);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salon profile updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(title: const Text('Salon Profile'), actions: [
              TextButton(
                  onPressed: _loading ? null : _save,
                  child: const Text('Save')),
            ]),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isOnboarding) ...[
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.store_outlined,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                Text("Set up your salon",
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text("Tell us about your business to get started",
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
              ],
              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Business Name *',
                        prefixIcon: Icon(Icons.business_outlined)),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Business name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTypeSelector(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _whatsAppCtrl,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Telegram bot username',
                      prefixIcon: Icon(Icons.chat_outlined),
                      hintText: 'e.g. @leadflow_bot',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return null;
                      }
                      if (!_isValidTelegramHandle(text)) {
                        return 'Enter a valid Telegram bot username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hoursCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Working Hours',
                      prefixIcon: Icon(Icons.access_time_outlined),
                      hintText: 'e.g. Mon–Sat 9am–7pm',
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
                          : Text(widget.isOnboarding
                              ? 'Get Started'
                              : 'Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business Type *', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.businessTypes.map((type) {
            final selected = _selectedType == type;
            return ChoiceChip(
              label: Text(type),
              selected: selected,
              onSelected: (_) => setState(() => _selectedType = type),
              selectedColor: AppColors.primarySurface,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  String _normalizeTelegramHandle(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  bool _isValidTelegramHandle(String input) {
    final normalized = _normalizeTelegramHandle(input);
    return RegExp(r'^@[A-Za-z0-9_]{5,}$').hasMatch(normalized);
  }
}
