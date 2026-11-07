// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credentials_store.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SpeakrCredentials {

 String get baseUrl; String get token;
/// Create a copy of SpeakrCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeakrCredentialsCopyWith<SpeakrCredentials> get copyWith => _$SpeakrCredentialsCopyWithImpl<SpeakrCredentials>(this as SpeakrCredentials, _$identity);

  /// Serializes this SpeakrCredentials to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeakrCredentials&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseUrl,token);



}

/// @nodoc
abstract mixin class $SpeakrCredentialsCopyWith<$Res>  {
  factory $SpeakrCredentialsCopyWith(SpeakrCredentials value, $Res Function(SpeakrCredentials) _then) = _$SpeakrCredentialsCopyWithImpl;
@useResult
$Res call({
 String baseUrl, String token
});




}
/// @nodoc
class _$SpeakrCredentialsCopyWithImpl<$Res>
    implements $SpeakrCredentialsCopyWith<$Res> {
  _$SpeakrCredentialsCopyWithImpl(this._self, this._then);

  final SpeakrCredentials _self;
  final $Res Function(SpeakrCredentials) _then;

/// Create a copy of SpeakrCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseUrl = null,Object? token = null,}) {
  return _then(_self.copyWith(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeakrCredentials].
extension SpeakrCredentialsPatterns on SpeakrCredentials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeakrCredentials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeakrCredentials() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeakrCredentials value)  $default,){
final _that = this;
switch (_that) {
case _SpeakrCredentials():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeakrCredentials value)?  $default,){
final _that = this;
switch (_that) {
case _SpeakrCredentials() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String baseUrl,  String token)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeakrCredentials() when $default != null:
return $default(_that.baseUrl,_that.token);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String baseUrl,  String token)  $default,) {final _that = this;
switch (_that) {
case _SpeakrCredentials():
return $default(_that.baseUrl,_that.token);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String baseUrl,  String token)?  $default,) {final _that = this;
switch (_that) {
case _SpeakrCredentials() when $default != null:
return $default(_that.baseUrl,_that.token);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpeakrCredentials extends SpeakrCredentials {
  const _SpeakrCredentials({required this.baseUrl, required this.token}): super._();
  factory _SpeakrCredentials.fromJson(Map<String, dynamic> json) => _$SpeakrCredentialsFromJson(json);

@override final  String baseUrl;
@override final  String token;

/// Create a copy of SpeakrCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeakrCredentialsCopyWith<_SpeakrCredentials> get copyWith => __$SpeakrCredentialsCopyWithImpl<_SpeakrCredentials>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpeakrCredentialsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeakrCredentials&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseUrl,token);



}

/// @nodoc
abstract mixin class _$SpeakrCredentialsCopyWith<$Res> implements $SpeakrCredentialsCopyWith<$Res> {
  factory _$SpeakrCredentialsCopyWith(_SpeakrCredentials value, $Res Function(_SpeakrCredentials) _then) = __$SpeakrCredentialsCopyWithImpl;
@override @useResult
$Res call({
 String baseUrl, String token
});




}
/// @nodoc
class __$SpeakrCredentialsCopyWithImpl<$Res>
    implements _$SpeakrCredentialsCopyWith<$Res> {
  __$SpeakrCredentialsCopyWithImpl(this._self, this._then);

  final _SpeakrCredentials _self;
  final $Res Function(_SpeakrCredentials) _then;

/// Create a copy of SpeakrCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseUrl = null,Object? token = null,}) {
  return _then(_SpeakrCredentials(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
