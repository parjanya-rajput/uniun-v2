# Uniun Codebase Complete Guide
## An Easy-to-Understand Explanation of BLoC Architecture & Layered Design

---

## Part 1: What is Uniun?

**Uniun** is a **community-based social platform app** (like Reddit) where:
- Users can join/create communities
- Users can post, comment, and interact with content
- Users can search for communities, posts, and people
- Posts and comments can be voted on, saved, and discussed

Think of it like **Reddit** - communities with posts, comments, and voting.

---

## Part 2: Why This Code Structure? (The "Layered" Concept)

### The Problem Without Layers:
If you write all code mixed together, it becomes messy:
```
UI directly talks to Database
UI directly has business rules
Database changes break UI
Hard to test, hard to maintain
```

### The Solution: "Layered Architecture"
Separate concerns into **3 independent layers**:

```
┌─────────────────────────────────────────┐
│  PRESENTATION LAYER (What users see)    │
│  Pages, UI Components, State Management │
│  (BLoC, Cubit)                          │
└────────────────┬────────────────────────┘
                 │ (Only communicates via)
                 ↓
┌─────────────────────────────────────────┐
│  DOMAIN LAYER (Business rules)          │
│  Entities, Use Cases, Abstract Repos    │
│  (The "What should happen" logic)       │
└────────────────┬────────────────────────┘
                 │ (Only communicates via)
                 ↓
┌─────────────────────────────────────────┐
│  DATA LAYER (Getting/Saving data)       │
│  API calls, Database, Models            │
│  (The "How to get data" logic)          │
└─────────────────────────────────────────┘
```

**Benefits:**
- Each layer can be changed independently
- Easy to test each layer separately
- Easy to switch from API to another data source
- Business logic doesn't depend on UI changes

---

## Part 3: Detailed Explanation of 3 Layers

### LAYER 1: DATA LAYER (`lib/data/`)
**Job:** Get data from API or database, save it locally

**How it works:**
```
RemoteDataSource (API calls)
       ↓
Models (Convert JSON to Dart objects)
       ↓
RepositoryImpl (Uses RemoteDataSource)
       ↓
Local Cache (Save data locally)
```

**Simple Example:**
```
User wants to search communities
    ↓
RemoteDataSource calls: GET /api/search?q=python
    ↓
API returns: {"id": 1, "name": "Python", ...}
    ↓
CommunityModel converts JSON to Dart object
    ↓
CommunityRepositoryImpl receives it
    ↓
Save to local database ([Isar](docs/ISAR_DB.md))
    ↓
Return to Domain Layer
```

**Key Files:**
- `lib/data/datasources/remote_datasource.dart` - Makes API calls
- `lib/data/datasources/local_datasource.dart` - Handles offline data
- `lib/data/models/` - Convert API responses to Dart objects
- `lib/data/repositories/` - Combine remote + local data

---

### LAYER 2: DOMAIN LAYER (`lib/domain/`)
**Job:** Define business rules (WHAT should happen)

**How it works:**
```
UseCase (Business operations)
    ↓
Entity (Clean domain object)
    ↓
Repository (Abstract interface)
    ↓
(Doesn't know HOW data is fetched)
```

**Simple Example:**
```
User wants to "join a community"

UseCase (CommunityUseCase) says:
  - "To join a community, call the repository"
  - "Tell me if it succeeded or failed"

Entity (CommunityEntity) defines:
  - What a community is: id, name, description, members...

RepositoryInterface says:
  - "I will join a community, but I won't tell you HOW"
  - (The Data Layer will implement this)
```

**Key Files:**
- `lib/domain/entities/` - Clean data objects (NOT from API)
- `lib/domain/usecases/` - Business logic operations
- `lib/domain/repositories/` - Abstract interfaces (what Data Layer must implement)
- `lib/domain/inputs/` - Parameters for use cases

---

### LAYER 3: PRESENTATION LAYER (Feature modules)
**Job:** Show data to users, handle user interactions, manage UI state

**How it works:**
```
User taps screen
    ↓
BLoC receives Event
    ↓
BLoC calls UseCase
    ↓
UseCase calls Repository
    ↓
Data Layer returns result
    ↓
BLoC creates new State
    ↓
UI rebuilds with new State
```

**Key Files:**
- `lib/search/` - Search feature
- `lib/community/` - Community feature
- `lib/posts/` - Posts feature
- `lib/user/` - Login/signup feature

---

## Part 4: Understanding BLoC (State Management)

### What is BLoC?

