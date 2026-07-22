import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';

import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../inventory/product_form.dart';
import '../../inventory/product_history.dart';
import '../../inventory/product_image_source.dart';
import '../../navigation/tongtai_design_tokens.dart';

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
    _name = TextEditingController(text: data.name);
    _sku = TextEditingController(text: data.sku);
    _category = TextEditingController(text: data.category);
    _price = TextEditingController(text: data.priceText);
    _quantity = TextEditingController(text: data.quantityText);
    _reorder = TextEditingController(text: data.reorderLevelText);
    _description = TextEditingController(text: data.description);
    _imagePaths.addAll(data.imagePaths);

    _controllers = [
      _name,
      _sku,
      _category,
      _price,
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
    priceText: _price.text,
    quantityText: _quantity.text,
    reorderLevelText: _reorder.text,
    imagePaths: _imagePaths,
  );

  /// Domain validation plus the SKU-uniqueness check layered on top.
  Map<ProductField, String> _validate(ProductFormData data) {
    final errors = Map<ProductField, String>.from(data.validate());
    if (!errors.containsKey(ProductField.sku)) {
      final taken = widget.isSkuTaken?.call(data.sku.trim()) ?? false;
      if (taken) errors[ProductField.sku] = 'SKU already exists';
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
          const SnackBar(content: Text('Please fix the highlighted fields.')),
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
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'Add Product'),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          children: [
            _field(
              key: const Key('product-name-field'),
              controller: _name,
              field: ProductField.name,
              hint: 'e.g. Handheld mini fan',
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
              hint: 'e.g. Electronics',
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
                const SizedBox(width: TongtaiDesignTokens.spacing3),
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
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            _DescriptionField(
              controller: _description,
              preview: _previewDescription,
              onTogglePreview: (preview) =>
                  setState(() => _previewDescription = preview),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            _ImagesSection(
              paths: _imagePaths,
              onUpload: () => _addImage(fromCamera: false),
              onCamera: () => _addImage(fromCamera: true),
              onRemove: _removeImage,
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: TongtaiDesignTokens.spacing4),
              _ChangeList(
                title: 'Unsaved changes (${pending.length})',
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
        saveLabel: widget.isEditing ? 'Save Changes' : 'Save Product',
        onSave: _save,
        onCancel: _cancel,
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required ProductField field,
    String? hint,
    String? suffixText,
    bool optional = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final label = optional
        ? '${field.labelEn} (optional)'
        : field.isRequired
        ? '${field.labelEn} *'
        : field.labelEn;
    return Padding(
      padding: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing3),
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
      padding: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing3),
      child: Wrap(
        spacing: TongtaiDesignTokens.spacing2,
        runSpacing: TongtaiDesignTokens.spacing1,
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
                'Description',
                overflow: TextOverflow.ellipsis,
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
            ),
            ChoiceChip(
              label: const Text('Write'),
              selected: !preview,
              onSelected: (_) => onTogglePreview(false),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing2),
            ChoiceChip(
              label: const Text('Preview'),
              selected: preview,
              onSelected: (_) => onTogglePreview(true),
            ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        if (preview)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
            decoration: BoxDecoration(
              color: TongtaiDesignTokens.lightHover,
              borderRadius: BorderRadius.circular(
                TongtaiDesignTokens.componentBorderRadius,
              ),
              border: Border.all(color: TongtaiDesignTokens.lightBorder),
            ),
            child: controller.text.trim().isEmpty
                ? Text(
                    'Nothing to preview yet.',
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
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
              hintText: 'Supports **markdown** — headings, **bold**, lists…',
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
          'Images (${paths.length})',
          style: TongtaiDesignTokens.smallStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        if (paths.isNotEmpty)
          Wrap(
            spacing: TongtaiDesignTokens.spacing2,
            runSpacing: TongtaiDesignTokens.spacing2,
            children: [
              for (var i = 0; i < paths.length; i++)
                _Thumbnail(path: paths[i], onRemove: () => onRemove(i)),
            ],
          ),
        if (paths.isNotEmpty)
          const SizedBox(height: TongtaiDesignTokens.spacing2),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Upload'),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            OutlinedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Camera'),
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
            borderRadius: BorderRadius.circular(
              TongtaiDesignTokens.componentBorderRadius,
            ),
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
              tooltip: 'Remove image',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const CircleAvatar(
                radius: 11,
                backgroundColor: TongtaiDesignTokens.error,
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
      color: TongtaiDesignTokens.lightHover,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: TongtaiDesignTokens.lightTextSecondary,
      ),
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
                '${change.field.labelEn}: ${change.before} → ${change.after}',
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
          'Change history',
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
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: TongtaiDesignTokens.inventoryOrange,
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
