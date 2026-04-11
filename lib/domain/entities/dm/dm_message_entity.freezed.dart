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

 String get eventId; int get conversationId; String get content; String? get subject; String? get replyToEventId; DateTime get createdAt; bool get isSentByMe;
/// Create a copy of DmMessageEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DmMessageEntityCopyWith<DmMessageEntity> get copyWith => _$DmMessageEntityCopyWithImpl<DmMessageEntity>(this as DmMessageEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DmMessageEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.content, content) || other.content == content)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.replyToEventId, replyToEventId) || other.replyToEventId == replyToEventId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isSentByMe, isSentByMe) || other.isSentByMe == isSentByMe));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,conversationId,content,subject,replyToEventId,createdAt,isSentByMe);

@override
String toString() {
  return 'DmMessageEntity(eventId: $eventId, conversationId: $conversationId, content: $content, subject: $subject, replyToEventId: $replyToEventId, createdAt: $createdAt, isSentByMe: $isSentByMe)';
}


}

/// @nodoc
abstract mixin class $DmMessageEntityCopyWith<$Res>  {
  factory $DmMessageEntityCopyWith(DmMessageEntity value, $Res Function(DmMessageEntity) _then) = _$DmMessageEntityCopyWithImpl;
@useResult
$Res call({
 String eventId, int conversationId, String content, String? subject, String? replyToEventId, DateTime createdAt, bool isSentByMe
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
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? conversationId = null,Object? content = null,Object? subject = freezed,Object? replyToEventId = freezed,Object? createdAt = null,Object? isSentByMe = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,replyToEventId: freezed == replyToEventId ? _self.replyToEventId : replyToEventId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSentByMe: null == isSentByMe ? _self.isSentByMe : isSentByMe // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  int conversationId,  String content,  String? subject,  String? replyToEventId,  DateTime createdAt,  bool isSentByMe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DmMessageEntity() when $default != null:
return $default(_that.eventId,_that.conversationId,_that.content,_that.subject,_that.replyToEventId,_that.createdAt,_that.isSentByMe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  int conversationId,  String content,  String? subject,  String? replyToEventId,  DateTime createdAt,  bool isSentByMe)  $default,) {final _that = this;
switch (_that) {
case _DmMessageEntity():
return $default(_that.eventId,_that.conversationId,_that.content,_that.subject,_that.replyToEventId,_that.createdAt,_that.isSentByMe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  int conversationId,  String content,  String? subject,  String? replyToEventId,  DateTime createdAt,  bool isSentByMe)?  $default,) {final _that = this;
switch (_that) {
case _DmMessageEntity() when $default != null:
return $default(_that.eventId,_that.conversationId,_that.content,_that.subject,_that.replyToEventId,_that.createdAt,_that.isSentByMe);case _:
  return null;

}
}

}

/// @nodoc


class _DmMessageEntity implements DmMessageEntity {
  const _DmMessageEntity({required this.eventId, required this.conversationId, required this.content, this.subject, this.replyToEventId, required this.createdAt, required this.isSentByMe});
  

@override final  String eventId;
@override final  int conversationId;
@override final  String content;
@override final  String? subject;
@override final  String? replyToEventId;
@override final  DateTime createdAt;
@override final  bool isSentByMe;

/// Create a copy of DmMessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DmMessageEntityCopyWith<_DmMessageEntity> get copyWith => __$DmMessageEntityCopyWithImpl<_DmMessageEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DmMessageEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.content, content) || other.content == content)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.replyToEventId, replyToEventId) || other.replyToEventId == replyToEventId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isSentByMe, isSentByMe) || other.isSentByMe == isSentByMe));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,conversationId,content,subject,replyToEventId,createdAt,isSentByMe);

@override
String toString() {
  return 'DmMessageEntity(eventId: $eventId, conversationId: $conversationId, content: $content, subject: $subject, replyToEventId: $replyToEventId, createdAt: $createdAt, isSentByMe: $isSentByMe)';
}


}

/// @nodoc
abstract mixin class _$DmMessageEntityCopyWith<$Res> implements $DmMessageEntityCopyWith<$Res> {
  factory _$DmMessageEntityCopyWith(_DmMessageEntity value, $Res Function(_DmMessageEntity) _then) = __$DmMessageEntityCopyWithImpl;
@override @useResult
$Res call({
 String eventId, int conversationId, String content, String? subject, String? replyToEventId, DateTime createdAt, bool isSentByMe
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
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? conversationId = null,Object? content = null,Object? subject = freezed,Object? replyToEventId = freezed,Object? createdAt = null,Object? isSentByMe = null,}) {
  return _then(_DmMessageEntity(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,replyToEventId: freezed == replyToEventId ? _self.replyToEventId : replyToEventId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSentByMe: null == isSentByMe ? _self.isSentByMe : isSentByMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
