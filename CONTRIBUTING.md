# Contributing to HunterMania

Thanks for contributing! Please read this guide before opening a PR.

---

## 🌿 Branching Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code only |
| `dev` | Integration branch for features |
| `feat/<name>` | New feature branches |
| `fix/<name>` | Bug fix branches |
| `chore/<name>` | Config, deps, tooling changes |

All PRs must target `dev`, never `main` directly.

---

## 🏗️ Architecture Rules

This project follows **Clean Architecture**. Violations will block merges.

### Layer Boundaries (STRICT)

```
Presentation (BLoC/Widgets)
    ↓ depends on
Domain (Use Cases / Repository Interfaces)
    ↓ depends on
Data (Repository Impl / Data Sources / Models)
```

- ❌ **Never** import a `data` class directly into a `bloc` or widget.
- ❌ **Never** put business logic inside a widget's `build()` method.
- ✅ Widgets dispatch events → BLoC handles logic → emits states.

### Dependency Injection

- Register all dependencies in the DI graph via `@injectable` / `@singleton`.
- **Never** call `GetIt.instance.get<X>()` inside a widget — inject via constructor or `context.read<>()`.

---

## 💅 Code Style

### Naming

| Concept | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.dart` | `hunt_detail_page.dart` |
| Classes | `PascalCase` | `HuntDetailPage` |
| Variables | `camelCase` | `currentCheckpoint` |
| Constants | `camelCase` (no `SCREAMING_SNAKE`) | `unlockRadius` |
| BLoC Events | Past tense | `HuntStarted`, `CheckpointUnlocked` |
| BLoC States | Descriptive noun | `HuntLoaded`, `HuntError` |

### Imports

- Use **absolute imports** for cross-feature or cross-layer references:  
  `package:huntermania/shared/models/hunt_model.dart`
- Use **relative imports** only within the same feature folder.
- **Never** leave unused imports — run `fvm dart fix --apply` before committing.

### Theming

- **Never** hardcode colours, font sizes, or spacing.
- Always use `Theme.of(context)` or the project's theme extensions.
- If you need a new colour or style, add it to the design tokens first.

---

## 🧪 Testing Requirements

Every PR that touches business logic **must** include tests.

```bash
# Run all tests before pushing
fvm flutter test

# Generate coverage report
fvm flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### What to test

| Layer | What |
|-------|------|
| `core/utils` | Pure functions — full branch coverage expected |
| `shared/models` | `fromJson`, `toJson`, round-trip, `copyWith`, defaults |
| `features/*/bloc` | All events → state transitions using `bloc_test` |
| Repositories | Mock Firestore and assert method calls |

---

## 📝 Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(active_hunt): add hint reveal animation
fix(auth): handle Google Sign-In cancellation gracefully
test(gps_utils): add bearing edge case coverage
chore(deps): bump firebase_core to 3.14.0
docs(readme): update setup instructions for FVM
```

Scope is the feature name or layer (e.g. `auth`, `home`, `gps_utils`, `di`).

---

## 🔍 PR Checklist

Before requesting review, ensure:

- [ ] Code compiles: `fvm flutter build apk --debug`
- [ ] All tests pass: `fvm flutter test`
- [ ] No analysis warnings: `fvm flutter analyze`
- [ ] No unused imports: `fvm dart fix --apply`
- [ ] New logic has unit tests
- [ ] No hardcoded colours or font sizes
- [ ] Commit messages follow Conventional Commits
- [ ] PR description explains *what* and *why*

---

## ⚙️ Local Dev Setup

```bash
# Install FVM globally
dart pub global activate fvm

# Install the project's Flutter version
fvm install && fvm use

# Install dependencies
fvm flutter pub get

# Re-generate DI & other generated code
fvm dart run build_runner build --delete-conflicting-outputs

# Run on a connected device
fvm flutter run

# Analyze before pushing
fvm flutter analyze
fvm flutter test
```

---

## 🚫 Things That Will Get Your PR Rejected

1. Business logic inside a `Widget.build()`.
2. Hardcoded colours, strings, or magic numbers.
3. Running `flutter` or `dart` directly (must use `fvm flutter` / `fvm dart`).
4. Importing domain/data layers across architecture boundaries.
5. Merging without tests for new logic.
6. Force-pushing to `main` or `dev`.
