// Onboarding tutorial content for Tổng Tài (WTM-59).
//
// Each [TongtaiOnboardingPage] is a pure value object describing one tutorial
// screen: an illustration (icon + accent color) plus a headline and a body in
// both English and Vietnamese. Copy lives here — not in the widget — so it can
// be unit-tested and reused, and so a translator can edit strings without
// touching UI code. Bilingual resolution follows the same `…For(languageCode)`
// convention as the deep-link failure messages (WTM-57).

import 'package:flutter/material.dart';

import '../navigation/tongtai_design_tokens.dart';

/// One screen in the first-launch onboarding tutorial.
@immutable
class TongtaiOnboardingPage {
  const TongtaiOnboardingPage({
    required this.id,
    required this.icon,
    required this.accentColor,
    required this.headlineEn,
    required this.headlineVi,
    required this.bodyEn,
    required this.bodyVi,
  });

  /// Stable identifier for the page (used for keys, tests, and analytics).
  final String id;

  /// The illustration icon shown in the tinted circle.
  final IconData icon;

  /// Accent color for the illustration, indicator dot, and primary button —
  /// drawn from the module color system so each screen echoes the feature it
  /// introduces.
  final Color accentColor;

  final String headlineEn;
  final String headlineVi;
  final String bodyEn;
  final String bodyVi;

  /// Headline for the given language code (`'vi'` → Vietnamese, else English).
  String headlineFor(String languageCode) =>
      languageCode == 'vi' ? headlineVi : headlineEn;

  /// Body copy for the given language code (`'vi'` → Vietnamese, else English).
  String bodyFor(String languageCode) => languageCode == 'vi' ? bodyVi : bodyEn;
}

/// The canonical onboarding sequence: a welcome screen followed by one screen
/// per core feature (suppliers, inventory, customers, AI chat, journeys). Six
/// screens total, satisfying the "5-6 screens" acceptance criterion.
const List<TongtaiOnboardingPage> kTongtaiOnboardingPages = [
  TongtaiOnboardingPage(
    id: 'welcome',
    icon: Icons.waving_hand,
    accentColor: TongtaiDesignTokens.copilotViolet,
    headlineEn: 'Welcome to Tổng Tài',
    headlineVi: 'Chào mừng đến Tổng Tài',
    bodyEn: 'Your AI-powered business partner for sourcing, inventory, '
        'customers, and growth — all in one app.',
    bodyVi: 'Trợ lý kinh doanh AI của bạn cho việc tìm nguồn hàng, quản lý kho, '
        'khách hàng và tăng trưởng — tất cả trong một ứng dụng.',
  ),
  TongtaiOnboardingPage(
    id: 'suppliers',
    icon: Icons.document_scanner,
    accentColor: TongtaiDesignTokens.producerGreen,
    headlineEn: 'Scan & Source Suppliers',
    headlineVi: 'Quét & Tìm Nhà Cung Cấp',
    bodyEn: 'Scan supplier cards and invoices — Tổng Tài captures the details '
        'so you can find and compare suppliers in seconds.',
    bodyVi: 'Quét danh thiếp và hóa đơn nhà cung cấp — Tổng Tài tự động lưu '
        'thông tin để bạn tìm và so sánh nhà cung cấp trong vài giây.',
  ),
  TongtaiOnboardingPage(
    id: 'inventory',
    icon: Icons.inventory_2,
    accentColor: TongtaiDesignTokens.inventoryOrange,
    headlineEn: 'Manage Your Inventory',
    headlineVi: 'Quản Lý Kho Hàng',
    bodyEn: 'Track products, stock levels, and warehouses in one place — so '
        'you never run out or over-order again.',
    bodyVi: 'Theo dõi sản phẩm, tồn kho và kho hàng ở một nơi — để bạn không '
        'bao giờ hết hàng hay nhập dư.',
  ),
  TongtaiOnboardingPage(
    id: 'customers',
    icon: Icons.groups,
    accentColor: TongtaiDesignTokens.consumerBlue,
    headlineEn: 'Know Your Customers',
    headlineVi: 'Hiểu Rõ Khách Hàng',
    bodyEn: 'Keep customer profiles, orders, and history close at hand, so '
        'every relationship keeps growing.',
    bodyVi: 'Lưu hồ sơ, đơn hàng và lịch sử khách hàng trong tầm tay, để mỗi '
        'mối quan hệ luôn phát triển.',
  ),
  TongtaiOnboardingPage(
    id: 'ai_chat',
    icon: Icons.smart_toy,
    accentColor: TongtaiDesignTokens.copilotViolet,
    headlineEn: 'Ask Your AI Copilot',
    headlineVi: 'Trò Chuyện Cùng Trợ Lý AI',
    bodyEn: 'Chat with your AI assistant for advice, summaries, and quick '
        'answers about your business — anytime.',
    bodyVi: 'Trò chuyện với trợ lý AI để nhận lời khuyên, tóm tắt và câu trả '
        'lời nhanh về việc kinh doanh — bất cứ lúc nào.',
  ),
  TongtaiOnboardingPage(
    id: 'journeys',
    icon: Icons.route,
    accentColor: TongtaiDesignTokens.financePurple,
    headlineEn: 'Build Business Journeys',
    headlineVi: 'Tạo Hành Trình Kinh Doanh',
    bodyEn: 'Turn your goals into guided journeys — Tổng Tài maps the steps and '
        "helps you follow through. You're all set!",
    bodyVi: 'Biến mục tiêu thành hành trình có hướng dẫn — Tổng Tài vạch ra các '
        'bước và đồng hành cùng bạn. Bạn đã sẵn sàng!',
  ),
];
