import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design/tt.dart';

import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../inventory/product_form.dart';
import '../../inventory/product_history.dart';
import '../../inventory/product_image_source.dart';
import '../../../../core/l10n/app_strings.dart';

/// Add / Edit Product form (WTM-69).
///
/// One screen serves both flows: pass [product] to edit it, or omit it to add a
/// new one. Covers every acceptance criterion —
/// - fields: name, SKU, category, unit price, quantity (+ optional reorder level),
/// - product images uploaded or camera-captured via [imageSource] (AC2),
/// - a markdown description with a live preview (AC3),
/// - edit mode records a change history and shows past revisions (AC4),
/// - Save/Cancel with required-field validation (AC5).
///
/// On Save the screen pops the resulting [Product] (built via [ProductEditor]);
/// on Cancel it pops `null`. The caller (Inventory screen) upserts the result.
class TongtaiProductFormScreen extends StatefulWidget {
  const TongtaiProductFormScreen({
    super.key,
    this.product,
    this.categories = const [],
    this.isSkuTaken,
    this.imageSource,
    this.clock,
    this.idFactory,
  });

  /// The product to edit; `null` puts the form in "add" mode.
  final Product? product;

  /// Known categories offered as quick-pick chips under the category field.
  final List<String> categories;

  /// Returns `true` if the given SKU is already used by another product. Wired by
  /// the caller to the catalog; `null` disables the uniqueness check.
  final bool Function(String sku)? isSkuTaken;

  /// Where product photos come from; defaults to the real `image_picker` source.
  final ProductImageSource? imageSource;

  /// Injectable clock (defaults to [DateTime.now]) — set in tests for
  /// deterministic `updatedAt`/revision timestamps.
  final DateTime Function()? clock;

  /// Injectable id generator for new products (defaults to a UUID v4).
  final String Function()? idFactory;

  bool get isEditing => product != null;

  @override
  State<TongtaiProductFormScreen> createState() =>
      _TongtaiProductFormScreenState();
}

