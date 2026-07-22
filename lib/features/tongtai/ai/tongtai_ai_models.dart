import 'package:flutter/foundation.dart';

import 'tongtai_ai_provider_kind.dart';

/// A chat turn's author, mapped to the OpenAI-compatible `role` field.
enum TongtaiAiRole {
  system,
  user,
  assistant;

  /// Wire value sent to the provider.
  String get wire => name;
}

/// One message in a chat exchange (WTM-61). Immutable so callers can hold a
/// conversation as a plain list.
@immutable
class TongtaiAiMessage {
  const TongtaiAiMessage(this.role, this.content);

  /// Convenience constructor for a user turn.
  const TongtaiAiMessage.user(this.content) : role = TongtaiAiRole.user;

  /// Convenience constructor for an assistant turn.
  const TongtaiAiMessage.assistant(this.content)
    : role = TongtaiAiRole.assistant;

  /// Convenience constructor for a system turn.
  const TongtaiAiMessage.system(this.content) : role = TongtaiAiRole.system;

  final TongtaiAiRole role;
  final String content;

  /// OpenAI-compatible `{role, content}` shape.
  Map<String, dynamic> toJson() => {'role': role.wire, 'content': content};

  @override
  bool operator ==(Object other) =>
      other is TongtaiAiMessage &&
      other.role == role &&
      other.content == content;

  @override
  int get hashCode => Object.hash(role, content);
}

/// A parsed successful reply from the AI provider (WTM-61 AC: "returns valid
/// response"). Token counts are optional — not every provider reports usage.
@immutable
class TongtaiAiResponse {
  const TongtaiAiResponse({
    required this.text,
    required this.provider,
    required this.model,
    this.inputTokens,
    this.outputTokens,
  });

  /// The assistant's answer text.
  final String text;

  /// Which provider produced it.
  final TongtaiAiProviderKind provider;

  /// The model that actually answered (echoed by the provider, or the requested
  /// model as a fallback).
  final String model;

  /// Prompt tokens billed, when reported.
  final int? inputTokens;

  /// Completion tokens billed, when reported.
  final int? outputTokens;

  @override
  bool operator ==(Object other) =>
      other is TongtaiAiResponse &&
      other.text == text &&
      other.provider == provider &&
      other.model == model &&
      other.inputTokens == inputTokens &&
      other.outputTokens == outputTokens;

  @override
  int get hashCode =>
      Object.hash(text, provider, model, inputTokens, outputTokens);
}
