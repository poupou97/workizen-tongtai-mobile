import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../core/tongtai_formatters.dart';
import '../../journey/business_goal.dart';
import '../../journey/business_goal_form.dart';

/// Multi-step Business Goal form (WTM-87 AC1/AC2/AC3).
///
/// Add mode walks three steps — pick a template (AC2), fill the details,
/// review — and edit mode opens straight on the details with the same
/// validation. On Save the screen pops the resulting [BusinessGoal]; on
/// Cancel it pops `null`. The caller (Goals screen) upserts the result —
/// same pop contract as the WTM-69/WTM-76 forms.
class TongtaiGoalFormScreen extends StatefulWidget {
  const TongtaiGoalFormScreen({
    super.key,
    this.goal,
    this.clock,
    this.idFactory,
  });

  /// The goal to edit; `null` puts the form in "add" mode.
  final BusinessGoal? goal;

  /// Injectable clock (defaults to [DateTime.now]) — deterministic templates
  /// and `updatedAt` stamps in tests.
  final DateTime Function()? clock;

  /// Injectable id generator for new goals (defaults to a UUID v4).
  final String Function()? idFactory;

  bool get isEditing => goal != null;

  @override
  State<TongtaiGoalFormScreen> createState() => _TongtaiGoalFormScreenState();
}

class _TongtaiGoalFormScreenState extends State<TongtaiGoalFormScreen> {
  late final DateTime Function() _clock;
  late final String Function() _idFactory;

  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _achieved;
  late final TextEditingController _growthTarget;
  late final TextEditingController _growthAchieved;
  late final TextEditingController _notes;

  late GoalFormData _seed; // non-text fields (type, dates) live here
  int _step = 0; // 0 = template (add only), 1 = details, 2 = review
  bool _submitted = false;
  Map<GoalField, String> _errors = const {};

  bool get _isEditing => widget.isEditing;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
    _idFactory = widget.idFactory ?? const Uuid().v4;
    _seed = _isEditing
        ? GoalFormData.fromGoal(widget.goal!)
        : const GoalFormData();
    _name = TextEditingController(text: _seed.name);
    _target = TextEditingController(text: _seed.targetAmountText);
    _achieved = TextEditingController(text: _seed.achievedAmountText);
    _growthTarget = TextEditingController(text: _seed.growthTargetText);
    _growthAchieved = TextEditingController(text: _seed.growthAchievedText);
    _notes = TextEditingController(text: _seed.notes);
    for (final c in [
      _name,
      _target,
      _achieved,
      _growthTarget,
      _growthAchieved,
      _notes,
    ]) {
      c.addListener(_onFieldChange);
    }
    _step = _isEditing ? 1 : 0;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _target,
      _achieved,
      _growthTarget,
      _growthAchieved,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldChange() {
    if (!mounted) return;
    setState(() {
      if (_submitted) _errors = _currentData().validate();
    });
  }

  GoalFormData _currentData() => _seed.copyWith(
    name: _name.text,
    targetAmountText: _target.text,
    achievedAmountText: _achieved.text,
    growthTargetText: _growthTarget.text,
    growthAchievedText: _growthAchieved.text,
    notes: _notes.text,
  );

  void _applyTemplate(GoalTemplate template) {
    final data = GoalFormData.fromTemplate(template, _clock());
    setState(() {
      _seed = data;
      _name.text = data.name;
      _target.text = data.targetAmountText;
      _growthTarget.text = data.growthTargetText;
      _step = 1;
    });
  }

