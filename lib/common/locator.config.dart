// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:isar_community/isar.dart' as _i214;

// Infrastructure
import 'package:uniun/core/isolate/embedded_server_bridge.dart' as _i717;
import 'package:uniun/data/datasources/isar_module.dart' as _i146;

// Data repositories
import 'package:uniun/data/repositories/followed_note_repository_impl.dart'
    as _i107;
import 'package:uniun/data/repositories/note_repository_impl.dart' as _i350;
import 'package:uniun/data/repositories/outbound_event_repository_impl.dart'
    as _i694;
import 'package:uniun/data/repositories/profile_repository_impl.dart' as _i484;
import 'package:uniun/data/repositories/saved_note_repository_impl.dart'
    as _i669;
import 'package:uniun/data/repositories/user_repository_impl.dart' as _i582;

// Domain repository interfaces
import 'package:uniun/domain/repositories/followed_note_repository.dart'
    as _i836;
import 'package:uniun/domain/repositories/note_repository.dart' as _i47;
import 'package:uniun/domain/repositories/outbound_event_repository.dart'
    as _i218;
import 'package:uniun/domain/repositories/profile_repository.dart' as _i967;
import 'package:uniun/domain/repositories/saved_note_repository.dart' as _i43;
import 'package:uniun/domain/repositories/user_repository.dart' as _i103;

// Use case modules
import 'package:uniun/domain/usecases/note_usecases.dart' as _noteUC;
import 'package:uniun/domain/usecases/saved_note_usecases.dart' as _savedUC;
import 'package:uniun/domain/usecases/profile_usecases.dart' as _profileUC;
import 'package:uniun/domain/usecases/user_usecases.dart' as _userUC;
import 'package:uniun/domain/usecases/followed_note_usecases.dart'
    as _followedUC;

// BLoC / Cubit
import 'package:uniun/brahma/bloc/brahma_create_bloc.dart' as _i787;
import 'package:uniun/home/bloc/drawer_bloc.dart' as _i987;
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart' as _i97;
import 'package:uniun/followed_notes/followed_note_detail/cubit/followed_note_detail_cubit.dart'
    as _i928;
