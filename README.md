# 🗺️ HunterMania

**HunterMania** is a location-based treasure hunt mobile app built with Flutter. Players explore real-world gardens and landmarks by solving clues, completing GPS-gated checkpoints, and racing the clock across beautifully designed hunt experiences.

---

## ✨ Features

- 🔐 **Firebase Auth** — Google Sign-In & email/password authentication
- 🗺️ **GPS Checkpoints** — Haversine-based geofencing to unlock real-world locations
- 🧩 **Two Checkpoint Types** — Clue answers & photo tasks
- 📊 **Hunt Progress Tracking** — Firestore-backed progress with per-checkpoint timestamps
- 💎 **Paywall & Subscriptions** — RevenueCat-powered in-app purchases
- 🔔 **Real-time Updates** — Firestore listeners for live hunt state
- 🌙 **Dark-first UI** — Glassmorphic design with Poppins & Nunito typography

---

## 🏗️ Architecture

This project follows **Clean Architecture** with a strict 3-layer separation:

```
lib/
├── app/              # Root widget, routing (go_router), theme
├── config/           # App-wide constants and environment config
├── core/
│   ├── di/           # GetIt + Injectable dependency injection
│   ├── error/        # Failure types and app exceptions
│   ├── extensions/   # BuildContext and String extensions
│   ├── network/      # Connectivity service
│   └── utils/        # GpsUtils, HMDateUtils, AppLogger
├── features/
│   ├── auth/         # Sign-in / sign-up flow
│   ├── home/         # Hunt discovery & listing
│   ├── hunt_detail/  # Hunt info & start flow
│   ├── active_hunt/  # Live checkpoint gameplay (BLoC heavy)
│   ├── hunt_complete/# Completion summary & score screen
│   ├── onboarding/   # First-launch walkthrough
│   ├── paywall/      # RevenueCat paywall
│   └── profile/      # User stats & settings
└── shared/
    ├── models/       # HuntModel, CheckpointModel, HuntProgressModel, UserModel
    ├── repositories/ # Repository interfaces
    ├── services/     # Firebase, location, analytics services
    └── widgets/      # Reusable UI components (HMButton, HMCard, etc.)
```

**State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc)  
**DI:** [get_it](https://pub.dev/packages/get_it) + [injectable](https://pub.dev/packages/injectable)  
**Navigation:** [go_router](https://pub.dev/packages/go_router)  
**Error Handling:** `Result<T>` / sealed `Failure` types  

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter (via FVM) | `^3.7.0` |
| Dart | `^3.7.0` |
| FVM | latest |
| Xcode | 15+ (for iOS) |
| Android Studio / SDK | API 21+ |

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/Harsh1052/trovo.git
cd trovo

# 2. Install Flutter version via FVM
fvm install
fvm use

# 3. Install dependencies
fvm flutter pub get

# 4. Generate DI code
fvm dart run build_runner build --delete-conflicting-outputs

# 5. Run the app
fvm flutter run
```

> **Firebase Setup:** This project requires your own `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). These are **not** committed to the repository. Follow the [Firebase Flutter setup guide](https://firebase.google.com/docs/flutter/setup) to generate them.

---

## 🧪 Running Tests

```bash
# Run all tests
fvm flutter test

# Run with coverage
fvm flutter test --coverage

# Run a specific test file
fvm flutter test test/core/utils/gps_utils_test.dart
```

### Test Coverage

| Layer | Tests |
|-------|-------|
| `core/utils/GpsUtils` | ✅ Haversine distance, radius, formatting, bearing |
| `core/utils/HMDateUtils` | ✅ Time/date formatting, elapsed seconds, timeAgo |
| `shared/models/CheckpointModel` | ✅ fromJson, toJson, copyWith, round-trip, enum |
| `shared/models/HuntModel` | ✅ fromJson, toJson, copyWith, round-trip, enum |

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `get_it` + `injectable` | Dependency injection |
| `go_router` | Declarative routing |
| `firebase_auth` | Authentication |
| `cloud_firestore` | Database & real-time data |
| `google_maps_flutter` | Map rendering |
| `geolocator` | GPS location access |
| `purchases_flutter` | RevenueCat in-app purchases |
| `lottie` | Animated illustrations |
| `logger` | Structured debug logging |

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development guidelines, branching strategy, and code style rules.

---

## 📄 License

This project is private and proprietary. All rights reserved.
