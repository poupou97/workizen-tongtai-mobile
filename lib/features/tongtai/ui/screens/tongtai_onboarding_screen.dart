import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../onboarding/tongtai_onboarding_content.dart';

/// First-launch onboarding tutorial for Tổng Tài (WTM-59).
///
/// A horizontally swipeable [PageView] of 5-6 feature screens with smooth
/// slide-and-fade transitions, a page indicator, a Skip button on every screen,
/// and a primary button that advances (Next) until the final screen, where it
/// becomes Get Started. Skipping or finishing both call [onFinished].
///
/// The widget is intentionally state-store agnostic — it takes an [onFinished]
/// callback rather than reaching into Riverpod — so it is trivially testable and
/// reusable (e.g. replayed from Settings). Wiring to the persisted "seen" flag
/// lives in [TongtaiRootGate].
class TongtaiOnboardingScreen extends StatefulWidget {
  const TongtaiOnboardingScreen({
    super.key,
    required this.onFinished,
    this.pages = kTongtaiOnboardingPages,
  }) : assert(pages.length > 0, 'Onboarding needs at least one page');

  /// Invoked when the user finishes the last screen or taps Skip. The host
  /// decides what happens next (persist the flag + show Home).
  final VoidCallback onFinished;

  /// The tutorial content. Defaults to [kTongtaiOnboardingPages]; overridable
  /// for tests.
  final List<TongtaiOnboardingPage> pages;

  @override
  State<TongtaiOnboardingScreen> createState() =>
      _TongtaiOnboardingScreenState();
}

class _TongtaiOnboardingScreenState extends State<TongtaiOnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == widget.pages.length - 1;

  void _onPrimaryPressed() {
    if (_isLast) {
      widget.onFinished();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final pages = widget.pages;
    final accent = pages[_index].accentColor;

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip — present on every screen (AC3).
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TongtaiDesignTokens.spacing2,
                  vertical: TongtaiDesignTokens.spacing1,
                ),
                child: TextButton(
                  key: const ValueKey('tongtai_onboarding_skip'),
                  onPressed: widget.onFinished,
                  style: TextButton.styleFrom(
                    foregroundColor: TongtaiDesignTokens.lightTextSecondary,
                  ),
                  child: Text(context.l10n.actionSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _OnboardingPageView(
                  page: pages[i],
                  index: i,
                  controller: _controller,
                  languageCode: languageCode,
                ),
              ),
            ),
            _PageIndicator(
              count: pages.length,
              index: _index,
              activeColor: accent,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing6),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TongtaiDesignTokens.spacing6,
                0,
                TongtaiDesignTokens.spacing6,
                TongtaiDesignTokens.spacing6,
              ),
              child: SizedBox(
                width: double.infinity,
                height: TongtaiDesignTokens.buttonHeight,
                child: ElevatedButton(
                  key: const ValueKey('tongtai_onboarding_next'),
                  onPressed: _onPrimaryPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        TongtaiDesignTokens.radiusLg,
                      ),
                    ),
                  ),
                  child: Text(
                    _isLast
                        ? context.l10n.actionGetStarted
                        : context.l10n.actionNext,
                    style: TongtaiDesignTokens.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single onboarding page: a tinted illustration circle, a headline, and body
/// copy — all faded and slid into place based on the [PageView] scroll offset,
/// so pages cross-dissolve as the user swipes (AC1).
class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({
    required this.page,
    required this.index,
    required this.controller,
    required this.languageCode,
  });

  final TongtaiOnboardingPage page;
  final int index;
  final PageController controller;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // How far this page is from the centered position, in page-units.
        var delta = 0.0;
        if (controller.hasClients && controller.position.haveDimensions) {
          delta = (controller.page ?? index.toDouble()) - index;
        }
        final t = (1 - delta.abs()).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TongtaiDesignTokens.spacing8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: page.accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(page.icon, size: 72, color: page.accentColor),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing8),
            Text(
              page.headlineFor(languageCode),
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.heading2Style.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            Text(
              page.bodyFor(languageCode),
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of dots showing progress; the active dot stretches into a pill in the
/// current page's accent color.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.index,
    required this.activeColor,
  });

  final int count;
  final int index;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(
            horizontal: TongtaiDesignTokens.spacing1,
          ),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? activeColor : TongtaiDesignTokens.lightBorder,
            borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
          ),
        );
      }),
    );
  }
}
