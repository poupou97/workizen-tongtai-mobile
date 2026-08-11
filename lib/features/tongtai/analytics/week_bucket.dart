import 'package:flutter/foundation.dart';

/// Calendar-week bucketing — the **one** week grid every weekly series in Tổng
/// Tài is built on (WTM-376, Epic WTM-179; One Data Path, ADR-TON-015).
///
/// Sibling of `month_bucket.dart`, and deliberately written the same way: a
/// second `date.difference(...).inDays ~/ 7` loop somewhere else is how two
/// screens end up disagreeing about which week an order fell in.
///
/// ## Vì sao có lưới tuần, chứ không dùng lại lưới tháng
///
/// Không phải để có thêm một sự thật doanh thu thứ hai — **luật tính tiền vẫn
/// là `isBillableOrder`**, dùng chung với `RevenueSeries`. Thứ khác nhau là
/// **câu hỏi**: *"tháng vừa rồi thế nào"* và *"tuần vừa rồi thế nào"* cần hai
/// lưới thời gian, không cần hai định nghĩa doanh thu.
///
/// Ranh giới ấy là điều phải giữ: **grid có hai, rule chỉ có một.**
///
/// ## Tuần bắt đầu THỨ HAI
///
/// Người bán Việt Nam nói *"tuần này"* là từ thứ Hai. Bắt đầu Chủ nhật (kiểu
/// Mỹ) sẽ **cắt đôi cuối tuần** — mà thứ Bảy + Chủ nhật thường là hai ngày bán
/// mạnh nhất, nên tách chúng ra hai tuần khác nhau làm mọi so sánh vô nghĩa.
///
/// ## Múi giờ — **giờ địa phương**, cùng lý do với `month_bucket.dart`
///
/// Một đơn ghi *"1/7"* do người bán nhìn lịch trên tường mà gõ. Chia theo UTC
/// sẽ đẩy đơn 1/7 00:30 (UTC+7) về tuần trước và làm app cãi nhau với sổ của
/// chính người bán. `DateTime` đến ở dạng UTC được `toLocal()` trước.
///
/// Mọi hàm ở đây là **thuần**: cùng đầu vào (và cùng múi giờ) → cùng đầu ra.
@immutable
class WeekKey implements Comparable<WeekKey> {
  /// A week identified by the local calendar date of its **Monday**.
  ///
  /// Cố ý khoá theo ngày thứ Hai chứ không theo *"tuần thứ mấy của năm"*: số
  /// tuần ISO có năm 52 tuần và năm 53 tuần, nên `(year, week)` không so sánh
  /// được qua ranh giới năm mà không viết thêm luật. Một ngày thì so sánh được
  /// ngay, và nó cũng là thứ hiện lên màn hình.
  WeekKey(int year, int month, int day) : monday = DateTime(year, month, day);

  /// The local calendar week that contains [moment].
  factory WeekKey.of(DateTime moment) {
    final local = moment.isUtc ? moment.toLocal() : moment;
    // `DateTime.weekday`: thứ Hai = 1 … Chủ nhật = 7.
    final back = local.weekday - DateTime.monday;
    final monday = DateTime(local.year, local.month, local.day - back);
    return WeekKey(monday.year, monday.month, monday.day);
  }

  /// Local midnight on the Monday that opens this week (inclusive start).
  final DateTime monday;

  /// Local midnight on the **next** Monday (exclusive end).
  DateTime get endExclusive =>
      DateTime(monday.year, monday.month, monday.day + 7);

  /// Local midnight on the Sunday that closes this week — the date a seller
  /// reads as *"đến hết Chủ nhật"*.
  DateTime get sunday => DateTime(monday.year, monday.month, monday.day + 6);

  /// Days since the epoch, on the **UTC-normalised** midnight so a DST jump
  /// cannot turn a day into 23 hours. A total order over weeks.
  int get ordinal =>
      DateTime.utc(
        monday.year,
        monday.month,
        monday.day,
      ).difference(DateTime.utc(1970)).inDays ~/
      7;

  /// This week shifted by [delta] weeks (negative shifts back).
  WeekKey addWeeks(int delta) {
    final shifted = DateTime(monday.year, monday.month, monday.day + delta * 7);
    return WeekKey(shifted.year, shifted.month, shifted.day);
  }

  /// How many weeks [other] lies before this one (negative when it is after).
  int weeksSince(WeekKey other) => ordinal - other.ordinal;

  /// Whether [moment] falls inside this local calendar week.
  bool contains(DateTime moment) => WeekKey.of(moment) == this;

  @override
  int compareTo(WeekKey other) => ordinal.compareTo(other.ordinal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is WeekKey && other.ordinal == ordinal);

  @override
  int get hashCode => ordinal;

  @override
  String toString() =>
      '${monday.year}-${monday.month.toString().padLeft(2, '0')}'
      '-${monday.day.toString().padLeft(2, '0')}';
}

/// The analysable week grid ending at [now], oldest → newest.
///
/// [weeks] is the number of buckets to emit; a non-positive value yields an
/// empty window (well-formed, never an exception).
///
/// When [excludeCurrentWeek] is true (the default for *analysis*) the running
/// week is dropped, for the same reason `monthWindow` drops the running month:
/// a partial week always reads as a collapse against complete ones. A Weekly
/// Review shown on Monday morning is **about last week**, not about the four
/// hours that have happened so far today.
List<WeekKey> weekWindow({
  required DateTime now,
  required int weeks,
  bool excludeCurrentWeek = true,
}) {
  if (weeks <= 0) return const <WeekKey>[];
  final current = WeekKey.of(now);
  final last = excludeCurrentWeek ? current.addWeeks(-1) : current;
  return List<WeekKey>.unmodifiable([
    for (var back = weeks - 1; back >= 0; back--) last.addWeeks(-back),
  ]);
}

/// Groups [items] into local calendar weeks, keyed by [WeekKey].
///
/// Weeks with no items are simply absent from the map — callers pair this with
/// [weekWindow] so **every** week in the window still emits a point (a gap must
/// be a visible zero, never a missing row).
Map<WeekKey, List<T>> bucketByWeek<T>(
  Iterable<T> items,
  DateTime Function(T item) dateOf,
) {
  final buckets = <WeekKey, List<T>>{};
  for (final item in items) {
    buckets.putIfAbsent(WeekKey.of(dateOf(item)), () => <T>[]).add(item);
  }
  return buckets;
}
