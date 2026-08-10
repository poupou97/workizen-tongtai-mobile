import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../consumer/customer.dart';
import '../../consumer/customer_form.dart';
import '../../consumer/customer_history.dart';
import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// Add / Edit Customer form (WTM-76).
///
/// One screen serves both flows: pass [customer] to edit it, or omit it to add
/// a new one. Covers every acceptance criterion —
/// - fields: name, phone, email, address, segment (AC1),
/// - multiple address entries with add/remove rows (AC2),
/// - notes + tags for seller annotations (AC3),
/// - edit mode records a change history and shows past revisions (AC4),
/// - live duplicate warning fed by [findDuplicates] (AC5).
///
/// On Save the screen pops the resulting [Customer] (built via
/// [CustomerEditor]); on Cancel it pops `null`. The caller (Customer list
/// screen) upserts the result — same contract as the WTM-69 product form.
class TongtaiCustomerFormScreen extends StatefulWidget {
  const TongtaiCustomerFormScreen({
    super.key,
    this.customer,
    this.locations = const [],
    this.findDuplicates,
    this.clock,
    this.idFactory,
  });

  /// The customer to edit; `null` puts the form in "add" mode.
  final Customer? customer;

  /// Known cities offered as quick-pick chips under the city field.
  final List<String> locations;

  /// Returns customers that look like duplicates of the typed name/phone
  /// (WTM-76 AC5). Wired by the caller to the directory (already excluding the
  /// customer being edited); `null` disables the check.
  final List<Customer> Function(String name, String phone)? findDuplicates;

  /// Injectable clock (defaults to [DateTime.now]) — set in tests for
  /// deterministic revision timestamps.
  final DateTime Function()? clock;

  /// Injectable id generator for new customers (defaults to a UUID v4).
  final String Function()? idFactory;

  bool get isEditing => customer != null;

  @override
  State<TongtaiCustomerFormScreen> createState() =>
      _TongtaiCustomerFormScreenState();
}

