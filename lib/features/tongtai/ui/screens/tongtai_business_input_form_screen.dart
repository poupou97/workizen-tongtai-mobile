import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../producer/business_input.dart';

/// Form thêm/sửa một **nguồn đầu vào** (WTM-234 / ADR-TON-023).
///
/// Pop trả về [BusinessInput] khi lưu, `null` khi huỷ — cùng hợp đồng với các
/// form WTM-69/WTM-87; màn danh sách là nơi ghi xuống repository.
///
/// Hai ô **cố tình không bắt buộc**: nhịp trả tiền và số tiền. Người bán mới
/// nhớ ra "à, mình có trả tiền Firebase" thường chưa biết chính xác bao nhiêu;
/// bắt điền là buộc họ **bịa một con số**, và con số bịa đó sẽ đi thẳng vào
/// tổng cam kết như thể nó có thật.
class TongtaiBusinessInputFormScreen extends StatefulWidget {
  const TongtaiBusinessInputFormScreen({
    super.key,
    this.input,
    this.clock,
    this.idFactory,
  });

  /// Nguồn đang sửa; `null` = thêm mới.
  final BusinessInput? input;

  final DateTime Function()? clock;
  final String Function()? idFactory;

  bool get isEditing => input != null;

  @override
  State<TongtaiBusinessInputFormScreen> createState() =>
      _TongtaiBusinessInputFormScreenState();
}

class _TongtaiBusinessInputFormScreenState
    extends State<TongtaiBusinessInputFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final DateTime Function() _clock;
  late final String Function() _idFactory;

  late BusinessInputKind _kind;

  /// `null` = người bán chưa nói nhịp trả tiền — một trạng thái hợp lệ, không
  /// phải một ô chưa điền xong.
  InputCadence? _cadence;

  bool _nameMissing = false;

  @override
  void initState() {
    super.initState();
    final input = widget.input;
    _name = TextEditingController(text: input?.name ?? '');
    _amount = TextEditingController(
      text: input?.expectedAmount == null
          ? ''
          : _amountText(input!.expectedAmount!),
    );
    _note = TextEditingController(text: input?.note ?? '');
    _kind = input?.kind ?? BusinessInputKind.supplier;
    _cadence = input?.cadence;
    _clock = widget.clock ?? DateTime.now;
    _idFactory = widget.idFactory ?? const Uuid().v4;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _amountText(double value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    final amountText = _amount.text.trim();
    Navigator.of(context).pop(
      BusinessInput(
        id: widget.input?.id ?? _idFactory(),
        name: name,
        kind: _kind,
        cadence: _cadence,
        // Ô trống ⇒ `null`, KHÔNG phải 0: 0 nói "nguồn này không tốn gì".
        expectedAmount: amountText.isEmpty ? null : double.tryParse(amountText),
        note: _note.text.trim(),
        updatedAt: _clock(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        key: const Key('input-form-header'),
        title: Text(
          widget.isEditing ? l10n.inputEditTitle : l10n.inputAddTitle,
        ),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TtSpace.x4),
          children: [
            _label(l10n.inputKindLabel),
            Wrap(
              spacing: TtSpace.x2,
              runSpacing: TtSpace.x1,
              children: [
                for (final kind in BusinessInputKind.values)
                  ChoiceChip(
                    key: Key('input-kind-${kind.code}'),
                    label: Text(l10n.inputKindName(kind.code)),
                    selected: kind == _kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: TtSpace.x4),
            TextField(
              key: const Key('input-name-field'),
              controller: _name,
              onChanged: (_) {
                if (_nameMissing) setState(() => _nameMissing = false);
              },
              decoration: _decoration(
                label: '${l10n.inputNameLabel} *',
                hint: l10n.inputNameHint,
                error: _nameMissing ? l10n.inputNameRequired : null,
              ),
            ),
            const SizedBox(height: TtSpace.x3),
            _label(l10n.inputCadenceLabel),
            Wrap(
              spacing: TtSpace.x2,
              runSpacing: TtSpace.x1,
              children: [
                for (final cadence in InputCadence.values)
                  ChoiceChip(
                    key: Key('input-cadence-${cadence.code}'),
                    label: Text(l10n.inputCadenceName(cadence.code)),
                    selected: cadence == _cadence,
                    // Bấm lại nhịp đang chọn = bỏ chọn: "chưa biết" phải quay
                    // về được, nếu không người bán bị kẹt vào lần bấm nhầm và
                    // tổng cam kết mang một con số họ không đứng sau.
                    onSelected: (selected) =>
                        setState(() => _cadence = selected ? cadence : null),
                  ),
              ],
            ),
            const SizedBox(height: TtSpace.x3),
            TextField(
              key: const Key('input-amount-field'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: _decoration(
                label:
                    '${l10n.inputAmountLabel} '
                    '${l10n.labelOptionalSuffix}',
                hint: '0',
                suffix: '₫',
              ),
            ),
            // Nói ngay tại chỗ vì sao một con số đã nhập vẫn không vào tổng —
            // không nói thì người bán sẽ đọc tổng như một tổng đầy đủ.
            if (_cadence != null && !_cadence!.isCommitment)
              Padding(
                key: const Key('input-not-commitment-note'),
                padding: const EdgeInsets.only(top: TtSpace.x2),
                child: Text(
                  l10n.inputNotCommitmentNote,
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
              ),
            const SizedBox(height: TtSpace.x3),
            TextField(
              key: const Key('input-note-field'),
              controller: _note,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration(
                label: '${l10n.inputNoteLabel} ${l10n.labelOptionalSuffix}',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
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
                  key: const Key('input-cancel-button'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(TtButtonMetrics.height),
                  ),
                  child: Text(l10n.actionCancel),
                ),
              ),
              const SizedBox(width: TtSpace.x3),
              Expanded(
                flex: 2,
                child: TtPrimaryButton(
                  key: const Key('input-save-button'),
                  label: l10n.actionSave,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: TtSpace.x2),
    child: Text(
      text,
      style: TtType.body.copyWith(
        fontWeight: FontWeight.w600,
        color: TtColors.textPrimary,
      ),
    ),
  );

  InputDecoration _decoration({
    required String label,
    String? hint,
    String? suffix,
    String? error,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    suffixText: suffix,
    errorText: error,
    filled: true,
    fillColor: TtColors.surfaceTertiary,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TtRadius.sm),
      borderSide: BorderSide.none,
    ),
  );
}
