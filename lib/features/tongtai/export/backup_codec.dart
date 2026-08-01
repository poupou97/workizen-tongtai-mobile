library;

import '../finance/finance_category.dart';
import '../opportunity/opportunity.dart';
import '../consumer/customer.dart';
import '../consumer/customer_history.dart';
import '../core/tongtai_enums.dart';
import '../finance/finance_transaction.dart';
import '../inventory/product.dart';
import '../inventory/product_history.dart';
import '../journey/business_goal.dart';
import '../journey/journey.dart';
import '../journey/journey_node.dart';
import '../profile/business_profile.dart';
import '../orders/order.dart';
import '../producer/supplier_favorite.dart';

/// Domain ⇄ JSON for the `.ttbk` v2 payload (WTM-164, ADR-TON-018).
///
/// **Canonical values only.** Enums travel as `.name` — `confirmed`, `income`,
/// `revenue` — never as `labelVi`/`labelEn`. The v1 CSV export made exactly
/// that mistake: it wrote `status` as a Vietnamese display label, which makes
/// the file unreadable by an English build and meaningless if a label is ever
/// reworded. A backup must survive translation changes.
///
/// **Every field, including derived history.** Round-trip equality is asserted
/// in tests for all six datasets. Fields the domain *derives* (a customer's
/// tier, a product's stock status) are deliberately NOT stored: they are
/// recomputed, and storing them would create two sources of truth inside the
/// backup itself.
///
/// **Decoding is total and defensive.** Every decoder returns `null` for a row
/// it cannot read rather than throwing, so validation can report *which row of
/// which dataset* is bad and refuse the file — instead of a constructor
/// assertion firing halfway through a restore.
class BackupCodec {
  const BackupCodec._();

  // ── primitives ───────────────────────────────────────────────────────────

  static String _iso(DateTime value) => value.toUtc().toIso8601String();

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  static String? _str(Object? value) => value is String ? value : null;