class _TongtaiProductFormScreenState extends State<TongtaiProductFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _costPrice;

  /// Loại sản phẩm đang chọn (ADR-TON-023). Sản phẩm mới mặc định `physical` —
  /// đó là loại hình phổ biến nhất của người dùng hôm nay, và người bán đổi
  /// được ngay trên form.
  late ProductKind _kind;
  late final TextEditingController _quantity;
  late final TextEditingController _reorder;
  late final TextEditingController _description;

  late final List<TextEditingController> _controllers;
  late final ProductImageSource _imageSource;
  late final DateTime Function() _clock;
  late final String Function() _idFactory;

  final List<String> _imagePaths = [];

  /// Field-keyed errors, populated after the first Save attempt.
  Map<ProductField, String> _errors = const {};
  bool _submitted = false;
  bool _previewDescription = false;

  @override
  void initState() {
    super.initState();
    final data = widget.product == null
        ? const ProductFormData()
        : ProductFormData.fromProduct(widget.product!);
    _kind = data.kind;
    _name = TextEditingController(text: data.name);
    _sku = TextEditingController(text: data.sku);
    _category = TextEditingController(text: data.category);
    _price = TextEditingController(text: data.priceText);
    _costPrice = TextEditingController(text: data.costPriceText);
    _quantity = TextEditingController(text: data.quantityText);
    _reorder = TextEditingController(text: data.reorderLevelText);
    _description = TextEditingController(text: data.description);
    _imagePaths.addAll(data.imagePaths);

    _controllers = [
      _name,
      _sku,
      _category,
      _price,
      _costPrice,
      _quantity,
      _reorder,
      _description,
    ];
    for (final c in _controllers) {
      c.addListener(_handleFieldChange);
    }

    _imageSource = widget.imageSource ?? ImagePickerProductImageSource();
    _clock = widget.clock ?? DateTime.now;
    _idFactory = widget.idFactory ?? const Uuid().v4;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_handleFieldChange);
      c.dispose();
    }
    super.dispose();
  }

  // Rebuild on every keystroke so the live change preview + markdown preview stay
  // current, and re-run validation once the user has attempted a save.
  void _handleFieldChange() {
    if (!mounted) return;
    setState(() {
      if (_submitted) _errors = _validate(_currentData());
    });
  }

  ProductFormData _currentData() => ProductFormData(
    name: _name.text,
    sku: _sku.text,
    category: _category.text,
    description: _description.text,
    kind: _kind,
    priceText: _price.text,
    costPriceText: _costPrice.text,
    quantityText: _quantity.text,
    reorderLevelText: _reorder.text,
    imagePaths: _imagePaths,
  );

  /// Domain validation plus the SKU-uniqueness check layered on top.
  Map<ProductField, String> _validate(ProductFormData data) {
    final errors = Map<ProductField, String>.from(data.validate());
    if (!errors.containsKey(ProductField.sku)) {
      final taken = widget.isSkuTaken?.call(data.sku.trim()) ?? false;
      if (taken) errors[ProductField.sku] = context.l10n.productSkuExists;
    }
    return errors;
  }

  void _save() {
    final data = _currentData();
    final errors = _validate(data);
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
    final now = _clock();
    final original = widget.product;
    final result = original == null
        ? ProductEditor.create(data, id: _idFactory(), now: now)
        : ProductEditor.applyEdit(original, data, now: now);
    Navigator.of(context).pop(result);
  }

  void _cancel() => Navigator.of(context).pop();

  Future<void> _addImage({required bool fromCamera}) async {
    final path = fromCamera
        ? await _imageSource.captureFromCamera()
        : await _imageSource.pickFromGallery();
    if (!mounted || path == null) return;
    setState(() => _imagePaths.add(path));
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  /// The unsaved diff of the current form against the product being edited.
  List<ProductFieldChange> _pendingChanges() {
    final original = widget.product;
    if (original == null) return const [];
    final edited = _currentData().toProduct(
      id: original.id,
      updatedAt: _clock(),
    );
    return ProductEditor.diff(original, edited);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pendingChanges();
    final history = widget.product?.history ?? const <ProductRevision>[];

    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? context.l10n.titleEditProduct
              : context.l10n.titleAddProduct,
        ),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TtSpace.x4),
          children: [
            // Đứng trước mọi ô khác vì nó quyết định các ô sau còn nghĩa hay
            // không: chọn "Sản phẩm số" thì tồn kho biến mất và "giá vốn" đổi
            // tên thành "chi phí mỗi lượt bán".
            _KindPicker(
              selected: _kind,
              onSelected: (kind) => setState(() {
                _kind = kind;
                if (_submitted) _errors = _validate(_currentData());
              }),
            ),
            _field(
              key: const Key('product-name-field'),
              controller: _name,
              field: ProductField.name,
              hint: context.l10n.productNameHint,
            ),
            _field(
              key: const Key('product-sku-field'),
              controller: _sku,
              field: ProductField.sku,
              hint: 'e.g. SKU-EL-001',
              textCapitalization: TextCapitalization.characters,
            ),
            _field(
              key: const Key('product-category-field'),
              controller: _category,
              field: ProductField.category,
              hint: context.l10n.productCategoryHint,
            ),
            _CategorySuggestions(
              categories: widget.categories,
              onSelected: (c) {
                _category.text = c;
                _category.selection = TextSelection.collapsed(offset: c.length);
              },
            ),
            _field(
              key: const Key('product-price-field'),
              controller: _price,
              field: ProductField.unitPrice,
              hint: '0',
              suffixText: '₫',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            // WTM-204: optional on purpose. Empty means `costPrice = null` —
            // "not entered", never 0, which would claim the stock is free and
            // print a 100% margin nobody computed. This one field unblocks
            // real opportunity ROI, the High Risk badge and per-product margin.
            _field(
              key: const Key('product-cost-price-field'),
              controller: _costPrice,
              field: ProductField.costPrice,
              // WTM-231: cùng một con số, khác cách gọi. Người bán hàng vật lý
              // nghĩ "giá nhập"; người bán sản phẩm số nghĩ "chi phí mỗi lượt
              // bán" (token AI, phí cổng thanh toán). Ý nghĩa và phép tính
              // KHÔNG đổi — chỉ nhãn đổi, nên vẫn là một trường, một chủ.
              labelOverride: _kind == ProductKind.physical
                  ? null
                  : context.l10n.productVariableCostLabel,
              hint: '0',
              suffixText: '₫',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            // Hai ô này BIẾN MẤT cho loại không có tồn kho, chứ không bị làm
            // mờ: một ô xám vẫn nói "khái niệm này có thật với bạn, bạn chưa
            // điền" — và người bán phần mềm sẽ đi tìm cách điền nó.
            if (_kind.tracksStock)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      key: const Key('product-quantity-field'),
                      controller: _quantity,
                      field: ProductField.quantity,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: TtSpace.x3),
                  Expanded(
                    child: _field(
                      key: const Key('product-reorder-field'),
                      controller: _reorder,
                      field: ProductField.reorderLevel,
                      hint: '0',
                      optional: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              )
            else
              Padding(
                key: const Key('product-no-stock-note'),
                padding: const EdgeInsets.only(bottom: TtSpace.x3),
                child: Text(
                  context.l10n.productKindNoStockNote,
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
              ),
            const SizedBox(height: TtSpace.x4),
            _DescriptionField(
              controller: _description,
              preview: _previewDescription,
              onTogglePreview: (preview) =>
                  setState(() => _previewDescription = preview),
            ),
            const SizedBox(height: TtSpace.x4),
            _ImagesSection(
              paths: _imagePaths,
              onUpload: () => _addImage(fromCamera: false),
              onCamera: () => _addImage(fromCamera: true),
              onRemove: _removeImage,
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: TtSpace.x4),
              _ChangeList(
                title: context.l10n.unsavedChanges(pending.length),
                changes: pending,
                accent: TtColors.info,
              ),
            ],
            if (history.isNotEmpty) ...[
              const SizedBox(height: TtSpace.x4),
              _ChangeHistory(history: history),
            ],
            const SizedBox(height: TtSpace.x8),
          ],
        ),
      ),
      bottomNavigationBar: _SaveCancelBar(
        saveLabel: widget.isEditing
            ? context.l10n.formSaveChanges
            : context.l10n.formSaveProduct,
        onSave: _save,
        onCancel: _cancel,
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required ProductField field,
    String? labelOverride,
    String? hint,
    String? suffixText,
    bool optional = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final code = context.l10n.languageCode;
    final base = labelOverride ?? field.label(code);
    final label = optional
        ? '$base ${context.l10n.labelOptionalSuffix}'
        : field.isRequired
        ? '$base *'
        : base;
    return Padding(
      padding: const EdgeInsets.only(bottom: TtSpace.x3),
      child: TextField(
        key: key,
        controller: controller,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
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

/// Ô chọn loại sản phẩm (WTM-233 / ADR-TON-023).
///
/// `ProductKind` đã có trong miền từ WTM-227 nhưng **không có đường nào để
/// người bán chọn**, nên với họ ADR chưa hề xảy ra: mọi sản phẩm mới vẫn là
/// hàng vật lý và một phần mềm vẫn phải mang một con số tồn kho.
///
/// Suy thẳng từ `ProductKind.values` — chép tay danh sách là đúng lỗi vừa bắt
/// được ở WTM-232, nơi kịch bản onboarding giữ bảy mã trong khi enum đã có
/// mười.
class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.selected, required this.onSelected});

  final ProductKind selected;
  final ValueChanged<ProductKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TtSpace.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.productKindLabel,
            style: TtType.body.copyWith(
              fontWeight: FontWeight.w600,
              color: TtColors.textPrimary,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          Wrap(
            spacing: TtSpace.x2,
            runSpacing: TtSpace.x1,
            children: [
              for (final kind in ProductKind.values)
                ChoiceChip(
                  key: Key('product-kind-${kind.code}'),
                  label: Text(context.l10n.productKindName(kind.code)),
                  selected: kind == selected,
                  onSelected: (_) => onSelected(kind),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick-pick chips of existing categories that fill the category field on tap.
class _CategorySuggestions extends StatelessWidget {
  const _CategorySuggestions({
    required this.categories,
    required this.onSelected,
  });

  final List<String> categories;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: TtSpace.x3),
      child: Wrap(
        spacing: TtSpace.x2,
        runSpacing: TtSpace.x1,
        children: [
          for (final category in categories)
            ActionChip(
              label: Text(category),
              onPressed: () => onSelected(category),
            ),
        ],
      ),
    );
  }
}

/// Description field with a Write/Preview toggle. In preview mode it renders the
/// text as markdown (WTM-69 AC3).
class _DescriptionField extends StatelessWidget {
  const _DescriptionField({
    required this.controller,
    required this.preview,
    required this.onTogglePreview,
  });

  final TextEditingController controller;
  final bool preview;
  final ValueChanged<bool> onTogglePreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.labelDescription,
                overflow: TextOverflow.ellipsis,
                style: TtType.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TtColors.textPrimary,
                ),
              ),
            ),
            ChoiceChip(
              label: Text(context.l10n.formWrite),
              selected: !preview,
              onSelected: (_) => onTogglePreview(false),
            ),
            const SizedBox(width: TtSpace.x2),
            ChoiceChip(
              label: Text(context.l10n.formPreview),
              selected: preview,
              onSelected: (_) => onTogglePreview(true),
            ),
          ],
        ),
        const SizedBox(height: TtSpace.x2),
        if (preview)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.all(TtSpace.x3),
            decoration: BoxDecoration(
              color: TtColors.surfaceTertiary,
              borderRadius: BorderRadius.circular(TtRadius.sm),
              border: Border.all(color: TtColors.border),
            ),
            child: controller.text.trim().isEmpty
                ? Text(
                    context.l10n.formNothingToPreview,
                    style: TtType.body.copyWith(color: TtColors.textSecondary),
                  )
                : MarkdownBody(data: controller.text),
          )
        else
          TextField(
            key: const Key('product-description-field'),
            controller: controller,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.l10n.formMarkdownHint,
              filled: true,
              fillColor: TtColors.surfaceTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TtRadius.sm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
      ],
    );
  }
}