import 'package:uniun/settings/cubit/edit_profile_cubit.dart' as _i195;
import 'package:uniun/settings/cubit/settings_cubit.dart' as _i731;
import 'package:uniun/thread/bloc/thread_bloc.dart' as _i118;
import 'package:uniun/vishnu/bloc/vishnu_feed_bloc.dart' as _i558;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final isarModule = _$IsarModule();

    // ── Singletons ────────────────────────────────────────────────────────────

    gh.singleton<_i717.EmbeddedServerBridge>(
      () => _i717.EmbeddedServerBridge(),
    );
    await gh.singletonAsync<_i214.Isar>(
      () => isarModule.createIsar(),
      preResolve: true,
    );

    // ── Repository factories ──────────────────────────────────────────────────

    gh.factory<_i47.NoteRepository>(
      () => _i350.NoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i836.FollowedNoteRepository>(
      () => _i107.FollowedNoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i218.OutboundEventRepository>(
      () => _i694.OutboundEventRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i43.SavedNoteRepository>(
      () => _i669.SavedNoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i967.ProfileRepository>(
      () => _i484.ProfileRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i103.UserRepository>(
      () => _i582.UserRepositoryImpl(isar: gh<_i214.Isar>()),
    );

    // ── Note use cases ────────────────────────────────────────────────────────

    gh.lazySingleton<_noteUC.GetFeedUseCase>(
      () => _noteUC.GetFeedUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_noteUC.GetNoteByIdUseCase>(
      () => _noteUC.GetNoteByIdUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_noteUC.GetRepliesUseCase>(
      () => _noteUC.GetRepliesUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_noteUC.SaveNoteUseCase>(
      () => _noteUC.SaveNoteUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_noteUC.MarkSeenUseCase>(
      () => _noteUC.MarkSeenUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_noteUC.GetThreadUseCase>(
      () => _noteUC.GetThreadUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_noteUC.GetReplyCountUseCase>(
      () => _noteUC.GetReplyCountUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_noteUC.GetThreadReplyCountUseCase>(
      () => _noteUC.GetThreadReplyCountUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_noteUC.PublishNoteUseCase>(
      () => _noteUC.PublishNoteUseCase(
        gh<_i47.NoteRepository>(),
        gh<_i218.OutboundEventRepository>(),
        gh<_i717.EmbeddedServerBridge>(),
      ),
    );

    // ── Saved note use cases ──────────────────────────────────────────────────

    gh.lazySingleton<_savedUC.ToggleSaveUseCase>(
      () => _savedUC.ToggleSaveUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_savedUC.IsSavedNoteUseCase>(
      () => _savedUC.IsSavedNoteUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_savedUC.GetAllSavedNotesUseCase>(
      () => _savedUC.GetAllSavedNotesUseCase(gh<_i43.SavedNoteRepository>()),
    );

    // ── Profile use cases ─────────────────────────────────────────────────────

    gh.lazySingleton<_profileUC.GetProfileUseCase>(
      () => _profileUC.GetProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_profileUC.GetOwnProfileUseCase>(
      () => _profileUC.GetOwnProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_profileUC.SaveProfileUseCase>(
      () => _profileUC.SaveProfileUseCase(gh<_i967.ProfileRepository>()),
    );

    // ── User use cases ────────────────────────────────────────────────────────

    gh.lazySingleton<_userUC.GetActiveUserUseCase>(
      () => _userUC.GetActiveUserUseCase(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_userUC.GetActiveUserKeysUseCase>(
      () => _userUC.GetActiveUserKeysUseCase(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_userUC.ImportKeyUseCase>(
      () => _userUC.ImportKeyUseCase(gh<_i103.UserRepository>()),
    );

    // ── Followed note use cases ───────────────────────────────────────────────

    gh.lazySingleton<_followedUC.GetAllFollowedNotesUseCase>(
      () => _followedUC.GetAllFollowedNotesUseCase(
          gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_followedUC.FollowNoteUseCase>(
      () =>
          _followedUC.FollowNoteUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_followedUC.UnfollowNoteUseCase>(
      () =>
          _followedUC.UnfollowNoteUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_followedUC.ClearNewReferencesUseCase>(
      () => _followedUC.ClearNewReferencesUseCase(
          gh<_i836.FollowedNoteRepository>()),
    );

    // ── BLoC / Cubit factories ────────────────────────────────────────────────

    gh.factory<_i928.FollowedNoteDetailCubit>(
      () => _i928.FollowedNoteDetailCubit(
        gh<_noteUC.GetNoteByIdUseCase>(),
        gh<_noteUC.GetRepliesUseCase>(),
        gh<_profileUC.GetProfileUseCase>(),
      ),
    );
    gh.factory<_i97.FollowedNotesCubit>(
      () => _i97.FollowedNotesCubit(
        gh<_followedUC.GetAllFollowedNotesUseCase>(),
        gh<_followedUC.FollowNoteUseCase>(),
        gh<_followedUC.UnfollowNoteUseCase>(),
        gh<_followedUC.ClearNewReferencesUseCase>(),
      ),
    );
    gh.factory<_i987.DrawerBloc>(
      () => _i987.DrawerBloc(
        gh<_userUC.GetActiveUserUseCase>(),
        gh<_profileUC.GetOwnProfileUseCase>(),
        gh<_followedUC.GetAllFollowedNotesUseCase>(),
      ),
    );
    gh.factory<_i787.BrahmaCreateBloc>(
      () => _i787.BrahmaCreateBloc(
        gh<_userUC.GetActiveUserKeysUseCase>(),
        gh<_noteUC.PublishNoteUseCase>(),
      ),
    );
    gh.factory<_i118.ThreadBloc>(
      () => _i118.ThreadBloc(
        gh<_noteUC.GetNoteByIdUseCase>(),
        gh<_noteUC.GetRepliesUseCase>(),
        gh<_noteUC.PublishNoteUseCase>(),
        gh<_profileUC.GetProfileUseCase>(),
        gh<_noteUC.GetReplyCountUseCase>(),
        gh<_userUC.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factory<_i731.SettingsCubit>(
      () => _i731.SettingsCubit(
        gh<_userUC.GetActiveUserUseCase>(),
        gh<_profileUC.GetOwnProfileUseCase>(),
      ),
    );
    gh.factory<_i195.EditProfileCubit>(
      () => _i195.EditProfileCubit(
        gh<_userUC.GetActiveUserUseCase>(),
        gh<_profileUC.GetOwnProfileUseCase>(),
        gh<_profileUC.SaveProfileUseCase>(),
      ),
    );
    gh.factory<_i558.VishnuFeedBloc>(
      () => _i558.VishnuFeedBloc(
        gh<_noteUC.GetFeedUseCase>(),
        gh<_profileUC.GetProfileUseCase>(),
        gh<_noteUC.GetThreadReplyCountUseCase>(),
        gh<_savedUC.GetAllSavedNotesUseCase>(),
        gh<_savedUC.ToggleSaveUseCase>(),
      ),
    );

    return this;
  }
}

class _$IsarModule extends _i146.IsarModule {}
