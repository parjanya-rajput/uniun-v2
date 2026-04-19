import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

@Injectable(as: NoteRepository)
class NoteRepositoryImpl extends NoteRepository {
  final Isar isar;

  NoteRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, List<NoteEntity>>> getFeed({
    required int limit,
    DateTime? before,
  }) async {
    try {
      // Feed shows every note — top-level posts, replies, and references.
      // Replies and refs are also notes; they belong in the stream.
      final notes = before != null
          ? await isar.noteModels
              .filter()
              .createdLessThan(before)
              .sortByCreatedDesc()
              .limit(limit)
              .findAll()
          : await isar.noteModels
              .where()
              .sortByCreatedDesc()
              .limit(limit)
              .findAll();

      return Right(notes.map((n) => n.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> getNoteById(String eventId) async {
    try {
      final note = await isar.noteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (note == null) {
        return const Left(Failure.errorFailure('Note not found'));
      }
      return Right(note.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getReplies(String eventId) async {
    try {
      // NIP-10 replies: this event is the immediate parent.
      final standard = await isar.noteModels
          .filter()
          .replyToEventIdEqualTo(eventId)
          .sortByCreated()
          .findAll();

      // Incoming eTagRef mentions: notes whose eTagRefs list contains this
      // event, but which are not already NIP-10 reply/root children.
      final mentions = await isar.noteModels
          .filter()
          .eTagRefsElementEqualTo(eventId)
          .not().replyToEventIdEqualTo(eventId)
          .not().rootEventIdEqualTo(eventId)
          .sortByCreated()
          .findAll();

      final seen = <String>{};
      final merged = [...standard, ...mentions]
          .where((n) => seen.add(n.eventId))
          .toList()
        ..sort((a, b) => a.created.compareTo(b.created));
      return Right(merged.map((n) => n.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getThread(
    String rootEventId,
  ) async {
    try {
      // Root note
      final root = await isar.noteModels
          .where()
          .eventIdEqualTo(rootEventId)
          .findFirst();

      // All notes in the thread (rootEventId == rootEventId), chronological
      final replies = await isar.noteModels
          .filter()
          .rootEventIdEqualTo(rootEventId)
          .sortByCreated()
          .findAll();

      final all = [if (root != null) root, ...replies];

      return Right(all.map((n) => n.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> saveNote(NoteEntity note) async {
    try {
      final existing = await isar.noteModels
          .where()
          .eventIdEqualTo(note.id)
          .findFirst();

      if (existing != null) {
        return Right(existing.toDomain());
      }

      final model = NoteModel(
        eventId: note.id,
        sig: note.sig,
        authorPubkey: note.authorPubkey,
        content: note.content,
        subject: note.subject,
        type: note.type,
        eTagRefs: note.eTagRefs,
        rootEventId: note.rootEventId,
        replyToEventId: note.replyToEventId,
        pTagRefs: note.pTagRefs,
        tTags: note.tTags,
        created: note.created,
        isSeen: note.isSeen,
      );

      await isar.writeTxn(() async {
        await isar.noteModels.put(model);
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getReplyCount(String eventId) async {
    try {
      final standardIds = await isar.noteModels
          .filter()
          .replyToEventIdEqualTo(eventId)
          .eventIdProperty()
          .findAll();

      final mentionIds = await isar.noteModels
          .filter()
          .eTagRefsElementEqualTo(eventId)
          .not().replyToEventIdEqualTo(eventId)
          .not().rootEventIdEqualTo(eventId)
          .eventIdProperty()
          .findAll();

      final unique = {...standardIds, ...mentionIds};
      return Right(unique.length);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getThreadReplyCount(String rootEventId) async {
    try {
      final count = await isar.noteModels
          .filter()
          .rootEventIdEqualTo(rootEventId)
          .count();
      return Right(count);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsSeen(String eventId) async {
    try {
      await isar.writeTxn(() async {
        final note = await isar.noteModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (note != null) {
          note.isSeen = true;
          await isar.noteModels.put(note);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getOwnNotes(
      String pubkeyHex) async {
    try {
      final notes = await isar.noteModels
          .filter()
          .authorPubkeyEqualTo(pubkeyHex)
          .sortByCreatedDesc()
          .findAll();
      return Right(notes.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> searchNotes(String query) async {
    try {
      if (query.trim().isEmpty) return const Right([]);
      final results = await isar.noteModels
          .filter()
          .contentContains(query.trim(), caseSensitive: false)
          .sortByCreatedDesc()
          .limit(30)
          .findAll();
      return Right(results.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateNoteEmbedding(
      String eventId, List<double> embedding) async {
    try {
      await isar.writeTxn(() async {
        final note = await isar.noteModels
            .filter()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (note != null) {
          note.embedding = embedding;
          await isar.noteModels.put(note);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
