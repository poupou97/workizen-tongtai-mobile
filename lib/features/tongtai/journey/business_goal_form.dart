import 'package:flutter/foundation.dart';

import 'business_goal.dart';

/// The editable fields of a [BusinessGoal] (WTM-87). Keys the form-validation
/// errors — same one-enum convention as `ProductField` / `CustomerField`.
enum GoalField {
  name,
  targetAmount,
  achievedAmount,
  growthTarget,
  growthAchieved,
  timeline,
  notes;

  String get labelEn => switch (this) {
    GoalField.name => 'Goal name',
    GoalField.targetAmount => 'Revenue target',
    GoalField.achievedAmount => 'Revenue so far',
    GoalField.growthTarget => 'Metric target',
    GoalField.growthAchieved => 'Metric so far',
    GoalField.timeline => 'Timeline',
    GoalField.notes => 'Notes',
  };

  String get labelVi => switch (this) {
    GoalField.name => 'Tên mục tiêu',
    GoalField.targetAmount => 'Mục tiêu doanh thu',
    GoalField.achievedAmount => 'Doanh thu đã đạt',
    GoalField.growthTarget => 'Chỉ tiêu phụ',
    GoalField.growthAchieved => 'Đã đạt (chỉ tiêu phụ)',
    GoalField.timeline => 'Khung thời gian',
    GoalField.notes => 'Ghi chú',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// Immutable snapshot of the multi-step goal form (WTM-87 AC1).
///
/// Numeric fields are raw text so the form can validate user input before
/// parsing — same pure-Dart pattern as `ProductFormData` (WTM-69) and
/// `CustomerFormData` (WTM-76), so every rule is unit-testable without
/// pumping a screen.
@immutable
class GoalFormData {
  const GoalFormData({
    this.name = '',
    this.type = GoalType.revenue,
    this.targetAmountText = '',
    this.achievedAmountText = '',
    this.growthTargetText = '',
    this.growthAchievedText = '',
    this.startDate,
    this.endDate,
    this.notes = '',
  });

  /// Seed the form from a template (add mode, AC2). The timeline starts at
  /// [now] and runs for the template's suggested length.
  factory GoalFormData.fromTemplate(GoalTemplate template, DateTime now) {
    return GoalFormData(
      name: template.nameVi,
      type: template.type,
      targetAmountText: template.suggestedTarget <= 0
          ? ''
          : template.suggestedTarget.round().toString(),
      growthTargetText: template.suggestedGrowthTarget.toString(),
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: template.suggestedDays)),
    );
  }

  /// Seed the form from an existing goal (edit mode, AC3).
  factory GoalFormData.fromGoal(BusinessGoal goal) => GoalFormData(
    name: goal.name,
    type: goal.type,
    targetAmountText: goal.targetAmount <= 0
        ? ''
        : goal.targetAmount.round().toString(),
    achievedAmountText: goal.achievedAmount <= 0
        ? ''
        : goal.achievedAmount.round().toString(),
    growthTargetText: goal.growthTarget <= 0
        ? ''
        : goal.growthTarget.toString(),
    growthAchievedText: goal.growthAchieved <= 0
        ? ''
        : goal.growthAchieved.toString(),
    startDate: goal.startDate,
    endDate: goal.endDate,
    notes: goal.notes,
  );

  final String name;
  final GoalType type;
  final String targetAmountText;
  final String achievedAmountText;
  final String growthTargetText;
  final String growthAchievedText;
  final DateTime? startDate;
  final DateTime? endDate;
  final String notes;

  GoalFormData copyWith({
    String? name,
    GoalType? type,
    String? targetAmountText,
    String? achievedAmountText,
    String? growthTargetText,
    String? growthAchievedText,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) {
    return GoalFormData(
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmountText: targetAmountText ?? this.targetAmountText,
      achievedAmountText: achievedAmountText ?? this.achievedAmountText,
      growthTargetText: growthTargetText ?? this.growthTargetText,
      growthAchievedText: growthAchievedText ?? this.growthAchievedText,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }

  double? get parsedTargetAmount => double.tryParse(targetAmountText.trim());
  double? get parsedAchievedAmount =>
      double.tryParse(achievedAmountText.trim());
  int? get parsedGrowthTarget => int.tryParse(growthTargetText.trim());
  int? get parsedGrowthAchieved => int.tryParse(growthAchievedText.trim());

  /// Field-keyed validation errors (AC1). An empty map means the form is
  /// valid. Rules:
  ///  - name required;
  ///  - at least ONE target (revenue or growth metric) must be a positive
  ///    number — a goal with nothing to reach cannot be tracked (AC4);
  ///  - numeric fields must parse and be non-negative when present;
  ///  - both timeline dates required, end strictly after start.
  Map<GoalField, String> validate() {
    final errors = <GoalField, String>{};

    if (name.trim().isEmpty) {
      errors[GoalField.name] = 'Goal name is required';
    }

    final target = _validateAmount(
      targetAmountText,
      errors,
      GoalField.targetAmount,
      'Revenue target',
    );
    _validateAmount(
      achievedAmountText,
      errors,
      GoalField.achievedAmount,
      'Revenue so far',
    );
    final growth = _validateCount(
      growthTargetText,
      errors,
      GoalField.growthTarget,
      'Metric target',
    );
    _validateCount(
      growthAchievedText,
      errors,
      GoalField.growthAchieved,
      'Metric so far',
    );

    final hasRevenueTarget = (target ?? 0) > 0;
    final hasGrowthTarget = (growth ?? 0) > 0;
    if (!errors.containsKey(GoalField.targetAmount) &&
        !errors.containsKey(GoalField.growthTarget) &&
        !hasRevenueTarget &&
        !hasGrowthTarget) {
      errors[GoalField.targetAmount] =
          'Set a revenue target or a metric target';
    }

    if (startDate == null || endDate == null) {
      errors[GoalField.timeline] = 'Start and end dates are required';
    } else if (!endDate!.isAfter(startDate!)) {
      errors[GoalField.timeline] = 'End date must be after the start date';
    }

    return errors;
  }

  double? _validateAmount(
    String text,
    Map<GoalField, String> errors,
    GoalField field,
    String label,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final value = double.tryParse(trimmed);
    if (value == null) {
      errors[field] = '$label must be a number';
      return null;
    }
    if (value < 0) {
      errors[field] = '$label cannot be negative';
      return null;
    }
    return value;
  }

  int? _validateCount(
    String text,
    Map<GoalField, String> errors,
    GoalField field,
    String label,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final value = int.tryParse(trimmed);
    if (value == null) {
      errors[field] = '$label must be a whole number';
      return null;
    }
    if (value < 0) {
      errors[field] = '$label cannot be negative';
      return null;
    }
    return value;
  }

  /// Whether every rule passes.
  bool get isValid => validate().isEmpty;

  /// Build a [BusinessGoal] from this form. Callers should check [isValid]
  /// first; unparseable numbers fall back to 0 so this never throws.
  BusinessGoal toGoal({
    required String id,
    required DateTime now,
    DateTime? createdAt,
  }) {
    return BusinessGoal(
      id: id,
      name: name.trim(),
      type: type,
      targetAmount: parsedTargetAmount ?? 0,
      achievedAmount: parsedAchievedAmount ?? 0,
      growthTarget: parsedGrowthTarget ?? 0,
      growthAchieved: parsedGrowthAchieved ?? 0,
      startDate: startDate ?? now,
      endDate: endDate ?? now,
      notes: notes.trim(),
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }
}
