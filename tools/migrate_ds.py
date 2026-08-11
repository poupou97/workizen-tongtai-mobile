"""Di trú một màn sang Design System — theo GIÁ TRỊ, không theo tên.

Bảng này là bản sao chạy được của §"Bảng ánh xạ chữ" trong
docs/02-ARCHITECTURE/TONG_TAI_DESIGN_SYSTEM_V1.md, và nó được
migrated_screens_test.dart khoá lại.
"""
import re, sys

TOKEN = {
    'TongtaiDesignTokens.displayStyle': 'TtType.display',
    'TongtaiDesignTokens.heading1Style': 'TtType.display',
    'TongtaiDesignTokens.heading2Style': 'TtType.h1',
    'TongtaiDesignTokens.heading3Style': 'TtType.h2',
    'TongtaiDesignTokens.bodyStyle': 'TtType.bodyLarge',
    'TongtaiDesignTokens.smallStyle': 'TtType.body',
    'TongtaiDesignTokens.captionStyle': 'TtType.caption',
    'TongtaiDesignTokens.cardBorderRadius': 'TtRadius.md',
    'TongtaiDesignTokens.componentBorderRadius': 'TtRadius.sm',
    'TongtaiDesignTokens.radiusSm': 'TtRadius.xs',
    'TongtaiDesignTokens.radiusMd': 'TtRadius.sm',
    'TongtaiDesignTokens.radiusLg': 'TtRadius.md',
    'TongtaiDesignTokens.radiusXl': 'TtRadius.lg',
    'TongtaiDesignTokens.radiusFull': 'TtRadius.full',
    'TongtaiDesignTokens.spacing0': '0.0',
    **{f'TongtaiDesignTokens.spacing{n}': f'TtSpace.x{n}' for n in (1,2,3,4,5,6,8,10,12)},
    'TongtaiDesignTokens.lightBackground': 'TtColors.surfaceSecondary',
    'TongtaiDesignTokens.lightSurface': 'TtColors.surface',
    'TongtaiDesignTokens.lightTextPrimary': 'TtColors.textPrimary',
    'TongtaiDesignTokens.lightTextSecondary': 'TtColors.textSecondary',
    'TongtaiDesignTokens.lightBorder': 'TtColors.border',
    'TongtaiDesignTokens.lightHover': 'TtColors.surfaceTertiary',
    'TongtaiDesignTokens.producerGreenText': 'TtColors.readableOn(TtColors.success)',
    'TongtaiDesignTokens.inventoryOrangeText': 'TtColors.warningOnDark',
    'TongtaiDesignTokens.consumerBlueText': 'TtColors.readableOn(TtColors.info)',
    'TongtaiDesignTokens.financeVioletText': 'TtColors.readableOn(TtColors.ai)',
    'TongtaiDesignTokens.errorText': 'TtColors.readableOn(TtColors.danger)',
    'TongtaiDesignTokens.neutralText': 'TtColors.textSecondary',
    'TongtaiDesignTokens.producerGreen': 'TtColors.success',
    'TongtaiDesignTokens.inventoryOrange': 'TtColors.warning',
    'TongtaiDesignTokens.consumerBlue': 'TtColors.info',
    'TongtaiDesignTokens.copilotViolet': 'TtColors.ai',
    'TongtaiDesignTokens.financePurple': 'TtColors.ai',
    'TongtaiDesignTokens.setupGray': 'TtColors.unknown',
    'TongtaiDesignTokens.success': 'TtColors.success',
    'TongtaiDesignTokens.warning': 'TtColors.warning',
    'TongtaiDesignTokens.info': 'TtColors.info',
    'TongtaiDesignTokens.error': 'TtColors.danger',
    'TongtaiDesignTokens.neutral': 'TtColors.unknown',
    'TongtaiDesignTokens.elevation0': 'TtElevation.none',
    'TongtaiDesignTokens.elevation1': 'TtElevation.soft',
    'TongtaiDesignTokens.elevation2': 'TtElevation.soft',
    'TongtaiDesignTokens.elevation3': 'TtElevation.floating',
    'TongtaiDesignTokens.readableText': 'TtColors.readableOn',
    'TongtaiDesignTokens.buttonHeight': 'TtButtonMetrics.height',
    'TongtaiDesignTokens.navBarHeight': '64.0',
}
RAW = {
    'Color(0xFFE5E7EB)': 'TtColors.border',
    'Color(0xFF6B7280)': 'TtColors.textSecondary',
    'Color(0xFF10B981)': 'TtColors.success',
    'Color(0xFF3B82F6)': 'TtColors.info',
    'Color(0xFFF59E0B)': 'TtColors.warning',
    'Color(0xFFEF4444)': 'TtColors.danger',
    'Color(0xFF8B5CF6)': 'TtColors.ai',
    'Color(0xFFF0FDF4)': 'TtColors.successSoft',
    'Color(0xFFF9FAFB)': 'TtColors.surfaceSecondary',
    'Color(0xFF111827)': 'TtColors.textPrimary',
    'Color(0xFF374151)': 'TtColors.textSecondary',
    'Color(0xFF9CA3AF)': 'TtColors.textTertiary',
    'Color(0xFFD1D5DB)': 'TtColors.borderStrong',
}
# dài trước ngắn — `inventoryOrangeText` từng bị cắt thành `warningText`
ORDER = sorted(TOKEN, key=len, reverse=True)

for path in sys.argv[1:]:
    s = open(path, encoding='utf-8').read()
    if 'core/design/tt.dart' not in s:
        m = list(re.finditer(r"^import 'package:[^']+';\n", s, re.M))
        s = s[:m[-1].end()] + "\nimport '../../../../core/design/tt.dart';\n" + s[m[-1].end():]
    for a in ORDER:
        s = s.replace(a, TOKEN[a])
    for a, b in RAW.items():
        s = s.replace('const ' + a, b).replace(a, b)
    left = len(re.findall(r'TongtaiDesignTokens\.[a-zA-Z]', s))
    if left == 0:
        s = re.sub(r"^import '[^']*tongtai_design_tokens\.dart';\n", '', s, flags=re.M)
    open(path, 'w', encoding='utf-8').write(s)
    print(f'{path.split("/")[-1]}: token cũ còn {left} · màu viết thẳng còn {s.count("Color(0x")}')
