# STARDY AI - Release Build and Hygiene Guide

This guide details instructions and requirements for building and releasing the STARDY AI mobile application for production.

---

## 1. Zero Secrets Statement

**No secrets are compiled into the client application binary.**
- No API keys, database credentials, server private keys, or admin tokens exist in the source code or asset bundles.
- All network interactions authenticate via short-lived Firebase ID tokens fetched at runtime from the Firebase Auth client SDK (`getIdToken`).
- Server authorization is strictly enforced on the backend via verifyIdToken; the client possesses no privileged secrets.
- All build-time configuration is provided through non-secret `--dart-define` compiler flags.

---

## 2. Required `--dart-define` Variables

Every production release build requires the following `--dart-define` flags:

| Flag | Required | Example / Allowed Values | Description |
| :--- | :--- | :--- | :--- |
| `APP_ENV` | **Yes** | `prod` (or `staging`) | Environment selector. In `prod`, HTTPS is enforced. |
| `API_BASE_URL` | **Yes** | `https://api.stardy.ai/api/v1` | Backend API base URL. Must start with `https://` and end with `/api/v1`. |
| `SENTRY_DSN` | No (Recommended) | `https://[key]@[org].ingest.sentry.io/[project]` | Sentry error sink DSN. When omitted or empty, Sentry is completely disabled. The Sentry DSN is a write-only public identifier compiled into the app (not a secret); the real protection is client-side `beforeSend` redaction plus Sentry project settings (rate limits, origin restrictions, and PII scrubbing). |

---

## 3. Release Build Commands and Flags

Production binaries must be built using code obfuscation and debug symbol splitting to protect intellectual property and minimize attack surface.

### Android Release Bundle (AAB)

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.stardy.ai/api/v1 \
  --dart-define=SENTRY_DSN=https://[key]@[org].ingest.sentry.io/[project]
```

### Android Release APK

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.stardy.ai/api/v1 \
  --dart-define=SENTRY_DSN=https://[key]@[org].ingest.sentry.io/[project]
```

### iOS Release Archive (IPA)

```bash
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/ios/outputs/symbols \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.stardy.ai/api/v1 \
  --dart-define=SENTRY_DSN=https://[key]@[org].ingest.sentry.io/[project]
```

> **Note on Symbol Files**: The directory specified by `--split-debug-info` (e.g., `build/app/outputs/symbols`) generates debug symbol maps (`app.android-arm64.symbols`). Store these securely in CI/CD artifacts or upload them to Sentry to enable stack trace symbolication. Never commit symbol maps or `.map.json` files to Git.

---

## 4. Platform Security Hygiene Checklist

- [x] **Cleartext Traffic Disabled**: `android:usesCleartextTraffic="false"` is explicitly set in `android/app/src/main/AndroidManifest.xml`.
- [x] **Backup Disabled**: `android:allowBackup="false"` is explicitly set in `android/app/src/main/AndroidManifest.xml`.
- [x] **No Debuggable Flag in Main Manifest**: Release builds compile with `android:debuggable="false"` automatically inserted by Gradle; no debuggable flag is present in `android/app/src/main/AndroidManifest.xml`.
- [x] **No Arbitrary Loads on iOS**: `NSAllowsArbitraryLoads` is absent from `ios/Runner/Info.plist`.
- [x] **All URL Launches Sanitized**: All URL launching routes exclusively through `SafeLauncher` enforcing `https` schemes.
- [x] **Sentry PII Protection**: `sendDefaultPii` is set to `false`, and `beforeSend` redacts Bearer tokens, JWTs, emails, query strings, and presigned URL signatures, and drops request bodies and user identifiers.
- [ ] **Android Signing Configuration**: Release builds in `android/app/build.gradle.kts` currently use debug keys. Before publishing to Google Play Store, configure a production keystore in `key.properties` (never committed to git).
