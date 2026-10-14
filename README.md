# STARDY AI Mobile Application

STARDY AI is an intelligent, student-centric learning platform mobile application built with Flutter. It provides adaptive learning pathways, course management, video and quiz modules, remedial learning, career development tracking, opportunity discovery, gamification milestones, and secure cloud storage and profile management.

## Prerequisites

- **Flutter SDK**: 3.44.0 (Channel stable)
- **Dart SDK**: 3.12.0
- **Android Studio / Xcode** for platform builds and emulators/simulators

## Configuration & Running

The application uses compile-time environment flags configured via `--dart-define`. No secrets or endpoints are committed into source control.

### Required Environment Flags

- `APP_ENV`: Application environment (`dev`, `staging`, or `prod`).
- `API_BASE_URL`: Base URL for the STARDY backend API (must end with `/api/v1`).
- `SENTRY_DSN`: (Optional) Sentry DSN for monitoring and error tracking.

### Run Commands

**Development**:
```bash
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

**Staging**:
```bash
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.api.stardy.ai/api/v1
```

**Production**:
```bash
flutter run --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.stardy.ai/api/v1
```

For detailed platform notes (such as local Android cleartext traffic handling), see [RUNNING.md](docs/RUNNING.md).

## Quality Assurance & Testing

Run static analysis:
```bash
flutter analyze
```

Run test suite:
```bash
flutter test
```

## Architecture & Code Structure

The `lib/` directory is organized into modular layers:

```
lib/
├── core/                  # Shared foundations, utilities, and infrastructure
│   ├── config/            # App environment, flavors, and config definitions
│   ├── data/              # Base repositories, storage abstractions
│   ├── logging/           # Structured logging and telemetry integrations
│   ├── models/            # Core domain and shared transfer models
│   ├── network/           # HTTP client, interceptors, auth token injection
│   ├── state/             # Global state abstractions and pagination helpers
│   ├── ui/                # Shared widgets, themes, colors, and components
│   ├── upload/            # Secure upload managers and file helpers
│   └── url/               # External URL handling and deep links
├── features/              # Feature domain logic, DTOs, controllers, and services
│   ├── career_paths/      # Career path tracking and enrollment
│   ├── courses/           # Course catalogs, modules, and video playback
│   ├── dashboard/         # Dashboard aggregations and recent activity
│   ├── gamification/      # XP, streak tracking, and badges
│   ├── grades/            # Academic grades and assignment submissions
│   ├── onboarding/        # User onboarding flow and preferences
│   ├── opportunities/     # Internships, jobs, and applications
│   ├── profile/           # User profile and settings
│   ├── remedial/          # Adaptive remedial quizzes and review
│   ├── search/            # Cross-entity discovery and query filters
│   └── session/           # User authentication, Firebase sync, and session state
├── Views/                 # Presentation layer screens, sub-pages, and widgets
│   ├── CareerPath/        # Career path UI
│   ├── Courses/           # Course catalog, module view, and quiz UI
│   ├── onboarding/        # Onboarding wizard screens
│   ├── Pages/             # Auth (Login, Sign-up) and primary navigation
│   ├── screens/           # Main application screens (Home, Profile, etc.)
│   ├── starbuddy/         # Study assistant UI
│   └── widgets/           # Feature-specific presentation widgets
├── Routers/               # App routing configuration and navigation guards
└── services/              # Platform services, background tasks, and native bridges
```

## Documentation

The `docs/` directory contains operational and architectural documentation:

- [API_CONTRACT.md](docs/API_CONTRACT.md): API contract specification and route definitions.
- [contract_conformance.md](docs/contract_conformance.md): Endpoint conformance matrix and test verification.
- [dto_conventions.md](docs/dto_conventions.md): Data Transfer Object patterns and serialization rules.
- [RUNNING.md](docs/RUNNING.md): Comprehensive instructions for launching across environments.
- [RELEASE.md](docs/RELEASE.md): Release preparation, versioning, and build steps.
- [INTEGRATION_DAY.md](docs/INTEGRATION_DAY.md): Backend integration checklist and endpoint validation.
- [FIREBASE_KEY_RESTRICTIONS.md](docs/FIREBASE_KEY_RESTRICTIONS.md): Security guide for Google Cloud / Firebase API key restrictions.
- [MANUAL_FIREBASE_STEPS.md](docs/MANUAL_FIREBASE_STEPS.md): Setup instructions for Firebase project credentials and rules.
