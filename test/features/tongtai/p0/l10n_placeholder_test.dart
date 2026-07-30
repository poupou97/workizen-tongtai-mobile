import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';

/// P0 §3 (WTM-146) — placeholder consistency: every parameterized AppStrings
/// method must interpolate ALL of its arguments in BOTH locales. A locale
/// that drops an argument (count, file name, model, title…) ships a broken
/// message that no compile step can catch.
void main() {
  const locales = <AppStrings>[AppStringsVi(), AppStringsEn()];

  test('every parameterized string contains all its arguments (vi + en)', () {
    for (final s in locales) {
      final code = s.languageCode;
      void mustContain(String result, List<String> args, String method) {
        for (final a in args) {
          expect(
            result.contains(a),
            isTrue,
            reason: '[$code] $method dropped "$a": "$result"',
          );
        }
      }

      mustContain(s.exportShareSubject('Customers', '20260730'), [
        'Customers',
        '20260730',
      ], 'exportShareSubject');
      mustContain(s.exportDoneSnack(12, 'customers-20260730.csv'), [
        '12',
        'customers-20260730.csv',
      ], 'exportDoneSnack');
      mustContain(s.exportHistoryLine('f.csv', 'Orders', 7, '2026-07-30'), [
        'f.csv',
        'Orders',
        '7',
        '2026-07-30',
      ], 'exportHistoryLine');
      mustContain(s.searchResultCount(2), ['2'], 'searchResultCount');
      mustContain(s.oppDismissedSnack('Cơ hội A'), [
        'Cơ hội A',
      ], 'oppDismissedSnack');
      mustContain(s.oppInterestedSnack('Cơ hội B'), [
        'Cơ hội B',
      ], 'oppInterestedSnack');
      mustContain(s.oppGoalCreatedSnack('Mục tiêu X'), [
        'Mục tiêu X',
      ], 'oppGoalCreatedSnack');
      mustContain(s.oppCreatedFromNote('mô tả'), [
        'mô tả',
      ], 'oppCreatedFromNote');
      mustContain(s.daysCount(9), ['9'], 'daysCount');
      mustContain(s.daysLeft(3), ['3'], 'daysLeft');
      mustContain(s.percentOfGoal(42), ['42'], 'percentOfGoal');
      mustContain(s.goalTemplateDays('Doanh thu', 30), [
        'Doanh thu',
        '30',
      ], 'goalTemplateDays');
      mustContain(s.reportsOrdersCount(4), ['4'], 'reportsOrdersCount');
      mustContain(s.aiKeyRotatedSnack('grok-3'), [
        'grok-3',
      ], 'aiKeyRotatedSnack');
      mustContain(s.aiKeyRotateFailedPrefix('401'), [
        '401',
      ], 'aiKeyRotateFailedPrefix');
      mustContain(s.aiKeyTestOkSnack('grok-3'), ['grok-3'], 'aiKeyTestOkSnack');
      mustContain(s.aiKeyConsoleHint('https://console.x.ai', 'xAI'), [
        'https://console.x.ai',
        'xAI',
      ], 'aiKeyConsoleHint');
      mustContain(s.aiKeyCardTitle('xAI'), ['xAI'], 'aiKeyCardTitle');
    }
  });

  test('singular/plural boundary stays coherent in both locales', () {
    for (final s in locales) {
      expect(s.searchResultCount(1), contains('1'));
      expect(s.searchResultCount(5), contains('5'));
    }
    // English pluralizes; Vietnamese does not — both must stay well-formed.
    expect(const AppStringsEn().searchResultCount(1), '1 result');
    expect(const AppStringsEn().searchResultCount(2), '2 results');
    expect(const AppStringsVi().searchResultCount(2), '2 kết quả');
  });
}
