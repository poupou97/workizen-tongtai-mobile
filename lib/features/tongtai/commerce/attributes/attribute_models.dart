/// Domain model for the DYNAMIC attribute tier (WTM-334, ADDENDUM).
///
/// Source spec: `docs/05-DATA/COMMERCE-ATTRIBUTE-MODEL.md` §6.3. This file is
/// pure Dart — no Flutter, no Drift — so the classification and validation
/// rules are testable without a database and reusable off-device.
library;

/// The nine MVP attribute types. There is **no arbitrary-JSON type**: raw
/// vendor payload that fits none of these stays in import provenance and is
/// *reported* as unmapped rather than promoted (spec §6.3).
enum AttributeType {
  text('TEXT'),
  integer('INTEGER'),
  decimal('DECIMAL'),
  boolean('BOOLEAN'),
  date('DATE'),
  datetime('DATETIME'),
  enumType('ENUM'),
  multiEnum('MULTI_ENUM'),
  url('URL');

  const AttributeType(this.code);

  /// Canonical, storage-stable code. Persisted instead of the Dart enum index
  /// so reordering the enum never rewrites the meaning of a stored row.
  final String code;

  /// Whether this type draws its value from a fixed option list.
  bool get usesOptions =>
      this == AttributeType.enumType || this == AttributeType.multiEnum;

  static AttributeType? fromCode(String? code) {
    if (code == null) return null;
    for (final t in AttributeType.values) {
      if (t.code == code) return t;
    }
    return null;
  }

  /// Separator that joins the selected option codes of a [multiEnum] value.
  /// Option codes may not contain it (enforced by [validateOptions]).
  static const String multiEnumSeparator = ',';

  /// Whether [raw] is a well-formed canonical value for this type.
  ///
  /// [options] is required (and used) only for [enumType] / [multiEnum].
  bool isValidValue(String raw, {List<String> options = const []}) {
    switch (this) {
      case AttributeType.text:
        return true;
      case AttributeType.integer:
        return int.tryParse(raw) != null;
      case AttributeType.decimal:
        return double.tryParse(raw) != null;
      case AttributeType.boolean:
        return raw == 'true' || raw == 'false';
      case AttributeType.date:
        return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw) &&
            DateTime.tryParse(raw) != null;
      case AttributeType.datetime:
        return DateTime.tryParse(raw) != null;
      case AttributeType.enumType:
        return options.contains(raw);
      case AttributeType.multiEnum:
        if (raw.isEmpty) return false;
        final parts = raw.split(multiEnumSeparator);
        final seen = <String>{};
        for (final part in parts) {
          if (part.isEmpty || !options.contains(part) || !seen.add(part)) {
            return false;
          }
        }
        return true;
      case AttributeType.url:
        final uri = Uri.tryParse(raw);
        return uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
    }
  }
}

/// Namespace root of an attribute code.
enum AttributeScope {
  system('system'),
  user('user'),
  vendor('vendor');

  const AttributeScope(this.code);
  final String code;