/// Product photos: a wrap of thumbnails plus Upload/Camera buttons (WTM-69 AC2).
class _ImagesSection extends StatelessWidget {
  const _ImagesSection({
    required this.paths,
    required this.onUpload,
    required this.onCamera,
    required this.onRemove,
  });

  final List<String> paths;
  final VoidCallback onUpload;
  final VoidCallback onCamera;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.productImageCount(paths.length),
          style: TtType.body.copyWith(
            fontWeight: FontWeight.w600,
            color: TtColors.textPrimary,
          ),
        ),
        const SizedBox(height: TtSpace.x2),
        if (paths.isNotEmpty)
          Wrap(
            spacing: TtSpace.x2,
            runSpacing: TtSpace.x2,
            children: [
              for (var i = 0; i < paths.length; i++)
                _Thumbnail(path: paths[i], onRemove: () => onRemove(i)),
            ],
          ),
        if (paths.isNotEmpty) const SizedBox(height: TtSpace.x2),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(context.l10n.formUpload),
            ),
            const SizedBox(width: TtSpace.x3),
            OutlinedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(context.l10n.formCamera),
            ),
          ],
        ),
      ],
    );
  }
}

/// A single image thumbnail with a remove badge. Falls back to a placeholder when
/// the file isn't on disk (e.g. in tests), so no image ever fails to load.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    final file = File(path);
    final exists = file.existsSync();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(TtRadius.sm),
            child: exists
                ? Image.file(
                    file,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _ThumbnailPlaceholder(),
                  )
                : const _ThumbnailPlaceholder(),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              tooltip: context.l10n.formRemoveImage,
              iconSize: 18,
              icon: const CircleAvatar(
                radius: 11,
                backgroundColor: TtColors.dangerOnLight,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: TtColors.surfaceTertiary,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: TtColors.textSecondary),
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
  final List<ProductFieldChange> changes;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TtType.body.copyWith(
              fontWeight: FontWeight.w700,
              color: TtColors.textPrimary,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          for (final change in changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${change.field.label(context.l10n.languageCode)}: '
                '${change.before} → ${change.after}',
                style: TtType.caption.copyWith(color: TtColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Past revisions of a product, newest first (WTM-69 AC4).
class _ChangeHistory extends StatelessWidget {
  const _ChangeHistory({required this.history});

  final List<ProductRevision> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.changeHistory,
          style: TtType.body.copyWith(
            fontWeight: FontWeight.w700,
            color: TtColors.textPrimary,
          ),
        ),
        const SizedBox(height: TtSpace.x2),
        for (final revision in history)
          Padding(
            padding: const EdgeInsets.only(bottom: TtSpace.x2),
            child: _ChangeList(
              title: TongtaiFormatters.isoDate(revision.timestamp),
              changes: revision.changes,
              accent: TtColors.unknown,
            ),
          ),
      ],
    );
  }
}

/// Sticky bottom bar with Cancel + Save (WTM-69 AC5).
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
        padding: const EdgeInsets.all(TtSpace.x4),
        decoration: const BoxDecoration(
          color: TtColors.surfaceSecondary,
          border: Border(top: BorderSide(color: TtColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TtSecondaryButton(
                label: context.l10n.actionCancel,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: TtSpace.x3),
            Expanded(
              flex: 2,
              child: TtPrimaryButton(
                key: const Key('product-save-button'),
                label: saveLabel,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