  static int? _int(Object? value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : null;

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : null;

  static List<String>? _strings(Object? value) {
    if (value is! List) return null;
    final out = <String>[];
    for (final item in value) {
      if (item is! String) return null;
      out.add(item);
    }
    return out;
  }

  /// Looks an enum value up by its canonical `name`; null when unknown, which
  /// validation reports as an invalid code rather than silently defaulting.
  static T? _enum<T extends Enum>(List<T> values, Object? value) {
    if (value is! String) return null;
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }

  // ── customers ────────────────────────────────────────────────────────────

  static Map<String, Object?> encodeCustomer(Customer c) => {
    'id': c.id,
    'name': c.name,
    'phone': c.phone,
    'email': c.email,
    'location': c.location,
    'addresses': c.addresses,
    'segments': c.segments,
    'tags': c.tags,
    'notes': c.notes,
    'orderCount': c.orderCount,
    'totalSpent': c.totalSpent,
    'lastPurchaseDate': c.lastPurchaseDate == null
        ? null
        : _iso(c.lastPurchaseDate!),
    'history': [
      for (final revision in c.history)
        {
          'timestamp': _iso(revision.timestamp),
          'changes': [
            for (final change in revision.changes)
              {
                'field': change.field.name,
                'before': change.before,
                'after': change.after,
              },
          ],
        },
    ],
  };

  static Customer? decodeCustomer(Map<String, Object?> json) {
    final id = _str(json['id']);
    final name = _str(json['name']);
    final phone = _str(json['phone']);
    final location = _str(json['location']);
    final orderCount = _int(json['orderCount']);
    final totalSpent = _double(json['totalSpent']);
    final addresses = _strings(json['addresses']);
    final segments = _strings(json['segments']);
    final tags = _strings(json['tags']);
    final email = _str(json['email']);
    final notes = _str(json['notes']);
    if (id == null ||
        id.isEmpty ||
        name == null ||
        phone == null ||
        location == null ||
        orderCount == null ||
        totalSpent == null ||
        addresses == null ||
        segments == null ||
        tags == null ||
        email == null ||
        notes == null) {
      return null;
    }
    final lastPurchaseRaw = json['lastPurchaseDate'];
    if (lastPurchaseRaw != null && _date(lastPurchaseRaw) == null) return null;
    final history = _decodeCustomerHistory(json['history']);
    if (history == null) return null;
    return Customer(
      id: id,
      name: name,
      phone: phone,
      location: location,
      orderCount: orderCount,
      totalSpent: totalSpent,
      lastPurchaseDate: lastPurchaseRaw == null ? null : _date(lastPurchaseRaw),
      email: email,
      addresses: addresses,
      segments: segments,
      tags: tags,
      notes: notes,
      history: history,
    );
  }

  static List<CustomerRevision>? _decodeCustomerHistory(Object? value) {
    if (value == null) return const [];
    if (value is! List) return null;
    final out = <CustomerRevision>[];
    for (final entry in value) {
      if (entry is! Map) return null;
      final timestamp = _date(entry['timestamp']);
      final rawChanges = entry['changes'];
      if (timestamp == null || rawChanges is! List) return null;
      final changes = <CustomerFieldChange>[];
      for (final raw in rawChanges) {
        if (raw is! Map) return null;
        final field = _enum(CustomerField.values, raw['field']);
        final before = _str(raw['before']);
        final after = _str(raw['after']);
        if (field == null || before == null || after == null) return null;
        changes.add(
          CustomerFieldChange(field: field, before: before, after: after),
        );
      }
      out.add(CustomerRevision(timestamp: timestamp, changes: changes));
    }
    return out;
  }

  // ── products ─────────────────────────────────────────────────────────────

  static Map<String, Object?> encodeProduct(Product p) => {
    'id': p.id,
    'sku': p.sku,
    'name': p.name,
    'category': p.category,
    'description': p.description,
    'quantity': p.quantity,
    'pricePerUnit': p.pricePerUnit,
    // WTM-204: nullable on purpose — absent means "not entered", never 0.
    'costPrice': p.costPrice,
    'reorderLevel': p.reorderLevel,
    'updatedAt': _iso(p.updatedAt),
    'imagePaths': p.imagePaths,
    'history': [
      for (final revision in p.history)
        {
          'timestamp': _iso(revision.timestamp),
          'changes': [
            for (final change in revision.changes)
              {
                'field': change.field.name,
                'before': change.before,
                'after': change.after,
              },
          ],
        },
    ],
  };

  static Product? decodeProduct(Map<String, Object?> json) {
    final id = _str(json['id']);
    final sku = _str(json['sku']);
    final name = _str(json['name']);
    final category = _str(json['category']);
    final description = _str(json['description']);
    final quantity = _int(json['quantity']);
    final pricePerUnit = _double(json['pricePerUnit']);
    final reorderLevel = _int(json['reorderLevel']);
    final updatedAt = _date(json['updatedAt']);
    final imagePaths = _strings(json['imagePaths']);
    if (id == null ||
        id.isEmpty ||
        sku == null ||
        name == null ||
        category == null ||
        description == null ||
        quantity == null ||
        pricePerUnit == null ||
        reorderLevel == null ||
        updatedAt == null ||
        imagePaths == null) {
      return null;
    }
    final history = _decodeProductHistory(json['history']);
    if (history == null) return null;
    return Product(
      id: id,
      sku: sku,
      name: name,
      category: category,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      // WTM-204: every `.ttbk` written before cost prices existed lacks this
      // key, and those files must restore — the product simply comes back with
      // no cost entered, which is the truth.
      costPrice: _double(json['costPrice']),
      reorderLevel: reorderLevel,
      updatedAt: updatedAt,
      description: description,
      imagePaths: imagePaths,
      history: history,
    );
  }

  static List<ProductRevision>? _decodeProductHistory(Object? value) {
    if (value == null) return const [];
    if (value is! List) return null;
    final out = <ProductRevision>[];
    for (final entry in value) {
      if (entry is! Map) return null;
      final timestamp = _date(entry['timestamp']);
      final rawChanges = entry['changes'];
      if (timestamp == null || rawChanges is! List) return null;
      final changes = <ProductFieldChange>[];
      for (final raw in rawChanges) {
        if (raw is! Map) return null;
        final field = _enum(ProductField.values, raw['field']);
        final before = _str(raw['before']);
        final after = _str(raw['after']);
        if (field == null || before == null || after == null) return null;
        changes.add(
          ProductFieldChange(field: field, before: before, after: after),
        );
      }
      out.add(ProductRevision(timestamp: timestamp, changes: changes));
    }
    return out;
  }

  // ── orders ───────────────────────────────────────────────────────────────

  /// Note `id` and every item's `productId` — the two fields the v1 CSV
  /// dropped, and the reason a v1 file can never rebuild the Inventory↔Orders
  /// link that ADR-TON-010 requires.
  static Map<String, Object?> encodeOrder(CustomerOrder o) => {
    'id': o.id,
    'customerId': o.customerId,
    'orderNumber': o.orderNumber,
    'date': _iso(o.date),
    'status': o.status.name,
    // WTM-209/211 — nullable, absent on files from older builds. Found while
    // wiring `channel`: WTM-211 shipped `paymentStatus` into the domain but
    // NOT into this codec, so a backup → restore would have silently erased
    // the seller's receivables. The wiring test now walks every domain field.
    'paymentStatus': o.paymentStatus,
    'channel': o.channel?.code,
    'items': [
      for (final item in o.items)
        {
          'productId': item.productId,
          'productName': item.productName,
          'sku': item.sku,
          'category': item.category,
          'unit': item.unit,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
        },
    ],
  };

  static CustomerOrder? decodeOrder(Map<String, Object?> json) {
    final id = _str(json['id']);
    final customerId = _str(json['customerId']);
    final orderNumber = _str(json['orderNumber']);
    final date = _date(json['date']);
    final status = _enum(OrderStatus.values, json['status']);
    final rawItems = json['items'];
    if (id == null ||
        id.isEmpty ||
        customerId == null ||
        customerId.isEmpty ||
        orderNumber == null ||
        date == null ||
        status == null ||
        rawItems is! List) {
      return null;
    }
    final items = <OrderItem>[];
    for (final raw in rawItems) {
      if (raw is! Map) return null;
      final productId = _str(raw['productId']);
      final productName = _str(raw['productName']);
      final sku = _str(raw['sku']);
      final category = _str(raw['category']);
      final unit = _str(raw['unit']);
      final quantity = _int(raw['quantity']);
      final unitPrice = _double(raw['unitPrice']);
      if (productId == null ||
          productName == null ||
          sku == null ||
          category == null ||
          unit == null ||
          quantity == null ||
          unitPrice == null) {
        return null;
      }
      items.add(
        OrderItem(
          productId: productId,
          productName: productName,
          sku: sku,
          category: category,
          unit: unit,
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      );
    }
    return CustomerOrder(
      id: id,
      customerId: customerId,
      orderNumber: orderNumber,
      date: date,
      status: status,
      paymentStatus: _str(json['paymentStatus']),
      channel: SalesChannel.fromCode(_str(json['channel'])),
      items: items,
    );
  }

  // ── goals ────────────────────────────────────────────────────────────────

  static Map<String, Object?> encodeGoal(BusinessGoal g) => {
    'id': g.id,
    'name': g.name,
    'type': g.type.name,
    'targetAmount': g.targetAmount,
    'achievedAmount': g.achievedAmount,
    'growthTarget': g.growthTarget,
    'growthAchieved': g.growthAchieved,
    'startDate': _iso(g.startDate),
    'endDate': _iso(g.endDate),
    'notes': g.notes,
    'createdAt': _iso(g.createdAt),
    'updatedAt': _iso(g.updatedAt),
  };

  static BusinessGoal? decodeGoal(Map<String, Object?> json) {
    final id = _str(json['id']);
    final name = _str(json['name']);
    final type = _enum(GoalType.values, json['type']);
    final targetAmount = _double(json['targetAmount']);
    final achievedAmount = _double(json['achievedAmount']);
    final growthTarget = _int(json['growthTarget']);
    final growthAchieved = _int(json['growthAchieved']);
    final startDate = _date(json['startDate']);
    final endDate = _date(json['endDate']);
    final notes = _str(json['notes']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    if (id == null ||
        id.isEmpty ||
        name == null ||
        type == null ||
        targetAmount == null ||
        achievedAmount == null ||
        growthTarget == null ||
        growthAchieved == null ||
        startDate == null ||
        endDate == null ||
        notes == null ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return BusinessGoal(
      id: id,
      name: name,
      type: type,
      targetAmount: targetAmount,
      achievedAmount: achievedAmount,
      growthTarget: growthTarget,
      growthAchieved: growthAchieved,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ── finance transactions ─────────────────────────────────────────────────

  static Map<String, Object?> encodeTransaction(FinanceTransaction t) => {
    'id': t.id,
    'type': t.type.name,
    'category': t.category.code,
    'amount': t.amount,
    'date': _iso(t.date),
    'description': t.description,
    'paymentMethod': t.paymentMethod,
  };

  static FinanceTransaction? decodeTransaction(Map<String, Object?> json) {
    final id = _str(json['id']);
    final type = _enum(TransactionType.values, json['type']);
    final category = _str(json['category']);
    final amount = _double(json['amount']);
    final date = _date(json['date']);
    final description = _str(json['description']);
    final paymentMethod = _str(json['paymentMethod']);
    if (id == null ||
        id.isEmpty ||
        type == null ||
        category == null ||
        amount == null ||
        date == null ||
        description == null ||
        paymentMethod == null) {
      return null;
    }
    return FinanceTransaction(
      id: id,
      type: type,
      // WTM-197: a `.ttbk` written before the codes existed carries Vietnamese
      // labels. Mapped, never dropped — losing a category silently moves money
      // between groups in the seller's own expense breakdown.
      category: FinanceCategory.fromStorage(category),
      categoryNote: FinanceCategory.noteFor(category),
      amount: amount,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
    );
  }

  // ── supplier favourites ──────────────────────────────────────────────────

  /// A journey and its whole tree, as one record (WTM-185).
  ///
  /// Nested rather than three flat datasets: a tree split across datasets can
  /// be restored half-way, and a plan missing its steps is worse than no plan.
  /// One record per journey means it arrives whole or not at all.
  static Map<String, Object?> encodeJourney(Journey j) => {
    'id': j.id,
    'goalId': j.goalId,
    'state': j.state.code,
    'activePlanVersion': j.activePlanVersion,
    'createdAt': j.createdAt.toIso8601String(),
    'updatedAt': j.updatedAt.toIso8601String(),
    'nodes': [for (final n in j.nodes) n.toJson()],
    'plans': [
      for (final p in j.plans)
        {
          'version': p.version,
          'generatedBy': p.generatedBy.code,
          'generatedAt': p.generatedAt.toIso8601String(),
          'reasonCodes': p.reasonCodes,
        },
    ],
  };

  /// Returns `null` for a record this build cannot understand — the whole
  /// journey is dropped rather than restored with an unreadable state, the
  /// same rule ADR-TON-018 sets for any unknown enum.
  static Journey? decodeJourney(Map<String, Object?> json) {
    final id = json['id'];
    final goalId = json['goalId'];
    final state = JourneyState.fromCode(json['state'] as String?);
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    if (id is! String ||
        goalId is! String ||
        state == null ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return Journey(
      id: id,
      goalId: goalId,
      state: state,
      activePlanVersion: (json['activePlanVersion'] as num?)?.toInt(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      nodes: [
        for (final raw in (json['nodes'] as List? ?? const []))
          if (raw is Map) ?JourneyNode.fromJson(Map<String, dynamic>.from(raw)),
      ],
      plans: [
        for (final raw in (json['plans'] as List? ?? const []))
          if (raw is Map)
            if (JourneyNodeOrigin.fromCode(raw['generatedBy'] as String?)
                case final by?)
              if (DateTime.tryParse(raw['generatedAt'] as String? ?? '')
                  case final at?)
                JourneyPlan(
                  version: (raw['version'] as num?)?.toInt() ?? 1,
                  generatedBy: by,
                  generatedAt: at,
                  reasonCodes: [
                    for (final c in (raw['reasonCodes'] as List? ?? const []))
                      if (c is String) c,
                  ],
                ),
      ],
    );
  }

  static Map<String, Object?> encodeFavourite(SupplierFavorite f) => {
    'supplierId': f.supplierId,
    'addedAt': _iso(f.addedAt),
  };

  static SupplierFavorite? decodeFavourite(Map<String, Object?> json) {
    final supplierId = _str(json['supplierId']);
    final addedAt = _date(json['addedAt']);
    if (supplierId == null || supplierId.isEmpty || addedAt == null) {
      return null;
    }
    return SupplierFavorite(supplierId: supplierId, addedAt: addedAt);
  }

  // ── opportunity reactions (WTM-190) ───────────────────────────────────────

  /// Encodes one decision. The reaction is written as its **canonical code**
  /// (`OpportunityReaction.name`), never a display label — ADR-TON-018.
  static Map<String, Object?> encodeOpportunityReaction(
    String opportunityId,
    OpportunityReaction reaction,
  ) => {'opportunityId': opportunityId, 'reaction': reaction.name};

  /// Decodes one decision, or `null` if the row is malformed or carries a
  /// reaction this build does not know.
  ///
  /// Dropping beats defaulting here: a wrong default would either resurrect an
  /// opportunity the seller dismissed or hide one they saved, and the seller
  /// has no way to tell it happened.
  static MapEntry<String, OpportunityReaction>? decodeOpportunityReaction(
    Map<String, Object?> json,
  ) {
    final id = json['opportunityId'];
    final code = json['reaction'];
    if (id is! String || id.isEmpty || code is! String) return null;
    for (final value in OpportunityReaction.values) {
      if (value.name == code) return MapEntry(id, value);
    }
    return null;
  }
}
