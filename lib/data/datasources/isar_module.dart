import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uniun/data/models/ai_model_selection_model.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/dm/dm_message_model.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/channel_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/models/shiv_conversation_model.dart';
import 'package:uniun/data/models/shiv_message_model.dart';
import 'package:uniun/data/models/subscription_record_model.dart';
import 'package:uniun/data/models/user_key_model.dart';

@module
abstract class IsarModule {
  @singleton
  @preResolve
  Future<Isar> createIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        NoteModelSchema,
        UserKeyModelSchema,
        ProfileModelSchema,
        FollowedNoteModelSchema,
        EventQueueModelSchema,
        DmConversationModelSchema,
        DmMessageModelSchema,
        SavedNoteModelSchema,
        AIModelSelectionModelSchema,
        ShivConversationModelSchema,
        ShivMessageModelSchema,
        ChannelModelSchema,
        SubscriptionRecordModelSchema,
      ],
      directory: dir.path,
    );
  }
}