**BLoC = Business Logic Component**

It's the middleman between UI and Data:
```
User Action (tap button) → BLoC → Data Layer → BLoC → UI Update
```

### BLoC has 3 Main Parts:

#### 1. **EVENTS** (What user does)
```dart
// lib/search/bloc/search_event.dart

class StartSearchEvent extends SearchEvent {
  final String query;
  // User typed text and hit search
}

class VoteCommentEvent extends SearchEvent {
  final int commentId;
  final bool upvote;
  // User voted on a comment
}
```

#### 2. **BLOC** (Does the work)
```dart
// lib/search/bloc/search_bloc.dart

class SearchBloc extends Bloc<SearchEvent, SearchState> {

  SearchBloc() : super(initialState) {
    // When StartSearchEvent happens, run _startSearch method
    on<StartSearchEvent>(_startSearchEvent);
    on<VoteCommentEvent>(_voteCommentEvent);
  }

  // Handle the event and change state
  _startSearchEvent(StartSearchEvent event, Emitter emit) async {
    emit(SearchState(status: loading));

    final result = await searchUseCase.searchEverything(event.query);

    result.fold(
      (failure) => emit(SearchState(status: failure)),
      (data) => emit(SearchState(status: success, results: data))
    );
  }
}
```

#### 3. **STATES** (What changed)
```dart
// lib/search/bloc/search_state.dart

class SearchState {
  final SearchStatus status; // initial, loading, success, failure, empty
  final List<Community> communities;
  final List<Post> posts;
  final List<Comment> comments;

  // When BLoC emits new state, UI rebuilds
}
```

### BLoC Flow (Visual Example):

```
┌─────────────────────────────────────────────────┐
│ USER INTERFACE (SearchPage)                     │
│  User types "python" and hits search button     │
└────────────────┬────────────────────────────────┘
                 │
                 ↓ (Sends Event)
┌─────────────────────────────────────────────────┐
│ BLOC (SearchBloc)                               │
│  1. Receives: StartSearchEvent("python")        │
│  2. Calls: searchUseCase.search("python")       │
│  3. Gets result from Repository                 │
│  4. Creates new State: SearchState(             │
│        status: success,                         │
│        communities: [...],                      │
│        posts: [...]                             │
│     )                                           │
└────────────────┬────────────────────────────────┘
                 │
                 ↓ (Emits State)
┌─────────────────────────────────────────────────┐
│ UI REBUILDS (SearchPage)                        │
│  Shows search results using new State           │
└─────────────────────────────────────────────────┘
```

---

## Part 5: Complete Example - Search Module

Let's trace what happens when user searches for "python":

### Step 1: User Types "python" and Hits Search

```dart
// lib/search/pages/search_page.dart
GestureDetector(
  onTap: () {
    context.read<SearchBloc>().add(
      StartSearchEvent(
        query: "python",
        searchType: SearchType.all // Search everywhere
      )
    );
  },
  child: Text("Search")
)
```

### Step 2: SearchBloc Receives Event

```dart
// lib/search/bloc/search_bloc.dart
on<StartSearchEvent>(_searchEvent);

_searchEvent(StartSearchEvent event, Emitter emit) async {
  // Emit loading state - UI shows spinner
  emit(state.copyWith(status: SearchStatus.loading));

  // Tell Repository to search
  final result = await _searchUseCase.search(event.query);

  result.fold(
    // If failed
    (failure) {
      emit(state.copyWith(
        status: SearchStatus.failure,
        message: failure.message
      ));
    },
    // If success
    (searchResults) {
      emit(state.copyWith(
        status: SearchStatus.success,
        communities: searchResults.communities,
        posts: searchResults.posts,
        comments: searchResults.comments,
        users: searchResults.users
      ));
    }
  );
}
```

### Step 3: SearchUseCase Calls Repository

```dart
// lib/domain/usecases/search_usecase.dart
class SearchUseCase {
  final SearchRepository repository;

  Future<Either<Failure, SearchResults>> search(String query) async {
    // UseCase doesn't know HOW to search
    // It just calls Repository and returns result
    return await repository.search(query);
  }
}
```

### Step 4: Repository Gets Data from API

```dart
// lib/data/repositories/search_repository_impl.dart
class SearchRepositoryImpl implements SearchRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;

  Future<Either<Failure, SearchResults>> search(String query) async {
    try {
      // Call API
      final response = await remoteDataSource.search(query);

      // Save to local database for offline access
      await localDataSource.cacheSearchResults(response);

      // Convert API response to domain objects
      return Right(response.toDomain());

    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

### Step 5: RemoteDataSource Makes API Call

```dart
// lib/data/datasources/remote_datasource.dart
class RemoteDataSourceImpl implements RemoteDataSource {
  final ApiConsumer apiConsumer;

