import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/service_model.dart';
import '../../providers/salon_provider.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final salonProvider = context.watch<SalonProvider>();
    final services = salonProvider.services;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Услуги'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openServiceSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: SafeArea(
        child: services.isEmpty
            ? _EmptyServicesState(onAdd: () => _openServiceSheet(context))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _ServicesHeader(services: services),
                  const SizedBox(height: 16),
                  ...services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ServiceCard(
                        service: service,
                        onEdit: () => _openServiceSheet(context, service),
                        onToggle: () {
                          context.read<SalonProvider>().updateService(
                                service.copyWith(isActive: !service.isActive),
                              );
                        },
                        onDelete: () => _confirmDelete(context, service),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _openServiceSheet(BuildContext context, [ServiceModel? existing]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceFormSheet(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, ServiceModel service) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить услугу'),
        content: Text('Удалить "${service.name}" из списка услуг?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusLost,
            ),
            onPressed: () {
              context.read<SalonProvider>().deleteService(service.serviceId);
              Navigator.pop(ctx);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _ServicesHeader extends StatelessWidget {
  const _ServicesHeader({required this.services});

  final List<ServiceModel> services;

  @override
  Widget build(BuildContext context) {
    final active = services.where((item) => item.isActive).length;
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
          Text('Каталог услуг',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Управляй ценами, описаниями и видимостью услуг в мобильном формате.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Всего',
                  value: services.length.toString(),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Активные',
                  value: active.toString(),
                  color: AppColors.statusBooked,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Скрытые',
                  value: (services.length - active).toString(),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    try {
      final displayName = service.name.trim().isEmpty ? 'Без названия' : service.name.trim();
      final displayCategory =
          service.category.trim().isEmpty ? 'Other' : service.category.trim();
      final displayDescription = service.description.trim().isEmpty
          ? 'Описание пока не добавлено.'
          : service.description.trim();
      final displayAutoReply = service.autoReplyTemplate.trim();
      final displayKeywords =
          service.keywords.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SmallBadge(
                              label: displayCategory, color: AppColors.primary),
                          _SmallBadge(
                            label: service.isActive ? 'Активна' : 'Скрыта',
                            color: service.isActive
                                ? AppColors.statusBooked
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                        value: 'edit', child: Text('Редактировать')),
                    PopupMenuItem<String>(
                        value: 'delete', child: Text('Удалить')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              displayDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (displayKeywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: displayKeywords
                    .map(
                      (keyword) => _SmallBadge(
                        label: keyword,
                        color: AppColors.statusInProgress,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (displayAutoReply.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Готовый автоответ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayAutoReply,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ServiceInfoTile(
                    label: 'Цена',
                    value: '${service.price.toStringAsFixed(0)} KZT',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ServiceInfoTile(
                    label: 'Длительность',
                    value: '${service.duration} мин',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: service.isActive,
              onChanged: (_) => onToggle(),
              title: const Text('Показывать клиентам'),
              subtitle: const Text(
                  'Услуга будет участвовать в автоответах и каталоге'),
            ),
          ],
        ),
      );
    } catch (_) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('Не удалось отобразить эту услугу. Открой и сохрани её заново.'),
      );
    }
  }
}

class _ServiceInfoTile extends StatelessWidget {
  const _ServiceInfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyServicesState extends StatelessWidget {
  const _EmptyServicesState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.content_cut_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Пока нет услуг',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Добавь услуги, чтобы ИИ мог использовать их в предложениях и автоответах.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceFormSheet extends StatefulWidget {
  const _ServiceFormSheet({this.existing});

  final ServiceModel? existing;

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _autoReplyCtrl;
  late final TextEditingController _keywordsCtrl;
  late final TextEditingController _durationCtrl;
  late String _category;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.price.toStringAsFixed(0)
          : '',
    );
    _descriptionCtrl =
        TextEditingController(text: widget.existing?.description ?? '');
    _autoReplyCtrl =
        TextEditingController(text: widget.existing?.autoReplyTemplate ?? '');
    _keywordsCtrl = TextEditingController(
      text: widget.existing?.keywords.join(', ') ?? '',
    );
    _durationCtrl = TextEditingController(
      text: widget.existing?.duration.toString() ?? '60',
    );
    final existingCategory = widget.existing?.category ?? '';
    _category = AppConstants.serviceCategories.contains(existingCategory)
        ? existingCategory
        : AppConstants.serviceCategories.first;
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    _autoReplyCtrl.dispose();
    _keywordsCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? 'Новая услуга'
                          : 'Редактировать услугу',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Название услуги'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Введите название'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _autoReplyCtrl,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Готовый ответ клиенту',
                  hintText:
                      'Например: Здравствуйте! {service} стоит {price} KZT, длительность {duration} мин.',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Шаблон можно вставить вручную. Доступны переменные: {service}, {price}, {duration}, {businessName}, {description}.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keywordsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ключевые слова',
                  hintText: 'Например: педикюр, pedicure, педик',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Разделяй слова запятыми. По ним приложение точнее подберёт услугу в чате.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Цена'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Введите цену'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Длительность'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: AppConstants.serviceCategories
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _category = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Услуга активна'),
                subtitle: const Text('Если выключить, услуга будет скрыта'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.existing == null
                          ? 'Создать услугу'
                          : 'Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final salonProvider = context.read<SalonProvider>();
    final salon = salonProvider.salon;
    if (salon == null) {
      return;
    }

    setState(() => _saving = true);

    final service = ServiceModel(
      serviceId: widget.existing?.serviceId ?? '',
      salonId: salon.salonId,
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      autoReplyTemplate: _autoReplyCtrl.text.trim(),
      keywords: _keywordsCtrl.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(),
      category: _category,
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      duration: int.tryParse(_durationCtrl.text.trim()) ?? 60,
      isActive: _isActive,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (widget.existing == null) {
      await salonProvider.addService(service);
    } else {
      await salonProvider.updateService(service);
    }

    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }
}
