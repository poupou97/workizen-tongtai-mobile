import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../profile/business_profile.dart';
import '../../providers/tongtai_profile_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart'
    show TongtaiAsyncScreenData, showTongtaiFailure;

/// "Thông tin doanh nghiệp" — the AI Business Profile editor (WTM-177).
///
/// Four categorical questions, every one skippable. The screen exists so the
/// AI stops giving a 40-SKU boutique the same advice as a 4,000-SKU importer.
///
/// **Why there is no text field anywhere on this screen:** the profile is sent
/// with every AI question, so a free-text box is where a seller would type a
/// customer's name and phone number and then ship it to a provider forever
/// after. Every answer is a chip from a closed vocabulary. That is enforced by
/// the model itself (`tongtai_business_profile_privacy_test.dart`), and this
/// screen simply has nothing to offer that could break it.
class TongtaiBusinessProfileScreen extends ConsumerStatefulWidget {
  const TongtaiBusinessProfileScreen({super.key});

  @override
  ConsumerState<TongtaiBusinessProfileScreen> createState() =>
      _TongtaiBusinessProfileScreenState();
}

class _TongtaiBusinessProfileScreenState
    extends ConsumerState<TongtaiBusinessProfileScreen> {
  BusinessProfile? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stored = ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        // ADR-TON-017: no hand-rolled `AsyncValue.when` in `ui/`. The first
        // draft of this screen used one with a comment arguing the seam would
        // be ceremony here — the governance suite disagreed, and it was right:
        // the seam is what guarantees a failed read looks like a failure and
        // not like an empty profile the seller never filled in.
        child: TongtaiAsyncScreenData<BusinessProfile>(
          prefix: 'profile',
          async: stored,
          onRetry: () async => ref.invalidate(businessProfileProvider),
          builder: (context, loaded) {
            final profile = _draft ?? loaded;
            return ListView(
              key: const Key('profile-list'),
              padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
              children: [
                Text(
                  l10n.profileIntro,
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: TongtaiDesignTokens.spacing5),
                _SingleChoice<BusinessTrade>(
                  label: l10n.profileTradeLabel,
                  keyPrefix: 'profile-trade',
                  values: BusinessTrade.values,
                  selected: profile.trade,
                  labelOf: (v) => l10n.profileTrade(v.code),
                  onChanged: (v) =>
                      setState(() => _draft = _clearable(profile, trade: v)),
                ),
                _SingleChoice<BusinessSize>(
                  label: l10n.profileSizeLabel,
                  keyPrefix: 'profile-size',
                  values: BusinessSize.values,
                  selected: profile.size,
                  labelOf: (v) => l10n.profileSize(v.code),
                  onChanged: (v) =>
                      setState(() => _draft = _clearable(profile, size: v)),
                ),
                _MultiChoice(
                  label: l10n.profileChannelsLabel,
                  selected: profile.channels,
                  labelOf: (v) => l10n.profileChannel(v.code),
                  onChanged: (channels) => setState(
                    () => _draft = _clearable(profile, channels: channels),
                  ),
                ),
                _SingleChoice<BusinessSeasonality>(
                  label: l10n.profileSeasonalityLabel,
                  keyPrefix: 'profile-season',
                  values: BusinessSeasonality.values,
                  selected: profile.seasonality,
                  labelOf: (v) => l10n.profileSeasonality(v.code),
                  onChanged: (v) => setState(
                    () => _draft = _clearable(profile, seasonality: v),
                  ),
                ),
                const SizedBox(height: TongtaiDesignTokens.spacing4),
                _PrivacyNote(text: l10n.profilePrivacyNote),
                const SizedBox(height: TongtaiDesignTokens.spacing5),
                SizedBox(
                  height: TongtaiDesignTokens.buttonHeight,
                  child: FilledButton(
                    key: const Key('profile-save'),
                    onPressed: _saving ? null : () => _save(profile),
                    child: Text(l10n.profileSave),
                  ),
                ),
                const SizedBox(height: TongtaiDesignTokens.spacing2),
                Center(
                  child: Text(
                    l10n.profileSkipHint,
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// `copyWith` cannot express "unset this field" — `null` means "keep". So a
  /// tap that deselects a chip has to build the profile explicitly, otherwise
  /// answers would be one-way and a mis-tap unfixable.
  BusinessProfile _clearable(
    BusinessProfile base, {
    Object? trade = _keep,
    Object? size = _keep,
    List<SalesChannel>? channels,
    Object? seasonality = _keep,
  }) => BusinessProfile(
    trade: identical(trade, _keep) ? base.trade : trade as BusinessTrade?,
    size: identical(size, _keep) ? base.size : size as BusinessSize?,
    channels: channels ?? base.channels,
    seasonality: identical(seasonality, _keep)
        ? base.seasonality
        : seasonality as BusinessSeasonality?,
    updatedAt: base.updatedAt,
  );

  static const Object _keep = Object();

  Future<void> _save(BusinessProfile profile) async {
    setState(() => _saving = true);
    final failure = await runTongtaiAction(
      () => ref.read(businessProfileRepositoryProvider).save(profile),
      screen: 'business-profile',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      showTongtaiFailure(context, failure, onRetry: () => _save(profile));
      return;
    }
    // The profile feeds every AI prompt AND the journey planner
    // (`JourneyPlanInput.profile`), so a stale read here would keep sending
    // the old answers until the app restarts. WTM-224: raise the one signal
    // rather than invalidating a single provider by hand — the list of who
    // cares is `kBusinessDataProviders`, and it grows.
    invalidateBusinessDataProviders(ref);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.profileSaved, key: const Key('profile-saved')),
        ),
      );
  }
}

class _SingleChoice<T> extends StatelessWidget {
  const _SingleChoice({
    required this.label,
    required this.keyPrefix,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final String keyPrefix;
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: label,
      child: Wrap(
        spacing: TongtaiDesignTokens.spacing2,
        runSpacing: TongtaiDesignTokens.spacing2,
        children: [
          for (final value in values)
            ChoiceChip(
              key: Key('$keyPrefix-${values.indexOf(value)}'),
              label: Text(labelOf(value)),
              selected: value == selected,
              // Tapping the selected chip clears it — an answer given by
              // mistake must be removable, not just replaceable.
              onSelected: (on) => onChanged(on ? value : null),
            ),
        ],
      ),
    );
  }
}

class _MultiChoice extends StatelessWidget {
  const _MultiChoice({
    required this.label,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<SalesChannel> selected;
  final String Function(SalesChannel) labelOf;
  final ValueChanged<List<SalesChannel>> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: label,
      child: Wrap(
        spacing: TongtaiDesignTokens.spacing2,
        runSpacing: TongtaiDesignTokens.spacing2,
        children: [
          for (final channel in SalesChannel.values)
            FilterChip(
              key: Key('profile-channel-${channel.index}'),
              label: Text(labelOf(channel)),
              selected: selected.contains(channel),
              onSelected: (on) => onChanged([
                for (final c in SalesChannel.values)
                  if (c == channel ? on : selected.contains(c)) c,
              ]),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TongtaiDesignTokens.bodyStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          child,
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile-privacy-note'),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusLg),
      ),
      child: Text(
        text,
        style: TongtaiDesignTokens.captionStyle.copyWith(
          color: TongtaiDesignTokens.producerGreenText,
          height: 1.5,
        ),
      ),
    );
  }
}
