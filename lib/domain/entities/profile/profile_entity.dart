import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_entity.freezed.dart';

@freezed
abstract class ProfileEntity with _$ProfileEntity {
  const factory ProfileEntity({
    required String pubkey,
    String? name,
    String? username,
    String? about,
    String? avatarUrl,
    String? nip05,
    required DateTime updatedAt,
  }) = _ProfileEntity;
}
