// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_key_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserKeyModelCollection on Isar {
  IsarCollection<UserKeyModel> get userKeyModels => this.collection();
}

const UserKeyModelSchema = CollectionSchema(
  name: r'UserKey',
  id: 5009162838006069678,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'npub': PropertySchema(id: 1, name: r'npub', type: IsarType.string),
    r'nsec': PropertySchema(id: 2, name: r'nsec', type: IsarType.string),
  },

  estimateSize: _userKeyModelEstimateSize,
  serialize: _userKeyModelSerialize,
  deserialize: _userKeyModelDeserialize,
  deserializeProp: _userKeyModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _userKeyModelGetId,
  getLinks: _userKeyModelGetLinks,
  attach: _userKeyModelAttach,
  version: '3.3.2',
);

int _userKeyModelEstimateSize(
  UserKeyModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.npub.length * 3;
  bytesCount += 3 + object.nsec.length * 3;
  return bytesCount;
}

void _userKeyModelSerialize(
  UserKeyModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.npub);
  writer.writeString(offsets[2], object.nsec);
}

UserKeyModel _userKeyModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserKeyModel();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.npub = reader.readString(offsets[1]);
  object.nsec = reader.readString(offsets[2]);
  return object;
}

P _userKeyModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userKeyModelGetId(UserKeyModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userKeyModelGetLinks(UserKeyModel object) {
  return [];
}

void _userKeyModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  UserKeyModel object,
) {
  object.id = id;
}

extension UserKeyModelQueryWhereSort
    on QueryBuilder<UserKeyModel, UserKeyModel, QWhere> {
  QueryBuilder<UserKeyModel, UserKeyModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserKeyModelQueryWhere
    on QueryBuilder<UserKeyModel, UserKeyModel, QWhereClause> {
  QueryBuilder<UserKeyModel, UserKeyModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension UserKeyModelQueryFilter
    on QueryBuilder<UserKeyModel, UserKeyModel, QFilterCondition> {
  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> npubEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'npub',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  npubGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'npub',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> npubLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'npub',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> npubBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'npub',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  npubStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'npub',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> npubEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'npub',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> npubContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'npub',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> npubMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'npub',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  npubIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'npub', value: ''),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  npubIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'npub', value: ''),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> nsecEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nsec',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  nsecGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nsec',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> nsecLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nsec',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> nsecBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nsec',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  nsecStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nsec',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> nsecEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nsec',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> nsecContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nsec',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition> nsecMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nsec',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  nsecIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nsec', value: ''),
      );
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterFilterCondition>
  nsecIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nsec', value: ''),
      );
    });
  }
}

extension UserKeyModelQueryObject
    on QueryBuilder<UserKeyModel, UserKeyModel, QFilterCondition> {}

extension UserKeyModelQueryLinks
    on QueryBuilder<UserKeyModel, UserKeyModel, QFilterCondition> {}

extension UserKeyModelQuerySortBy
    on QueryBuilder<UserKeyModel, UserKeyModel, QSortBy> {
  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> sortByNpub() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'npub', Sort.asc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> sortByNpubDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'npub', Sort.desc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> sortByNsec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nsec', Sort.asc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> sortByNsecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nsec', Sort.desc);
    });
  }
}

extension UserKeyModelQuerySortThenBy
    on QueryBuilder<UserKeyModel, UserKeyModel, QSortThenBy> {
  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> thenByNpub() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'npub', Sort.asc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> thenByNpubDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'npub', Sort.desc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> thenByNsec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nsec', Sort.asc);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QAfterSortBy> thenByNsecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nsec', Sort.desc);
    });
  }
}

extension UserKeyModelQueryWhereDistinct
    on QueryBuilder<UserKeyModel, UserKeyModel, QDistinct> {
  QueryBuilder<UserKeyModel, UserKeyModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QDistinct> distinctByNpub({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'npub', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserKeyModel, UserKeyModel, QDistinct> distinctByNsec({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nsec', caseSensitive: caseSensitive);
    });
  }
}

extension UserKeyModelQueryProperty
    on QueryBuilder<UserKeyModel, UserKeyModel, QQueryProperty> {
  QueryBuilder<UserKeyModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserKeyModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<UserKeyModel, String, QQueryOperations> npubProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'npub');
    });
  }

  QueryBuilder<UserKeyModel, String, QQueryOperations> nsecProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nsec');
    });
  }
}