  static AttributeScope? fromCode(String? code) {
    if (code == null) return null;
    for (final s in AttributeScope.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// Core fields whose *semantics* a dynamic attribute may never shadow (spec
/// §20). Creating `user.price` or mapping a vendor `SKU` field into a
/// definition is refused: the number already has a typed-column home, and a
/// second one is exactly the P-27/P-28 defect the model exists to close.
const Set<String> kCoreShadowedFields = {
  'price',
  'sku',
  'quantity',
  'cost_price',
  'status',
  'kind',
};

final RegExp _segment = RegExp(r'^[a-z][a-z0-9_]*$');

/// A parsed, valid attribute code: `system.<leaf>`, `user.<leaf>` or
/// `vendor.<name>.<leaf...>`.
class AttributeNamespace {
  const AttributeNamespace._({
    required this.scope,
    required this.leaf,
    required this.code,
    this.vendor,
  });

  final AttributeScope scope;

  /// Vendor slug when [scope] is [AttributeScope.vendor]; `null` otherwise.
  final String? vendor;

  /// The last segment — what the shadow-core check compares against.
  final String leaf;

  /// The full namespaced code.
  final String code;

  /// Parses [code]; returns `null` when it is not a well-formed namespaced
  /// code (every segment must be a lowercase identifier).
  static AttributeNamespace? tryParse(String code) {
    final segments = code.split('.');
    if (segments.length < 2) return null;
    if (segments.any((s) => !_segment.hasMatch(s))) return null;

    final root = AttributeScope.fromCode(segments.first);
    if (root == null) return null;

    switch (root) {
      case AttributeScope.system:
      case AttributeScope.user:
        return AttributeNamespace._(
          scope: root,
          leaf: segments.last,
          code: code,
        );
      case AttributeScope.vendor:
        if (segments.length < 3) return null;
        return AttributeNamespace._(
          scope: root,
          vendor: segments[1],
          leaf: segments.last,
          code: code,
        );
    }
  }

  /// Turns a raw vendor field name ("Screen Size", "công_suất") into a
  /// lowercase identifier usable as a code leaf; `null` when nothing usable
  /// remains.
  static String? slugify(String raw) {
    final slug = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isEmpty || !RegExp(r'^[a-z]').hasMatch(slug)) return null;
    return slug;
  }
}

/// Base type for every attribute-layer governance refusal. Each is a *rule*
/// with its own reason, so a caller (and a test) can tell exactly which
/// invariant was hit rather than catching a generic error.
sealed class AttributeError implements Exception {
  const AttributeError(this.message);
  final String message;
  @override
  String toString() => '$runtimeType: $message';
}

/// Two definitions share a `code` within one business (spec §20).
class DuplicateAttributeCode extends AttributeError {
  const DuplicateAttributeCode(this.code)
    : super('attribute code already exists in this scope: $code');
  final String code;
}

/// The code is not a valid `system.*` / `user.*` / `vendor.<name>.*` code.
class InvalidAttributeNamespace extends AttributeError {
  const InvalidAttributeNamespace(this.code)
    : super('not a valid namespaced attribute code: $code');
  final String code;
}

/// The code's leaf collides with a core field's semantics (spec §20).
class AttributeShadowsCoreField extends AttributeError {
  const AttributeShadowsCoreField(this.leaf)
    : super('dynamic attribute may not shadow the core field: $leaf');
  final String leaf;
}

/// A `user.*` definition would override an existing `system.*` field of the
/// same leaf (spec §20).
class UserAttributeOverridesSystem extends AttributeError {
  const UserAttributeOverridesSystem(this.leaf)
    : super('a user attribute may not override the system field: $leaf');
  final String leaf;
}

/// The value does not parse as the definition's type, or the enum options are
/// malformed (spec §20).
class InvalidAttributeValue extends AttributeError {
  const InvalidAttributeValue(super.message);
}

/// A definition of one dynamic attribute (mirrors
/// `attribute_definitions_table`).
class AttributeDefinition {
  AttributeDefinition({
    required this.id,
    required this.code,
    required this.type,
    required this.label,
    this.unit,
    this.enumOptions = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String code;
  final AttributeType type;
  final String label;
  final String? unit;
  final List<String> enumOptions;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The parsed namespace, or `null` when [code] is malformed.
  AttributeNamespace? get namespace => AttributeNamespace.tryParse(code);
}

/// One dynamic value on one entity (mirrors `attribute_values_table`).
class AttributeValue {
  AttributeValue({
    required this.id,
    required this.definitionId,
    required this.entityType,
    required this.entityId,
    required this.valueRaw,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String definitionId;
  final String entityType;
  final String entityId;
  final String valueRaw;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// A display group (mirrors `attribute_groups_table`).
class AttributeGroup {
  AttributeGroup({
    required this.id,
    required this.code,
    required this.label,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String code;
  final String label;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// A definition's membership in a group (mirrors
/// `attribute_group_items_table`).
class AttributeGroupItem {
  const AttributeGroupItem({
    required this.id,
    required this.groupId,
    required this.definitionId,
    this.sortOrder = 0,
  });

  final String id;
  final String groupId;
  final String definitionId;
  final int sortOrder;
}

/// The four buckets every incoming import field must land in — the antidote to
/// "unknown field silently swallowed" (spec §20). Nothing is dropped: a field
/// is Mapped (a definition exists), Unmapped (surfaced for the seller to
/// decide), Ignored (explicitly skipped), or Invalid (would shadow a core
/// field / has no usable name).
class AttributeImportReport {
  const AttributeImportReport({
    required this.mapped,
    required this.unmapped,
    required this.ignored,
    required this.invalid,
  });

  final List<String> mapped;
  final List<String> unmapped;
  final List<String> ignored;
  final List<String> invalid;

  int get total =>
      mapped.length + unmapped.length + ignored.length + invalid.length;
}

/// Classifies each raw vendor [fields] name into one of the four buckets.
///
/// A field is Invalid if it has no usable slug or its slug collides with a
/// core field. Otherwise it is Ignored if listed, Mapped if a
/// `vendor.<vendor>.<slug>` definition already exists in [knownCodes], else
/// Unmapped. The count of every bucket sums to `fields.length` — the guarantee
/// that no field vanishes.
AttributeImportReport classifyAttributeImport({
  required String vendor,
  required List<String> fields,
  required Set<String> knownCodes,
  Set<String> ignoreFields = const {},
}) {
  final mapped = <String>[];
  final unmapped = <String>[];
  final ignored = <String>[];
  final invalid = <String>[];

  for (final field in fields) {
    if (ignoreFields.contains(field)) {
      ignored.add(field);
      continue;
    }
    final slug = AttributeNamespace.slugify(field);
    if (slug == null || kCoreShadowedFields.contains(slug)) {
      invalid.add(field);
      continue;
    }
    final code = 'vendor.$vendor.$slug';
    if (knownCodes.contains(code)) {
      mapped.add(field);
    } else {
      unmapped.add(field);
    }
  }

  return AttributeImportReport(
    mapped: mapped,
    unmapped: unmapped,
    ignored: ignored,
    invalid: invalid,
  );
}