  void _startBlank() {
    final now = _clock();
    setState(() {
      _seed = GoalFormData(
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 30)),
      );
      _step = 1;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final base = isStart ? _seed.startDate : _seed.endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: base ?? _clock(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _seed = isStart
          ? _seed.copyWith(startDate: picked)
          : _seed.copyWith(endDate: picked);
      if (_submitted) _errors = _currentData().validate();
    });
  }

  void _toReview() {
    final errors = _currentData().validate();
    setState(() {
      _submitted = true;
      _errors = errors;
      if (errors.isEmpty) _step = 2;
    });
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.formFixHighlighted)),
        );
    }
  }

  void _save() {
    final data = _currentData();
    if (!data.isValid) {
      setState(() {
        _submitted = true;
        _errors = data.validate();
        _step = 1;
      });
      return;
    }
    final now = _clock();
    final original = widget.goal;
    final goal = data.toGoal(
      id: original?.id ?? _idFactory(),
      now: now,
      createdAt: original?.createdAt,
    );
    Navigator.of(context).pop(goal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        // Stable test ID carries the *mode*, so behaviour tests never assert
        // on displayed copy — a test that reads the label breaks the moment
        // the label is translated, which is exactly how WTM-194 surfaced.
        title: Text(
          key: Key(_isEditing ? 'goal-form-title-edit' : 'goal-form-title-new'),
          _isEditing
              ? context.l10n.goalFormEditTitle
              : context.l10n.goalFormNewTitle,
        ),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        child: switch (_step) {
          0 => _TemplateStep(onTemplate: _applyTemplate, onBlank: _startBlank),
          1 => _detailsStep(),
          _ => _reviewStep(),
        },
      ),
    );
  }

  Widget _detailsStep() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(TtSpace.x4),
            children: [
              _field(
                key: const Key('goal-name-field'),
                controller: _name,
                field: GoalField.name,
                hint: context.l10n.goalTitleHint,
                required: true,
              ),
              _TypePicker(
                selected: _seed.type,
                onSelected: (type) =>
                    setState(() => _seed = _seed.copyWith(type: type)),
              ),
              const SizedBox(height: TtSpace.x3),
              _field(
                key: const Key('goal-target-field'),
                controller: _target,
                field: GoalField.targetAmount,
                hint: '0',
                suffixText: '₫',
                numeric: true,
              ),
              // Auto-derive (WTM-138, Founder default): for a revenue-
              // denominated goal the achieved revenue is derived from real
              // booked orders — manual entry stays only for KPIs that cannot
              // be derived (the growth metric below).
              if (_isEditing && widget.goal!.targetAmount > 0)
                Padding(
                  key: const Key('goal-achieved-derived-note'),
                  padding: const EdgeInsets.only(bottom: TtSpace.x3),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_mode,
                        size: 16,
                        color: TtColors.textSecondary,
                      ),
                      const SizedBox(width: TtSpace.x2),
                      Expanded(
                        child: Text(
                          context.l10n.goalRealizedHelp,
                          style: TtType.caption.copyWith(
                            color: TtColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_isEditing)
                _field(
                  key: const Key('goal-achieved-field'),
                  controller: _achieved,
                  field: GoalField.achievedAmount,
                  hint: '0',
                  suffixText: '₫',
                  numeric: true,
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      key: const Key('goal-growth-target-field'),
                      controller: _growthTarget,
                      field: GoalField.growthTarget,
                      hint: '0',
                      numeric: true,
                      integerOnly: true,
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(width: TtSpace.x3),
                    Expanded(
                      child: _field(
                        key: const Key('goal-growth-achieved-field'),
                        controller: _growthAchieved,
                        field: GoalField.growthAchieved,
                        hint: '0',
                        numeric: true,
                        integerOnly: true,
                      ),
                    ),
                  ],
                ],
              ),
              _TimelineRow(
                start: _seed.startDate,
                end: _seed.endDate,
                error: _errors[GoalField.timeline],
                onPickStart: () => _pickDate(isStart: true),
                onPickEnd: () => _pickDate(isStart: false),
              ),
              const SizedBox(height: TtSpace.x3),
              _field(
                key: const Key('goal-notes-field'),
                controller: _notes,
                field: GoalField.notes,
                hint: context.l10n.goalNotesHint,
                maxLines: 3,
              ),
              const SizedBox(height: TtSpace.x8),
            ],
          ),
        ),
        _BottomBar(
          primaryLabel: 'Review',
          primaryKey: const Key('goal-next'),
          onPrimary: _toReview,
          secondaryLabel: _isEditing ? 'Cancel' : 'Back',
          onSecondary: _isEditing
              ? () => Navigator.of(context).pop()
              : () => setState(() => _step = 0),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    final now = _clock();
    final data = _currentData();
    final preview = data.toGoal(id: 'preview', now: now);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(TtSpace.x4),
            children: [
              Text(
                preview.name,
                style: TtType.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TtColors.textPrimary,
                ),
              ),
              const SizedBox(height: TtSpace.x3),
              _reviewRow(
                context.l10n.goalReviewType,
                preview.type.label(context.l10n.languageCode),
              ),
              if (preview.targetAmount > 0)
                _reviewRow(
                  context.l10n.goalReviewRevenueTarget,
                  TongtaiFormatters.vnd(preview.targetAmount),
                ),
              if (preview.growthTarget > 0)
                _reviewRow(
                  context.l10n.goalReviewMetricTarget,
                  '${preview.growthTarget}',
                ),
              _reviewRow(
                context.l10n.goalReviewTimeline,
                '${TongtaiFormatters.isoDate(preview.startDate)} → '
                '${TongtaiFormatters.isoDate(preview.endDate)}',
              ),
              if (preview.notes.isNotEmpty)
                _reviewRow(context.l10n.goalReviewNotes, preview.notes),
              const SizedBox(height: TtSpace.x4),
              Container(
                padding: const EdgeInsets.all(TtSpace.x3),
                decoration: BoxDecoration(
                  color: TtColors.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(TtRadius.md),
                  border: Border.all(
                    color: TtColors.info.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  preview.recommendation(now),
                  style: TtType.body.copyWith(color: TtColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          primaryLabel: _isEditing
              ? context.l10n.actionSaveChanges
              : context.l10n.goalFormCreate,
          primaryKey: const Key('goal-save'),
          onPrimary: _save,
          secondaryLabel: 'Back',
          onSecondary: () => setState(() => _step = 1),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TtSpace.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TtType.body.copyWith(
                color: TtColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TtType.body.copyWith(color: TtColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required GoalField field,
    String? hint,
    String? suffixText,
    bool required = false,
    bool numeric = false,
    bool integerOnly = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TtSpace.x3),
      child: TextField(
        key: key,
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        inputFormatters: numeric
            ? [
                integerOnly
                    ? FilteringTextInputFormatter.digitsOnly
                    : FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ]
            : null,
        decoration: InputDecoration(
          labelText: required
              ? '${field.label(context.l10n.languageCode)} *'
              : field.label(context.l10n.languageCode),
          hintText: hint,
          suffixText: suffixText,
          errorText: _errors[field],
          filled: true,
          fillColor: TtColors.surfaceTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TtRadius.sm),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// Step 1 (add mode): pick a goal template or start blank (AC2).
class _TemplateStep extends StatelessWidget {
  const _TemplateStep({required this.onTemplate, required this.onBlank});

  final ValueChanged<GoalTemplate> onTemplate;
  final VoidCallback onBlank;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(TtSpace.x4),
      children: [
        Text(
          l10n.goalWhatToAchieve,
          style: TtType.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: TtColors.textPrimary,
          ),
        ),
        const SizedBox(height: TtSpace.x3),
        for (final template in kTongtaiGoalTemplates)
          Padding(
            padding: const EdgeInsets.only(bottom: TtSpace.x3),
            child: InkWell(
              key: Key('goal-template-${template.type.name}'),
              borderRadius: BorderRadius.circular(TtRadius.md),
              onTap: () => onTemplate(template),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TtSpace.x3),
                decoration: BoxDecoration(
                  color: TtColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(TtRadius.md),
                  border: Border.all(color: TtColors.border),
                  boxShadow: TtElevation.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.nameVi,
                      style: TtType.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TtColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.goalTemplateDays(
                        template.type.label(l10n.languageCode),
                        template.suggestedDays,
                      ),
                      style: TtType.caption.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        OutlinedButton.icon(
          key: const Key('goal-template-blank'),
          onPressed: onBlank,
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.goalCustom),
        ),
      ],
    );
  }
}

/// Goal-type chips shown on the details step.
class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.selected, required this.onSelected});

  final GoalType selected;
  final ValueChanged<GoalType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TtSpace.x2,
      runSpacing: TtSpace.x1,
      children: [
        for (final type in GoalType.values)
          ChoiceChip(
            key: Key('goal-type-${type.name}'),
            label: Text(type.label(context.l10n.languageCode)),
            selected: selected == type,
            onSelected: (_) => onSelected(type),
          ),
      ],
    );
  }
}

