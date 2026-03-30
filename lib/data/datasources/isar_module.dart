import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uniun/data/models/note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
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
      ],
      directory: dir.path,
    );
  }
}