  Future<SearchResultsModel> search(String query) async {
    final response = await apiConsumer.get(
      '/api/search?q=$query&type=all'
    );

    // API returns JSON, convert to Model
    return SearchResultsModel.fromJson(response);
  }
}
```

### Step 6: API Returns Data

```json
{
  "communities": [
    {
      "id": 1,
      "name": "Python",
      "description": "Programming in Python"
    }
  ],
  "posts": [...],
  "comments": [...]
}
```

### Step 7: SearchResultsModel Converts JSON to Dart

```dart
// lib/data/models/search_results_model.dart
class SearchResultsModel {
  final List<CommunityModel> communities;
  final List<PostModel> posts;
  final List<CommentModel> comments;

  factory SearchResultsModel.fromJson(Map<String, dynamic> json) {
    return SearchResultsModel(
      communities: List.from(json['communities']),
      posts: List.from(json['posts']),
      comments: List.from(json['comments']),
    );
  }

  // Convert Model to Entity (domain object)
  SearchResultsEntity toDomain() {
    return SearchResultsEntity(
      communities: communities.map((c) => c.toDomain()).toList(),
      posts: posts.map((p) => p.toDomain()).toList(),
      comments: comments.map((c) => c.toDomain()).toList(),
    );
  }
}
```

### Step 8: BLoC Receives Entity and Creates State

Entity comes back to SearchBloc:
```dart
SearchState(
  status: SearchStatus.success,
  communities: [CommunityEntity(id: 1, name: "Python", ...)],
  posts: [...],
  comments: [...]
)
```

### Step 9: UI Rebuilds with New State

```dart
// lib/search/pages/search_page.dart
BlocBuilder<SearchBloc, SearchState>(
  builder: (context, state) {
    if (state.status == SearchStatus.loading) {
      return CircularProgressIndicator();
    }

    if (state.status == SearchStatus.success) {
      return Column(
        children: [
          // Show communities
          ...state.communities.map((c) =>
            CommunityCard(community: c)
          ),
          // Show posts
          ...state.posts.map((p) =>
            PostCard(post: p)
          ),
        ]
      );
    }

    return Text("Failed to load");
  }
)
```

### User Sees Results! ✅

---

## Part 6: Folder Structure Explained

```
lib/
├── main.dart                    # App entry point
│
├── common/                      # Shared across app
│   ├── constants.dart          # App-wide constants
│   ├── locator.dart            # Dependency injection setup
│   ├── widgets/                # Reusable UI components
│   └── snackbar.dart           # Notifications
│
├── core/                        # Global infrastructure
│   ├── api/                    # HTTP client (Dio)
│   ├── theme/                  # Theme management
│   ├── bloc/                   # Global states (auth, theme, etc)
│   ├── error/                  # Error/Failure classes
│   └── extensions/             # Helper methods for Dart types
│
├── data/                        # Data Layer
│   ├── datasources/            # API calls & local database
│   ├── models/                 # Convert JSON to Dart
│   └── repositories/           # Combine data sources
│
├── domain/                      # Domain Layer
│   ├── entities/               # Clean domain objects
│   ├── repositories/           # Abstract interfaces
│   ├── usecases/              # Business logic operations
│   └── inputs/                # UseCase parameters
│
├── search/                      # Search Feature
│   ├── bloc/                   # SearchBloc, SearchEvent, SearchState
│   ├── pages/                  # Search UI pages
│   ├── widgets/                # Search components
│   └── utils/                  # Search utilities
│
├── community/                   # Community Feature
│   ├── bloc/                   # CommunityCubit, FeedCubit
│   ├── pages/                  # Community UI pages
│   ├── widgets/                # Community components
│   └── utils/                  # Community utilities
│
├── posts/                       # Posts Feature
│   ├── bloc/                   # PostBloc, PostEvent, PostState
│   ├── pages/                  # Post UI pages
│   ├── widgets/                # Post components
│   └── utils/                  # Post utilities
│
├── user/                        # User Feature (Login/Signup)
│   ├── bloc/                   # LoginCubit, SignupCubit
│   ├── pages/                  # Login/signup pages
│   └── widgets/                # Form components
│
└── l10n/                        # Multi-language support
```

---

## Part 7: Key Concepts Simplified

### 1. **Freezed** (Immutable Data)
```dart
// Most classes use @freezed to prevent accidental changes
@freezed
class CommunityEntity with _$CommunityEntity {
  const factory CommunityEntity({
    required int id,
    required String name,
    required String description,
  }) = _CommunityEntity;
}

