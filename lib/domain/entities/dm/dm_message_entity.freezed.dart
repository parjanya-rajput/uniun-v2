// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dm_message_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DmMessageEntity {

 String get eventId; int get conversationId; String get receiverPubkey; String? get replyToEventId; String get content; String? get subject; int get kind; NoteType get type; DateTime get created; bool get isSeen;
/// Create a copy of DmMessageEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DmMessageEntityCopyWith<DmMessageEntity> get copyWith => _$DmMessageEntityCopyWithImpl<DmMessageEntity>(this as DmMessageEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DmMessageEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.receiverPubkey, receiverPubkey) || other.receiverPubkey == receiverPubkey)&&(identical(other.replyToEventId, replyToEventId) || other.replyToEventId == replyToEventId)&&(identical(other.content, content) || other.content == content)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.type, type) || other.type == type)&&(identical(other.created, created) || other.created == created)&&(identical(other.isSeen, isSeen) || other.isSeen == isSeen));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,conversationId,receiverPubkey,replyToEventId,content,subject,kind,type,created,isSeen);

@override
String toString() {
  return 'DmMessageEntity(eventId: $eventId, conversationId: $conversationId, receiverPubkey: $receiverPubkey, replyToEventId: $replyToEventId, content: $content, subject: $subject, kind: $kind, type: $type, created: $created, isSeen: $isSeen)';
}


}

/// @nodoc
abstract mixin class $DmMessageEntityCopyWith<$Res>  {
  factory $DmMessageEntityCopyWith(DmMessageEntity value, $Res Function(DmMessageEntity) _then) = _$DmMessageEntityCopyWithImpl;
@useResult
$Res call({
 String eventId, int conversationId, String receiverPubkey, String? replyToEventId, String content, String? subject, int kind, NoteType type, DateTime created, bool isSeen
});




}
/// @nodoc
class _$DmMessageEntityCopyWithImpl<$Res>
    implements $DmMessageEntityCopyWith<$Res> {
  _$DmMessageEntityCopyWithImpl(this._self, this._then);

  final DmMessageEntity _self;
  final $Res Function(DmMessageEntity) _then;

/// Create a copy of DmMessageEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? conversationId = null,Object? receiverPubkey = null,Object? replyToEventId = freezed,Object? content = null,Object? subject = freezed,Object? kind = null,Object? type = null,Object? created = null,Object? isSeen = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,receiverPubkey: null == receiverPubkey ? _self.receiverPubkey : receiverPubkey // ignore: cast_nullable_to_non_nullable
as String,replyToEventId: freezed == replyToEventId ? _self.replyToEventId : replyToEventId // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NoteType,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime,isSeen: null == isSeen ? _self.isSeen : isSeen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DmMessageEntity].
extension DmMessageEntityPatterns on DmMessageEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DmMessageEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DmMessageEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DmMessageEntity value)  $default,){
final _that = this;
switch (_that) {
case _DmMessageEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DmMessageEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DmMessageEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  int conversationId,  String receiverPubkey,  String? replyToEventId,  String content,  String? subject,  int kind,  NoteType type,  DateTime created,  bool isSeen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DmMessageEntity() when $default != null:
return $default(_that.eventId,_that.conversationId,_that.receiverPubkey,_that.replyToEventId,_that.content,_that.subject,_that.kind,_that.type,_that.created,_that.isSeen);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  int conversationId,  String receiverPubkey,  String? replyToEventId,  String content,  String? subject,  int kind,  NoteType type,  DateTime created,  bool isSeen)  $default,) {final _that = this;
switch (_that) {
case _DmMessageEntity():
return $default(_that.eventId,_that.conversationId,_that.receiverPubkey,_that.replyToEventId,_that.content,_that.subject,_that.kind,_that.type,_that.created,_that.isSeen);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  int conversationId,  String receiverPubkey,  String? replyToEventId,  String content,  String? subject,  int kind,  NoteType type,  DateTime created,  bool isSeen)?  $default,) {final _that = this;
switch (_that) {
case _DmMessageEntity() when $default != null:
return $default(_that.eventId,_that.conversationId,_that.receiverPubkey,_that.replyToEventId,_that.content,_that.subject,_that.kind,_that.type,_that.created,_that.isSeen);case _:
  return null;

}
}

}

/// @nodoc


class _DmMessageEntity implements DmMessageEntity {
  const _DmMessageEntity({required this.eventId, required this.conversationId, required this.receiverPubkey, this.replyToEventId, required this.content, this.subject, required this.kind, required this.type, required this.created, required this.isSeen});
  

@override final  String eventId;
@override final  int conversationId;
@override final  String receiverPubkey;
@override final  String? replyToEventId;
@override final  String content;
@override final  String? subject;
@override final  int kind;
@override final  NoteType type;
@override final  DateTime created;
@override final  bool isSeen;

/// Create a copy of DmMessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DmMessageEntityCopyWith<_DmMessageEntity> get copyWith => __$DmMessageEntityCopyWithImpl<_DmMessageEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DmMessageEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.receiverPubkey, receiverPubkey) || other.receiverPubkey == receiverPubkey)&&(identical(other.replyToEventId, replyToEventId) || other.replyToEventId == replyToEventId)&&(identical(other.content, content) || other.content == content)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.type, type) || other.type == type)&&(identical(other.created, created) || other.created == created)&&(identical(other.isSeen, isSeen) || other.isSeen == isSeen));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,conversationId,receiverPubkey,replyToEventId,content,subject,kind,type,created,isSeen);

@override
String toString() {
  return 'DmMessageEntity(eventId: $eventId, conversationId: $conversationId, receiverPubkey: $receiverPubkey, replyToEventId: $replyToEventId, content: $content, subject: $subject, kind: $kind, type: $type, created: $created, isSeen: $isSeen)';
}


}

/// @nodoc
abstract mixin class _$DmMessageEntityCopyWith<$Res> implements $DmMessageEntityCopyWith<$Res> {
  factory _$DmMessageEntityCopyWith(_DmMessageEntity value, $Res Function(_DmMessageEntity) _then) = __$DmMessageEntityCopyWithImpl;
@override @useResult
$Res call({
 String eventId, int conversationId, String receiverPubkey, String? replyToEventId, String content, String? subject, int kind, NoteType type, DateTime created, bool isSeen
});




}
/// @nodoc
class __$DmMessageEntityCopyWithImpl<$Res>
    implements _$DmMessageEntityCopyWith<$Res> {
  __$DmMessageEntityCopyWithImpl(this._self, this._then);

  final _DmMessageEntity _self;
  final $Res Function(_DmMessageEntity) _then;

/// Create a copy of DmMessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? conversationId = null,Object? receiverPubkey = null,Object? replyToEventId = freezed,Object? content = null,Object? subject = freezed,Object? kind = null,Object? type = null,Object? created = null,Object? isSeen = null,}) {
  return _then(_DmMessageEntity(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,receiverPubkey: null == receiverPubkey ? _self.receiverPubkey : receiverPubkey // ignore: cast_nullable_to_non_nullable
as String,replyToEventId: freezed == replyToEventId ? _self.replyToEventId : replyToEventId // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NoteType,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime,isSeen: null == isSeen ? _self.isSeen : isSeen // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
