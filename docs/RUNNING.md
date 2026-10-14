# Running the App

This document provides the exact commands required to run the STARDY AI Flutter application in different environments, ensuring that the correct configuration variables are passed.

## Environment Variables (`--dart-define`)

The app requires configuration flags passed via `--dart-define`. No secrets or hardcoded endpoints are committed into the repository.

- `APP_ENV`: Application environment (`dev`, `staging`, or `prod`). Required.
- `API_BASE_URL`: Base URL for the backend API. Required. Must use `https://` for `staging` and `prod`.
- `SENTRY_DSN`: Sentry project DSN for error reporting and crash analysis. Optional. If omitted or empty, Sentry logging and monitoring are disabled.

---

## Development (dev)

In the `dev` environment, the base URL does not require `https`.

```bash
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

> **Note on Local Android Development**: `android:usesCleartextTraffic="false"` is enforced in the main manifest (`android/app/src/main/AndroidManifest.xml`) for security. For local development on an emulator or device against an `http://` backend, a debug-only manifest override (`android/app/src/debug/AndroidManifest.xml` with `tools:replace="android:usesCleartextTraffic"` and `android:usesCleartextTraffic="true"`) enables cleartext HTTP traffic strictly in debug builds. Release builds continue to forbid cleartext traffic.

To run with Sentry enabled in development:
```bash
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:3000/api/v1 --dart-define=SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
```

---

## Staging (staging)

In the `staging` environment, the application requires the `API_BASE_URL` to begin with `https://` and end with `/api/v1`.

```bash
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.api.stardy.ai/api/v1 --dart-define=SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
```

---

## Production (prod)

In the `prod` environment, the application requires the `API_BASE_URL` to begin with `https://` and end with `/api/v1`. Running in release mode (`--release`) is required.

```bash
flutter run --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.stardy.ai/api/v1 --dart-define=SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
```
