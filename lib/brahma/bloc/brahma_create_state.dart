part of 'brahma_create_bloc.dart';

enum BrahmaCreateStatus { idle, submitting, success, error }

class BrahmaCreateState {
  const BrahmaCreateState({
    this.content = '',
    this.extractedTags = const [],
    this.status = BrahmaCreateStatus.idle,
    this.errorMessage,
    this.publishedNoteId,
  });

  final String content;
  final List<String> extractedTags;
  final BrahmaCreateStatus status;
  final String? errorMessage;
  final String? publishedNoteId;

  bool get canSubmit =>
      content.trim().isNotEmpty && status != BrahmaCreateStatus.submitting;

  int get charCount => content.length;

  BrahmaCreateState copyWith({
    String? content,
    List<String>? extractedTags,
    BrahmaCreateStatus? status,
    String? errorMessage,
    String? publishedNoteId,
  }) {
    return BrahmaCreateState(
      content: content ?? this.content,
      extractedTags: extractedTags ?? this.extractedTags,
      status: status ?? this.status,
      errorMessage: errorMessage,
      publishedNoteId: publishedNoteId ?? this.publishedNoteId,
    );
  }
}