class _TongtaiCustomerFormScreenState extends State<TongtaiCustomerFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _location;
  late final TextEditingController _tags;
  late final TextEditingController _notes;
  late final TextEditingController _segmentInput;
  final List<TextEditingController> _addresses = [];

  late final DateTime Function() _clock;
  late final String Function() _idFactory;

  final List<String> _segments = [];

  /// Field-keyed errors, populated after the first Save attempt.
  Map<CustomerField, String> _errors = const {};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final data = widget.customer == null
        ? const CustomerFormData()
        : CustomerFormData.fromCustomer(widget.customer!);
    _name = TextEditingController(text: data.name);
    _phone = TextEditingController(text: data.phone);
    _email = TextEditingController(text: data.email);
    _location = TextEditingController(text: data.location);
    _tags = TextEditingController(text: data.tags.join(', '));
    _notes = TextEditingController(text: data.notes);
    _segmentInput = TextEditingController();
    _segments.addAll(data.segments);
    for (final address in data.addresses) {
      _addresses.add(TextEditingController(text: address));
    }
    if (_addresses.isEmpty) _addresses.add(TextEditingController());

    for (final c in _textControllers) {
      c.addListener(_handleFieldChange);
    }

    _clock = widget.clock ?? DateTime.now;
    _idFactory = widget.idFactory ?? const Uuid().v4;
  }

  List<TextEditingController> get _textControllers => [
    _name,
    _phone,
    _email,
    _location,
    _tags,
    _notes,
    ..._addresses,
  ];

  @override
  void dispose() {
    for (final c in _textControllers) {
      c.removeListener(_handleFieldChange);
      c.dispose();
    }
    _segmentInput.dispose();
    super.dispose();
  }

  // Rebuild on every keystroke so the duplicate warning + live change preview
  // stay current, and re-run validation once the user has attempted a save.
  void _handleFieldChange() {
    if (!mounted) return;
    setState(() {
      if (_submitted) _errors = _currentData().validate();
    });
  }

  CustomerFormData _currentData() => CustomerFormData(
    name: _name.text,
    phone: _phone.text,
    email: _email.text,
    location: _location.text,
    addresses: [for (final c in _addresses) c.text],
    segments: _segments,
    tags: [
      for (final tag in _tags.text.split(','))
        if (tag.trim().isNotEmpty) tag.trim(),
    ],
    notes: _notes.text,
  );

  /// Live duplicate matches for the typed name/phone (WTM-76 AC5).
  List<Customer> _duplicates() =>
      widget.findDuplicates?.call(_name.text, _phone.text) ?? const [];

  void _save() {
    final data = _currentData();
    final errors = data.validate();
    setState(() {
      _submitted = true;
      _errors = errors;
    });
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.formFixHighlighted)),
        );
      return;
    }
    final original = widget.customer;
    final result = original == null
        ? CustomerEditor.create(data, id: _idFactory())
        : CustomerEditor.applyEdit(original, data, now: _clock());
    Navigator.of(context).pop(result);
  }

  void _cancel() => Navigator.of(context).pop();

  void _addAddressRow() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(_handleFieldChange);
      _addresses.add(controller);
    });
  }

  void _removeAddressRow(int index) {
    setState(() {
      final controller = _addresses.removeAt(index);
      controller.removeListener(_handleFieldChange);
      controller.dispose();
    });
  }

  void _toggleSegment(String segment, bool selected) {
    setState(() {
      if (selected) {
        if (!_segments.contains(segment)) _segments.add(segment);
      } else {
        _segments.remove(segment);
      }
    });
  }

  void _addCustomSegment() {
    final segment = _segmentInput.text.trim();
    if (segment.isEmpty) return;
    setState(() {
      if (!_segments.contains(segment)) _segments.add(segment);
      _segmentInput.clear();
    });
  }

  /// The unsaved diff of the current form against the customer being edited.
  List<CustomerFieldChange> _pendingChanges() {
    final original = widget.customer;
    if (original == null) return const [];
    final edited = _currentData().toCustomer(
      id: original.id,
      orderCount: original.orderCount,
      totalSpent: original.totalSpent,
      lastPurchaseDate: original.lastPurchaseDate,
      history: original.history,
    );
    return CustomerEditor.diff(original, edited);
  }

  @override
  Widget build(BuildContext context) {
    final duplicates = _duplicates();
    final pending = _pendingChanges();
    final history = widget.customer?.history ?? const <CustomerRevision>[];

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        // Stable test ID carries the *mode* — see the note on the goal form.
        title: Text(
          key: Key(
            widget.isEditing
                ? 'customer-form-title-edit'
                : 'customer-form-title-add',
          ),
          widget.isEditing
              ? context.l10n.customerEditTitle
              : context.l10n.customerAddTitle,
        ),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          children: [
            _field(
              key: const Key('customer-name-field'),
              controller: _name,
              field: CustomerField.name,
              hint: context.l10n.custNameHint,
              textCapitalization: TextCapitalization.words,
            ),
            _field(
              key: const Key('customer-phone-field'),
              controller: _phone,
              field: CustomerField.phone,
              hint: 'e.g. +84912345678',
              keyboardType: TextInputType.phone,
            ),
            if (duplicates.isNotEmpty)
              _DuplicateWarning(duplicates: duplicates),
            _field(
              key: const Key('customer-email-field'),
              controller: _email,
              field: CustomerField.email,
              hint: 'e.g. khach@gmail.com',
              optional: true,
              keyboardType: TextInputType.emailAddress,
            ),
            _field(
              key: const Key('customer-location-field'),
              controller: _location,
              field: CustomerField.location,
              hint: context.l10n.custLocationHint,
              optional: true,
            ),
            _LocationSuggestions(
              locations: widget.locations,
              onSelected: (location) {
                _location.text = location;
                _location.selection = TextSelection.collapsed(
                  offset: location.length,
                );
              },
            ),
            _AddressesSection(
              controllers: _addresses,
              onAdd: _addAddressRow,
              onRemove: _addresses.length > 1 ? _removeAddressRow : null,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            _SegmentsSection(
              selected: _segments,
              input: _segmentInput,
              onToggle: _toggleSegment,
              onAddCustom: _addCustomSegment,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            _field(
              key: const Key('customer-tags-field'),
              controller: _tags,
              field: CustomerField.tags,
              hint: context.l10n.custTagsHint,
              optional: true,
            ),
            _field(
              key: const Key('customer-notes-field'),
              controller: _notes,
              field: CustomerField.notes,
              hint: 'Private notes about this customer…',
              optional: true,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: TongtaiDesignTokens.spacing4),
              _ChangeList(
                title: context.l10n.unsavedChanges(pending.length),
                changes: pending,
                accent: TongtaiDesignTokens.info,
              ),
            ],
            if (history.isNotEmpty) ...[
              const SizedBox(height: TongtaiDesignTokens.spacing4),
              _ChangeHistory(history: history),
            ],
            const SizedBox(height: TongtaiDesignTokens.spacing8),
          ],
        ),
      ),
      bottomNavigationBar: _SaveCancelBar(
        saveLabel: widget.isEditing
            ? context.l10n.actionSaveChanges
            : context.l10n.customerSave,
        onSave: _save,
        onCancel: _cancel,
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required CustomerField field,
    String? hint,
    bool optional = false,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
  }) {
    final label = optional
        ? '${field.label(context.l10n.languageCode)} ${context.l10n.labelOptionalSuffix}'
        : field.isRequired
        ? '${field.label(context.l10n.languageCode)} *'
        : field.label(context.l10n.languageCode);
    return Padding(
      padding: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing3),
      child: TextField(
        key: key,
        controller: controller,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: _errors[field],
          filled: true,
          fillColor: TongtaiDesignTokens.lightHover,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              TongtaiDesignTokens.componentBorderRadius,
            ),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// Amber "possible duplicate" banner shown while the typed name or phone
/// matches an existing customer (WTM-76 AC5). Informational, not blocking — the
/// seller may genuinely have two customers with the same name.
class _DuplicateWarning extends StatelessWidget {
  const _DuplicateWarning({required this.duplicates});

  final List<Customer> duplicates;

  @override
  Widget build(BuildContext context) {
    const accent = TongtaiDesignTokens.warning;
    return Container(
      key: const Key('customer-duplicate-warning'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing3),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: accent),
              const SizedBox(width: TongtaiDesignTokens.spacing1),
              Expanded(
                child: Text(
                  duplicates.length == 1
                      ? context.l10n.customerPossibleDuplicate
                      : 'Possible duplicate customers (${duplicates.length})',
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing1),
          for (final customer in duplicates.take(3))
            Text(
              '${customer.name} • ${customer.maskedPhone}',
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Quick-pick chips of known cities that fill the city field on tap.
class _LocationSuggestions extends StatelessWidget {
  const _LocationSuggestions({
    required this.locations,
    required this.onSelected,
  });

  final List<String> locations;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing3),
      child: Wrap(
        spacing: TongtaiDesignTokens.spacing2,
        runSpacing: TongtaiDesignTokens.spacing1,
        children: [
          for (final location in locations)
            ActionChip(
              label: Text(location),
              onPressed: () => onSelected(location),
            ),
        ],
      ),
    );
  }
}

/// Multiple delivery/contact addresses with add/remove rows (WTM-76 AC2).
class _AddressesSection extends StatelessWidget {
  const _AddressesSection({
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  final List<TextEditingController> controllers;
  final VoidCallback onAdd;

  /// Removes the row at the given index; `null` when only one row is left (the
  /// last row stays so the section never disappears).
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.customerAddressCount(controllers.length),
          style: TongtaiDesignTokens.smallStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        for (var i = 0; i < controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(
              bottom: TongtaiDesignTokens.spacing2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('customer-address-field-$i'),
                    controller: controllers[i],
                    decoration: InputDecoration(
                      hintText: context.l10n.custAddressHint,
                      filled: true,
                      fillColor: TongtaiDesignTokens.lightHover,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          TongtaiDesignTokens.componentBorderRadius,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    key: Key('customer-address-remove-$i'),
                    tooltip: context.l10n.custRemoveAddress,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: TongtaiDesignTokens.errorText,
                    onPressed: () => onRemove!(i),
                  ),
              ],
            ),
          ),
        OutlinedButton.icon(
          key: const Key('customer-add-address'),
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(context.l10n.custAddAddress),
        ),
      ],
    );
  }
}

