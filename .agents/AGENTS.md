# HunterMania Architectural Rules & Co-Founder Best Practices

## Micro-Rules (Auto-generated)

- MR-01: Clarity before coding
  - If inputs are missing, ask 3–7 questions and STOP.
  - Do not create files until requirements are confirmed.

- MR-02: Firebase Config & Key Synchronization
  - Always ensure `android/app/google-services.json` contains valid production/development API Keys matching `lib/firebase_options.dart`.
  - Always guard `Firebase.initializeApp` with `if (Firebase.apps.isEmpty)` to prevent Android `[core/duplicate-app]` white screen startup crashes.

- MR-03: Java Desugaring for Android Builds
  - Ensure `isCoreLibraryDesugaringEnabled = true` and `desugar_jdk_libs` dependency are included in `android/app/build.gradle.kts` whenever local notification or date-time packages are added.
