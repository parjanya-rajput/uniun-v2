import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';

/// Data loaded once per session from Isar.
/// Personalises every prompt even when the user has zero saved notes.
class PersonalizationContext {
  const PersonalizationContext({
    this.userName,
    this.userBio,
  });

  final String? userName;
  final String? userBio;
}

/// Assembles prompts for Shiv inference.
///
/// ## Architecture
/// flutter_gemma's [InferenceChat] manages conversation history internally.
/// We must NOT embed history in our prompts — that causes every prior turn to
/// be repeated inside the model's context window.
///
/// Instead we split into two pieces:
///
/// **[buildSystemInstruction]** — called ONCE when a conversation opens.
/// Produces the static system instruction: Shiv persona + user name/bio +
/// interests. Passed to [InferenceChat] via `createChat(systemInstruction:)`.
///
/// **[buildUserMessage]** — called for EVERY user turn.
/// Produces only: the RAG context block (if notes were retrieved) +
/// the current user question. No history, no system repeated.
@lazySingleton
class PromptBuilder {
  const PromptBuilder();

  // ── Session-level (set once) ────────────────────────────────────────────────

  /// Builds the static system instruction injected once per conversation.
  String buildSystemInstruction(PersonalizationContext personalization) {
    final buf = StringBuffer();

    final name = personalization.userName;
    final bio = personalization.userBio;

    buf.writeln('You are an AI assistant called Shiv, built into UNIUN. Always identify yourself as Shiv.');

    if (name != null && name.isNotEmpty) {
      buf.writeln('The user\'s name is $name (not yours — yours is Shiv).');
      if (bio != null && bio.isNotEmpty) {
        buf.writeln('About the user: $bio');
      }
    }

    buf.writeln('Answer concisely and helpfully.');
    buf.writeln('If you reason before answering, keep your thinking brief — do not over-reason.');

    debugPrint('🤖 System instruction built — name: $name, bio: $bio');

    return buf.toString().trimRight();
  }

  // ── Branch context (called on branch switch) ──────────────────────────────

  /// Summarises a branch's conversation for injection into the system instruction
  /// when the user switches branches.
  ///
  /// Takes the last 6 messages (3 exchanges). For each message:
  /// - User turns: first sentence or up to 100 chars — questions are short.
  /// - AI turns: strips markdown formatting, extracts the first complete sentence
  ///   (up to 220 chars) — avoids cutting a long response mid-thought.
  String buildBranchContextSummary(List<ShivMessageEntity> branch) {
    if (branch.isEmpty) return '';
    final recent = branch.length > 6 ? branch.sublist(branch.length - 6) : branch;
    final buf = StringBuffer('\n[Previous conversation context on this branch]\n');
    for (final m in recent) {
      final isUser = m.role.name == 'user';
      final role = isUser ? 'User' : 'Shiv';
      final preview = isUser
          ? _summarizeUser(m.content)
          : _summarizeAssistant(m.content);
      buf.writeln('$role: $preview');
    }
    buf.write('[Continue naturally from this context]');
    return buf.toString();
  }

  /// First sentence of a user message (≤ 100 chars).
  String _summarizeUser(String content) {
    final text = content.trim();
    return _firstSentence(text, 100);
  }

  /// First complete sentence of an AI response with markdown stripped (≤ 220 chars).
  String _summarizeAssistant(String content) {
    // Strip common markdown: headers, bold, italic, inline code, bullet leaders
    final clean = content
        .replaceAll(RegExp(r'#{1,6}\s+'), '')
        .replaceAll(RegExp(r'\*{1,2}([^*]+)\*{1,2}'), r'\1')
        .replaceAll(RegExp(r'`[^`]*`'), '')
        .replaceAll(RegExp(r'^[\-\*]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '')
        .trim();
    return _firstSentence(clean, 220);
  }

  /// Extracts the first complete sentence up to [limit] chars.
  /// Falls back to plain truncation if no sentence boundary is found early enough.
  String _firstSentence(String text, int limit) {
    if (text.isEmpty) return '…';
    // Look for sentence-ending punctuation followed by space or end-of-string
    final match = RegExp(r'[.!?](?:\s|$)').firstMatch(text);
    if (match != null && match.end <= limit) {
      return text.substring(0, match.end).trim();
    }
    // No early sentence boundary — truncate at limit
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}…';
  }

  // ── Per-turn (called each message) ─────────────────────────────────────────

  /// Builds the user-turn message: optional RAG context block + the question.
  /// This is the ONLY thing added to [InferenceChat] per turn — no history,
  /// no system prompt repetition.
  String buildUserMessage({
    required String userQuestion,
    required List<ScoredNote> relevantNotes,
  }) {
    if (relevantNotes.isEmpty) return userQuestion;

    final buf = StringBuffer();
    buf.writeln('[Relevant notes from your knowledge base:]');
    for (final scored in relevantNotes) {
      buf.writeln('• ${scored.content}');
    }
    buf.writeln('[End of notes]');
    buf.writeln();
    buf.write(userQuestion);
    return buf.toString();
  }
}
