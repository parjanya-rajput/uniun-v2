// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_note_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedNoteEntity {

 String get eventId; DateTime get savedAt; String get contentPreview;
/// Create a copy of SavedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedNoteEntityCopyWith<SavedNoteEntity> get copyWith => _$SavedNoteEntityCopyWithImpl<SavedNoteEntity>(this as SavedNoteEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedNoteEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.contentPreview, contentPreview) || other.contentPreview == contentPreview));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,savedAt,contentPreview);

@override
String toString() {
  return 'SavedNoteEntity(eventId: $eventId, savedAt: $savedAt, contentPreview: $contentPreview)';
}


}

/// @nodoc
abstract mixin class $SavedNoteEntityCopyWith<$Res>  {
  factory $SavedNoteEntityCopyWith(SavedNoteEntity value, $Res Function(SavedNoteEntity) _then) = _$SavedNoteEntityCopyWithImpl;
@useResult
$Res call({
 String eventId, DateTime savedAt, String contentPreview
});




}
/// @nodoc
class _$SavedNoteEntityCopyWithImpl<$Res>
    implements $SavedNoteEntityCopyWith<$Res> {
  _$SavedNoteEntityCopyWithImpl(this._self, this._then);

  final SavedNoteEntity _self;
  final $Res Function(SavedNoteEntity) _then;

/// Create a copy of SavedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? savedAt = null,Object? contentPreview = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,contentPreview: null == contentPreview ? _self.contentPreview : contentPreview // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedNoteEntity].
extension SavedNoteEntityPatterns on SavedNoteEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedNoteEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedNoteEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedNoteEntity value)  $default,){
final _that = this;
switch (_that) {
case _SavedNoteEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedNoteEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SavedNoteEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  DateTime savedAt,  String contentPreview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedNoteEntity() when $default != null:
return $default(_that.eventId,_that.savedAt,_that.contentPreview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  DateTime savedAt,  String contentPreview)  $default,) {final _that = this;
switch (_that) {
case _SavedNoteEntity():
return $default(_that.eventId,_that.savedAt,_that.contentPreview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  DateTime savedAt,  String contentPreview)?  $default,) {final _that = this;
switch (_that) {
case _SavedNoteEntity() when $default != null:
return $default(_that.eventId,_that.savedAt,_that.contentPreview);case _:
  return null;

}
}

}

/// @nodoc


class _SavedNoteEntity implements SavedNoteEntity {
  const _SavedNoteEntity({required this.eventId, required this.savedAt, required this.contentPreview});
  

@override final  String eventId;
@override final  DateTime savedAt;
@override final  String contentPreview;

/// Create a copy of SavedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedNoteEntityCopyWith<_SavedNoteEntity> get copyWith => __$SavedNoteEntityCopyWithImpl<_SavedNoteEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedNoteEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.contentPreview, contentPreview) || other.contentPreview == contentPreview));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,savedAt,contentPreview);

@override
String toString() {
  return 'SavedNoteEntity(eventId: $eventId, savedAt: $savedAt, contentPreview: $contentPreview)';
}


}

/// @nodoc
abstract mixin class _$SavedNoteEntityCopyWith<$Res> implements $SavedNoteEntityCopyWith<$Res> {
  factory _$SavedNoteEntityCopyWith(_SavedNoteEntity value, $Res Function(_SavedNoteEntity) _then) = __$SavedNoteEntityCopyWithImpl;
@override @useResult
$Res call({
 String eventId, DateTime savedAt, String contentPreview
});




}
/// @nodoc
class __$SavedNoteEntityCopyWithImpl<$Res>
    implements _$SavedNoteEntityCopyWith<$Res> {
  __$SavedNoteEntityCopyWithImpl(this._self, this._then);

  final _SavedNoteEntity _self;
  final $Res Function(_SavedNoteEntity) _then;

/// Create a copy of SavedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? savedAt = null,Object? contentPreview = null,}) {
  return _then(_SavedNoteEntity(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,contentPreview: null == contentPreview ? _self.contentPreview : contentPreview // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