/// Segment picker: suggested-segment chips plus a free-text input for custom
/// segments (WTM-76 AC1).
class _SegmentsSection extends StatelessWidget {
  const _SegmentsSection({
    required this.selected,
    required this.input,
    required this.onToggle,
    required this.onAddCustom,
  });

  final List<String> selected;
  final TextEditingController input;
  final void Function(String segment, bool selected) onToggle;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    // Suggestions first, then any custom segments the seller has added.
    final options = [
      ...kTongtaiSegmentSuggestions,
      for (final segment in selected)
        if (!kTongtaiSegmentSuggestions.contains(segment)) segment,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.custSegments,
          style: TongtaiDesignTokens.smallStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        Wrap(
          spacing: TongtaiDesignTokens.spacing2,
          runSpacing: TongtaiDesignTokens.spacing1,
          children: [
            for (final segment in options)
              FilterChip(
                label: Text(segment),
                selected: selected.contains(segment),
                onSelected: (value) => onToggle(segment, value),
              ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('customer-segment-input'),
                controller: input,
                onSubmitted: (_) => onAddCustom(),
                decoration: InputDecoration(
                  hintText: context.l10n.custCustomSegmentHint,
                  isDense: true,
                  filled: true,
                  fillColor: TongtaiDesignTokens.lightHover,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      TongtaiDesignTokens.componentBorderRadius,
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing2),
            OutlinedButton(
              key: const Key('customer-segment-add'),
              onPressed: onAddCustom,
              child: Text(context.l10n.actionAdd),
            ),
          ],
        ),
      ],
    );
  }
}

