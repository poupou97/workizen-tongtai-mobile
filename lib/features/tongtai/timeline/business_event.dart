import 'package:flutter/foundation.dart';

/// The kind of business event on the timeline (WTM-114). Drives the icon,
/// color and grouping; new kinds plug in without changing the timeline.
enum BusinessEventType {
  order,
  finance,
  inventory,
  customer,
  opportunity,
  recommendation,
  journey;

  String get labelVi => switch (this) {
    BusinessEventType.order => 'Đơn hàng',
    BusinessEventType.finance => 'Tài chính',
    BusinessEventType.inventory => 'Kho',
    BusinessEventType.customer => 'Khách hàng',
    BusinessEventType.opportunity => 'Cơ hội',
    BusinessEventType.recommendation => 'Gợi ý AI',
    BusinessEventType.journey => 'Mục tiêu',
  };

  String get labelEn => switch (this) {
    BusinessEventType.order => 'Orders',
    BusinessEventType.finance => 'Finance',
    BusinessEventType.inventory => 'Inventory',
    BusinessEventType.customer => 'Customers',
    BusinessEventType.opportunity => 'Opportunities',
    BusinessEventType.recommendation => 'AI suggestions',
    BusinessEventType.journey => 'Goals',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// A single thing that happened in the business (WTM-114).
///
/// The timeline consumes [BusinessEvent]s produced by sources; it never queries
/// modules directly. `amount` is optional (đồng, signed — positive in, negative
/// out) and `refId` links back to the originating record.
@immutable
class BusinessEvent {
  const BusinessEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.timestamp,
    this.subtitle = '',
    this.amount,
    this.refId,
  });

  final String id;
  final BusinessEventType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  /// Signed đồng amount when the event carries money (finance/order); null
  /// otherwise.
  final double? amount;

  /// Identifier of the source record, for a future tap-through.
  final String? refId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BusinessEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BusinessEvent($id, ${type.name}, $title)';
}

/// A producer of business events (WTM-114). Each module contributes one; the
/// [TimelineService] merges them. This is the seam that keeps the timeline
/// decoupled — adding a source never touches the timeline or the UI.
abstract class BusinessEventSource {
  List<BusinessEvent> events();
}
