import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/repositories/saved_note_repository.dart';

@Injectable(as: SavedNoteRepository)
class SavedNoteRepositoryImpl extends SavedNoteRepository {
  final Isar isar;
  SavedNoteRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, SavedNoteEntity>> saveNote(NoteEntity note) async {
    try {
      final existing = await isar.savedNoteModels
          .where()
          .eventIdEqualTo(note.id)
          .findFirst();
      if (existing != null) return Right(existing.toDomain());

      final model = SavedNoteModel()
        ..eventId = note.id
        ..sig = note.sig
        ..authorPubkey = note.authorPubkey
        ..content = note.content
        ..type = note.type
        ..eTagRefs = note.eTagRefs
        ..rootEventId = note.rootEventId
        ..replyToEventId = note.replyToEventId
        ..pTagRefs = note.pTagRefs
        ..tTags = note.tTags
        ..created = note.created
        ..savedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.savedNoteModels.put(model);
        // Increment counts on saved notes that this note references.
        // Same exclusion logic as NoteRepository: only direct parent +
        // mention-refs, not the root-tag when a deeper reply target exists.
        final toIncrement = <String>{};
        if (note.replyToEventId != null) {
          toIncrement.add(note.replyToEventId!);
        }
        for (final ref in note.eTagRefs) {
          if (ref != note.rootEventId && ref != note.replyToEventId) {
            toIncrement.add(ref);
          }
        }
        for (final refId in toIncrement) {
          final ref = await isar.savedNoteModels
              .where()
              .eventIdEqualTo(refId)
              .findFirst();
          if (ref != null) {
            ref.cachedReplyCount++;
            await isar.savedNoteModels.put(ref);
          }
        }
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> unsaveNote(String eventId) async {
    try {
      await isar.writeTxn(() async {
        final model = await isar.savedNoteModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (model == null) return;
        // Decrement counts on saved notes this note was referencing.
        final toDecrement = <String>{};
        if (model.replyToEventId != null) {
          toDecrement.add(model.replyToEventId!);
        }
        for (final ref in model.eTagRefs) {
          if (ref != model.rootEventId && ref != model.replyToEventId) {
            toDecrement.add(ref);
          }
        }
        for (final refId in toDecrement) {
          final ref = await isar.savedNoteModels
              .where()
              .eventIdEqualTo(refId)
              .findFirst();
          if (ref != null && ref.cachedReplyCount > 0) {
            ref.cachedReplyCount--;
            await isar.savedNoteModels.put(ref);
          }
        }
        await isar.savedNoteModels.delete(model.id);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isSaved(String eventId) async {
    try {
      final exists = await isar.savedNoteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      return Right(exists != null);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SavedNoteEntity>>> getAll() async {
    try {
      final all = await isar.savedNoteModels
          .where()
          .sortBySavedAtDesc()
          .findAll();
      await _backfillReplyCountsIfNeeded(all);
      return Right(all.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  Future<void> _backfillReplyCountsIfNeeded(List<SavedNoteModel> models) async {
    final toUpdate = <SavedNoteModel>[];
    for (final m in models) {
      // Count only OTHER saved notes that reference this one — not all relay notes.
      final totalEtag = await isar.savedNoteModels
          .filter()
          .eTagRefsElementEqualTo(m.eventId)
          .count();
      // Subtract nested thread replies (saved notes that have m as root but
      // reply to someone else — they shouldn't count as a direct interaction).
      final nestedOnly = await isar.savedNoteModels
          .filter()
          .rootEventIdEqualTo(m.eventId)
          .not()
          .replyToEventIdEqualTo(m.eventId)
          .replyToEventIdIsNotNull()
          .count();
      final count = totalEtag - nestedOnly;
      if (count != m.cachedReplyCount) {
        m.cachedReplyCount = count;
        toUpdate.add(m);
      }
    }
    if (toUpdate.isEmpty) return;
    await isar.writeTxn(() async {
      for (final m in toUpdate) {
        await isar.savedNoteModels.put(m);
      }
    });
  }

  @override
  Future<Either<Failure, int>> getSavedReplyCount(String eventId) async {
    try {
      final count = await isar.savedNoteModels
          .filter()
          .rootEventIdEqualTo(eventId)
          .count();
      return Right(count);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