/// A titled list of field changes (used for both unsaved changes and history).
class _ChangeList extends StatelessWidget {
  const _ChangeList({
    required this.title,
    required this.changes,
    required this.accent,
  });

  final String title;
  final List<CustomerFieldChange> changes;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          for (final change in changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${change.field.label(context.l10n.languageCode)}: '
                '${change.before.isEmpty ? '—' : change.before} → '
                '${change.after.isEmpty ? '—' : change.after}',
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Past revisions of a customer, newest first (WTM-76 AC4).
class _ChangeHistory extends StatelessWidget {
  const _ChangeHistory({required this.history});

  final List<CustomerRevision> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.changeHistory,
          style: TongtaiDesignTokens.smallStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        for (final revision in history)
          Padding(
            padding: const EdgeInsets.only(
              bottom: TongtaiDesignTokens.spacing2,
            ),
            child: _ChangeList(
              title: TongtaiFormatters.isoDate(revision.timestamp),
              changes: revision.changes,
              accent: TongtaiDesignTokens.neutral,
            ),
          ),
      ],
    );
  }
}

/// Sticky bottom bar with Cancel + Save.
class _SaveCancelBar extends StatelessWidget {
  const _SaveCancelBar({
    required this.saveLabel,
    required this.onSave,
    required this.onCancel,
  });

  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
        decoration: const BoxDecoration(
          color: TongtaiDesignTokens.lightBackground,
          border: Border(
            top: BorderSide(color: TongtaiDesignTokens.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    TongtaiDesignTokens.buttonHeight,
                  ),
                ),
                child: Text(context.l10n.actionCancel),
              ),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              flex: 2,
              child: FilledButton(
                key: const Key('customer-save'),
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: TongtaiDesignTokens.consumerBlueText,
                  minimumSize: const Size.fromHeight(
                    TongtaiDesignTokens.buttonHeight,
                  ),
                ),
                child: Text(saveLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
