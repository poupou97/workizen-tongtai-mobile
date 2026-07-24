/// Shared formatting utilities for Tổng Tài (WTM-60, core utilities).
///
/// Pure Dart (no new package dependency, no `intl`) so it is trivially
/// unit-testable and adds nothing to the Hub's dependency surface. These are the
/// reusable "core" helpers every feature screen needs — currency, compact
/// numbers, and human-friendly dates.
abstract final class TongtaiFormatters {
  /// Formats [amount] as Vietnamese đồng, e.g. 1234567 -> "1.234.567 ₫".
  static String vnd(num amount) {
    final rounded = amount.round();
    final negative = rounded < 0;
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${negative ? '-' : ''}$buffer ₫';
  }

  /// Compact đồng in Vietnamese money units — nghìn → "K", triệu → "tr",
  /// tỷ → "tỷ" (e.g. 579714 → "580K ₫", 4058000 → "4,06tr ₫", 1.25e9 →
  /// "1,25tỷ ₫"). Decimal comma per VN convention. For tight chips (KPI tiles);
  /// use [vnd] where the full figure fits.
  static String vndShort(num amount) {
    final rounded = amount.round();
    final sign = rounded < 0 ? '-' : '';
    final v = rounded.abs();
    if (v >= 1000000000) return '$sign${_vnDecimals(v / 1000000000)}tỷ ₫';
    if (v >= 1000000) return '$sign${_vnDecimals(v / 1000000)}tr ₫';
    if (v >= 1000) return '$sign${(v / 1000).round()}K ₫';
    return '$sign$v ₫';
  }

  /// Up to two decimals, trailing zeros trimmed, comma as the separator
  /// (4.058 → "4,06", 12 → "12", 1.5 → "1,5").
  static String _vnDecimals(double value) {
    var s = value.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s.replaceAll('.', ',');
  }

  /// Compact number, e.g. 1500 -> "1.5K", 2300000 -> "2.3M", 4_000_000_000 ->
  /// "4B". Values below 1000 are returned as-is.
  static String compact(num value) {
    final negative = value < 0;
    final v = value.abs();
    String body;
    if (v < 1000) {
      body = v == v.roundToDouble() ? v.round().toString() : v.toString();
    } else if (v < 1000000) {
      body = '${_trim(v / 1000)}K';
    } else if (v < 1000000000) {
      body = '${_trim(v / 1000000)}M';
    } else {
      body = '${_trim(v / 1000000000)}B';
    }
    return negative ? '-$body' : body;
  }

  /// Human-friendly relative date. [now] is injectable for testing.
  ///
  /// "just now" (<1m), "Nm ago" (<1h), "Nh ago" (<1d), "Nd ago" (<7d),
  /// otherwise an absolute "YYYY-MM-DD".
  static String relativeDate(DateTime when, {required DateTime now}) {
    final diff = now.difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return isoDate(when);
  }

  /// Absolute date as YYYY-MM-DD.
  static String isoDate(DateTime when) {
    final m = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    return '${when.year}-$m-$d';
  }

  /// Drops a trailing ".0" so 2.0 -> "2" but 2.3 stays "2.3".
  static String _trim(double value) {
    final oneDp = (value * 10).round() / 10;
    return oneDp == oneDp.roundToDouble()
        ? oneDp.round().toString()
        : oneDp.toString();
  }
}