// Cannot do: entity.name = "new name" ❌
// Must do: entity.copyWith(name: "new name") ✅
```

### 2. **Either** (Success OR Failure)
```dart
// Instead of: return (success, error)
// Use Either<Failure, Success>

Either<Failure, CommunityEntity> result = await repository.getCommunity(id);

result.fold(
  (failure) => print("Error: ${failure.message}"),
  (community) => print("Got: ${community.name}")
);
```

### 3. **UseCase** (Business Operation)
```dart
// Single responsibility: One use case = one business operation

@injectable
class SearchCommunityUseCase {
  final SearchRepository repository;

  // Input must be wrapped in a class
  Future<Either<Failure, List<Community>>> call(
    SearchInput input  // input.query, input.sortType
  ) async {
    return await repository.search(input.query);
  }
}

// Usage:
final result = await useCase.call(SearchInput(query: "python"));
```

### 4. **Injectable/Service Locator** (Dependency Injection)
```dart
// Instead of: SearchBloc(SearchUseCase(Repository(...)))
// Dependencies are auto-injected

@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchUseCase searchUseCase;

  // Constructor auto-receives dependency
  SearchBloc(this.searchUseCase) : super(initialState);
}

// Usage:
final bloc = getIt<SearchBloc>(); // Auto-injected!
```

---

## Part 8: How Everything Works Together (Big Picture)

```
USER TAPS SEARCH BUTTON
           ↓
    SearchPage (UI)
           ↓
  context.read<SearchBloc>()
           ↓
   StartSearchEvent("python")
           ↓
      SearchBloc
           ↓
   SearchUseCase.search()
           ↓
   SearchRepository (abstract)
           ↓
   SearchRepositoryImpl
           ↓
   RemoteDataSource.search()
           ↓
    API: GET /search?q=python
           ↓
   JSON Response: {...}
           ↓
   SearchResultsModel.fromJson()
           ↓
   .toDomain() → Entity
           ↓
   BLoC emits SearchState(success: [...])
           ↓
   UI rebuilds with BlocBuilder
           ↓
USER SEES RESULTS ✅
```

---

## Part 9: Easy Analogy

Think of the app like a **Restaurant**:

- **PRESENTATION LAYER** = Customer at table
  - Customer (User) orders food (clicks button)
  - Sees the menu (UI)

- **BLoC** = Waiter
  - Takes order (Event)
  - Brings food (State)
  - Communicates between customer and kitchen

- **DOMAIN LAYER** = Chef Manager
  - Describes what a "pizza" is (Entity)
  - Decides business rules: "To serve a pizza, get it from kitchen" (UseCase)

- **DATA LAYER** = Kitchen
  - Makes the pizza (RemoteDataSource)
  - Stores extra pizzas (LocalDataSource)
  - Packages pizza nicely (Model)

---

## Part 10: Testing (Why Clean Architecture Helps)

Each layer can be tested separately:

```dart
// Test UseCase (doesn't need UI or API)
test('SearchUseCase returns communities', () async {
  final mockRepository = MockSearchRepository();
  final useCase = SearchUseCase(mockRepository);

  final result = await useCase.search("python");

  expect(result, Right([...]));
});

// Test BLoC (doesn't need real API)
blocTest<SearchBloc, SearchState>(
  'emits [loading, success] when search succeeds',
  build: () => SearchBloc(mockUseCase),
  act: (bloc) => bloc.add(StartSearchEvent(query: 'python')),
  expect: () => [
    SearchState(status: SearchStatus.loading),
    SearchState(status: SearchStatus.success, communities: [...])
  ],
);
```

---

## Summary: Key Takeaways

1. **Layered Architecture** = Separate concerns for maintainability
2. **Data Layer** = Get/save data (API, database)
3. **Domain Layer** = Define business rules
4. **Presentation Layer** = Show UI, manage state with BLoC
5. **BLoC** = Middleman between UI and data
6. **Event** = What user does
7. **State** = What changed
8. **Entity** = Clean domain object
9. **UseCase** = Business operation
10. **Repository** = Abstract interface between Domain and Data

This structure makes the code:
- ✅ Easy to test
- ✅ Easy to maintain
- ✅ Easy to change
- ✅ Easy to understand