/// Start/end date pickers with the shared timeline validation error (AC1).
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.start,
    required this.end,
    required this.error,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime? start;
  final DateTime? end;
  final String? error;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('goal-start-date'),
                onPressed: onPickStart,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  start == null
                      ? context.l10n.goalStartDate
                      : TongtaiFormatters.isoDate(start!),
                ),
              ),
            ),
            const SizedBox(width: TtSpace.x3),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('goal-end-date'),
                onPressed: onPickEnd,
                icon: const Icon(Icons.event_outlined, size: 16),
                label: Text(
                  end == null
                      ? context.l10n.goalEndDate
                      : TongtaiFormatters.isoDate(end!),
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: TtSpace.x1),
            child: Text(
              error!,
              style: TtType.caption.copyWith(color: TtColors.dangerOnLight),
            ),
          ),
      ],
    );
  }
}

/// Sticky bottom bar shared by the details and review steps.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.primaryLabel,
    required this.primaryKey,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String primaryLabel;
  final Key primaryKey;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(TtSpace.x4),
        decoration: const BoxDecoration(
          color: TtColors.surfaceSecondary,
          border: Border(top: BorderSide(color: TtColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(TtButtonMetrics.height),
                ),
                child: Text(secondaryLabel),
              ),
            ),
            const SizedBox(width: TtSpace.x3),
            Expanded(
              flex: 2,
              child: TtPrimaryButton(
                key: primaryKey,
                label: primaryLabel,
                onPressed: onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
