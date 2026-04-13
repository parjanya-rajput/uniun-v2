part of 'brahma_create_bloc.dart';

enum BrahmaCreateStatus { idle, submitting, success, error, loadingDrafts }

class BrahmaCreateState {
  const BrahmaCreateState({
    this.status = BrahmaCreateStatus.idle,
    this.errorMessage,
    this.drafts = const [],
  });

  final BrahmaCreateStatus status;
  final String? errorMessage;
  final List<DraftEntity> drafts;

  bool get isSubmitting => status == BrahmaCreateStatus.submitting;

  BrahmaCreateState copyWith({
    BrahmaCreateStatus? status,
    String? errorMessage,
    List<DraftEntity>? drafts,
  }) {
    return BrahmaCreateState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      drafts: drafts ?? this.drafts,
    );
  }
}

// Import placeholder for DraftEntity — added by bloc
// This is provided by the import at the top of brahma_create_bloc.dart
