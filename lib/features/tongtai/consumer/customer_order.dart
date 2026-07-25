/// Compatibility shim (WTM-125): the order domain moved to the independent
/// Orders capability (`orders/order.dart`) so business logic no longer lives
/// inside Consumer (Founder G-2 / ADR-TON-010). Existing importers keep working
/// via this re-export; new code should import `../orders/order.dart` directly.
library;

export '../orders/order.dart';
