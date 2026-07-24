import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/tongtai_enums.dart';
import '../../core/tongtai_formatters.dart';
import '../../finance/finance_transaction.dart';
import '../../finance/transaction_form.dart';
import '../../navigation/tongtai_design_tokens.dart';

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

  static const Color _income = TongtaiDesignTokens.producerGreen;
  static const Color _expense = TongtaiDesignTokens.error;

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

  List<String> get _categories => _data.type == TransactionType.income
      ? kIncomeCategories
      : kExpenseCategories;

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
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Ghi giao dịch'),
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
        children: [
          // ── Direction: Thu / Chi ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  buttonKey: const Key('transaction-type-income'),
                  label: 'Thu',
                  icon: Icons.south_west,
                  color: _income,
                  selected: _data.type == TransactionType.income,
                  onTap: () => _update(
                    _data.copyWith(type: TransactionType.income, category: ''),
                  ),
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Expanded(
                child: _TypeButton(
                  buttonKey: const Key('transaction-type-expense'),
                  label: 'Chi',
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
          const SizedBox(height: TongtaiDesignTokens.spacing5),

          // ── Amount ───────────────────────────────────────────────────
          _Label('Số tiền (₫)'),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          TextField(
            key: const Key('transaction-amount'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Ví dụ: 1500000',
              border: const OutlineInputBorder(),
              errorText: _errors[TransactionField.amount],
              suffixText: _data.parsedAmount != null
                  ? TongtaiFormatters.vndShort(_data.parsedAmount!)
                  : null,
            ),
            onChanged: (v) => _update(_data.copyWith(amountText: v)),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing4),

          // ── Category ─────────────────────────────────────────────────
          _Label('Nhóm'),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          Wrap(
            spacing: TongtaiDesignTokens.spacing2,
            children: [
              for (final c in _categories)
                ChoiceChip(
                  key: Key('transaction-cat-$c'),
                  label: Text(c),
                  selected: _data.category == c,
                  onSelected: (_) => _update(_data.copyWith(category: c)),
                ),
            ],
          ),
          if (_errors[TransactionField.category] != null)
            Padding(
              padding: const EdgeInsets.only(top: TongtaiDesignTokens.spacing1),
              child: Text(
                _errors[TransactionField.category]!,
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.error,
                ),
              ),
            ),
          const SizedBox(height: TongtaiDesignTokens.spacing4),

          // ── Date ─────────────────────────────────────────────────────
          _Label('Ngày'),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          OutlinedButton.icon(
            key: const Key('transaction-date'),
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(TongtaiFormatters.isoDate(date)),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: TongtaiDesignTokens.spacing3,
                vertical: TongtaiDesignTokens.spacing3,
              ),
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing4),

          // ── Description ──────────────────────────────────────────────
          _Label('Ghi chú (không bắt buộc)'),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          TextField(
            key: const Key('transaction-description'),
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Bán lô quạt cho khách sỉ',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _update(_data.copyWith(description: v)),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing6),

          FilledButton(
            key: const Key('transaction-save'),
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: TongtaiDesignTokens.financePurple,
              padding: const EdgeInsets.symmetric(
                vertical: TongtaiDesignTokens.spacing4,
              ),
            ),
            child: const Text('Lưu giao dịch'),
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
        padding: const EdgeInsets.symmetric(
          vertical: TongtaiDesignTokens.spacing3,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(
            TongtaiDesignTokens.componentBorderRadius,
          ),
          border: Border.all(
            color: selected ? color : TongtaiDesignTokens.lightBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : null),
            const SizedBox(width: TongtaiDesignTokens.spacing2),
            Text(
              label,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: selected ? color : TongtaiDesignTokens.lightTextPrimary,
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
      style: TongtaiDesignTokens.smallStyle.copyWith(
        color: TongtaiDesignTokens.lightTextSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
