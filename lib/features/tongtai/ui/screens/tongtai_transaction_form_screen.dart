import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../core/tongtai_enums.dart';
import '../../core/tongtai_formatters.dart';
import '../../finance/finance_transaction.dart';
import '../../finance/transaction_form.dart';
import '../../finance/finance_category.dart';

/// Add Transaction form (WTM-113) — records an income or expense that flows
/// straight into the Finance dashboard. Pops the created [FinanceTransaction]
/// on save, or null on cancel. `clock` is injectable so the default date and
/// the generated id are deterministic under test.
class TongtaiTransactionFormScreen extends StatefulWidget {
  const TongtaiTransactionFormScreen({super.key, this.clock});

  final DateTime Function()? clock;

  @override
  State<TongtaiTransactionFormScreen> createState() =>
      _TongtaiTransactionFormScreenState();
}

class _TongtaiTransactionFormScreenState
    extends State<TongtaiTransactionFormScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final DateTime Function() _clock;
  late TransactionFormData _data;
  bool _submitted = false;
  Map<TransactionField, String> _errors = const {};

  static const Color _income = TtColors.success;
  static const Color _expense = TtColors.danger;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
    _data = TransactionFormData(date: _clock());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<FinanceCategory> get _categories => transactionCategories(_data.type);

  void _update(TransactionFormData next) {
    setState(() {
      _data = next;
      if (_submitted) _errors = _data.validate();
    });
  }

  void _save() {
    setState(() {
      _submitted = true;
      _errors = _data.validate();
    });
    if (_errors.isNotEmpty) return;
    final txn = _data.toTransaction(
      id: 'tx-${_clock().microsecondsSinceEpoch}',
      fallbackDate: _clock(),
    );
    Navigator.of(context).pop(txn);
  }

  Future<void> _pickDate() async {
    final now = _clock();
    final picked = await showDatePicker(
      context: context,
      initialDate: _data.date ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) _update(_data.copyWith(date: picked));
  }

  @override
  Widget build(BuildContext context) {
    final date = _data.date ?? _clock();
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.titleTransactionForm),
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(TtSpace.x4),
        children: [
          // ── Direction: Thu / Chi ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  buttonKey: const Key('transaction-type-income'),
                  label: l10n.txnIncome,
                  icon: Icons.south_west,
                  color: _income,
                  selected: _data.type == TransactionType.income,
                  onTap: () => _update(
                    _data.copyWith(type: TransactionType.income, category: ''),
                  ),
                ),
              ),
              const SizedBox(width: TtSpace.x3),
              Expanded(
                child: _TypeButton(
                  buttonKey: const Key('transaction-type-expense'),
                  label: l10n.txnExpense,
                  icon: Icons.north_east,
                  color: _expense,
                  selected: _data.type == TransactionType.expense,
                  onTap: () => _update(
                    _data.copyWith(type: TransactionType.expense, category: ''),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TtSpace.x5),

          // ── Amount ───────────────────────────────────────────────────
          _Label(l10n.txnAmountLabel),
          const SizedBox(height: TtSpace.x2),
          TextField(
            key: const Key('transaction-amount'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: l10n.txnAmountHint,
              border: const OutlineInputBorder(),
              errorText: _errors[TransactionField.amount],
              suffixText: _data.parsedAmount != null
                  ? TongtaiFormatters.vndShort(_data.parsedAmount!)
                  : null,
            ),
            onChanged: (v) => _update(_data.copyWith(amountText: v)),
          ),
          const SizedBox(height: TtSpace.x4),

          // ── Category ─────────────────────────────────────────────────
          _Label(l10n.txnCategoryLabel),
          const SizedBox(height: TtSpace.x2),
          Wrap(
            spacing: TtSpace.x2,
            children: [
              // Lưu **mã**, hiện **nhãn** (ADR-TON-018). Trước đây chip lưu
              // đúng chuỗi tiếng Việt đang hiện, nên bản tiếng Anh ghi nhãn
              // tiếng Việt xuống sổ.
              for (final c in _categories)
                ChoiceChip(
                  key: Key('transaction-cat-${c.code.replaceAll('_', '-')}'),
                  label: Text(financeCategoryCodeLabel(c.code, l10n)),
                  selected: _data.category == c.code,
                  onSelected: (_) => _update(_data.copyWith(category: c.code)),
                ),
            ],
          ),
          if (_errors[TransactionField.category] != null)
            Padding(
              padding: const EdgeInsets.only(top: TtSpace.x1),
              child: Text(
                _errors[TransactionField.category]!,
                style: TtType.caption.copyWith(color: TtColors.dangerOnLight),
              ),
            ),
          const SizedBox(height: TtSpace.x4),

          // ── Date ─────────────────────────────────────────────────────
          _Label(l10n.txnDateLabel),
          const SizedBox(height: TtSpace.x2),
          OutlinedButton.icon(
            key: const Key('transaction-date'),
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(TongtaiFormatters.isoDate(date)),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: TtSpace.x3,
                vertical: TtSpace.x3,
              ),
            ),
          ),
          const SizedBox(height: TtSpace.x4),

          // ── Description ──────────────────────────────────────────────
          _Label(l10n.txnNoteLabel),
          const SizedBox(height: TtSpace.x2),
          TextField(
            key: const Key('transaction-description'),
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: l10n.txnNoteHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => _update(_data.copyWith(description: v)),
          ),
          const SizedBox(height: TtSpace.x6),

          TtPrimaryButton(
            key: const Key('transaction-save'),
            label: l10n.txnSave,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TtSpace.x3),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(TtRadius.sm),
          border: Border.all(
            color: selected ? color : TtColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : null),
            const SizedBox(width: TtSpace.x2),
            Text(
              label,
              style: TtType.bodyLarge.copyWith(
                // Selected state tints the card at 12 %; the label has to be
                // the readable twin or it sits at 3.23:1 on that tint.
                color: selected
                    ? TtColors.readableOn(color)
                    : TtColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TtType.body.copyWith(
        color: TtColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
