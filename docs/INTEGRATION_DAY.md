# STARDY AI Integration-Day Checklist & Backend Connection Guide

## 1. Overview and Core Governance Rule

This guide documents the procedures for connecting the STARDY AI Flutter application to the real Node/Express/Prisma backend.

> ### CRITICAL CONTRACT GOVERNANCE RULE
> `docs/API_CONTRACT.md` is the single source of truth between the client and backend teams.
> If the backend implementation deviates in any way from the contract (field naming, status codes, envelope shape, enum case, or pagination schema):
> 1. **Do NOT hack the UI or View layer.**
> 2. **Edit `docs/API_CONTRACT.md` first** with mutual agreement between Jeevan and backend engineers.
> 3. **Change ONLY the repository layer (`lib/features/*/repository/` and DTOs)** to conform to the updated contract.
> UI screens, routers, and business logic remain isolated from transport-level deviations.

---

## 2. Environment Configuration

The client requires zero code changes to connect to a real environment. All configurations are supplied via `--dart-define` flags during build or run:

### Staging Run:
```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging-api.stardy.ai/api/v1 \
  --dart-define=SENTRY_DSN=https://public_key@o0.ingest.sentry.io/0
```

### Production Release Build:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.stardy.ai/api/v1 \
  --dart-define=SENTRY_DSN=https://public_key@o0.ingest.sentry.io/0
```

### Local Dev Backend Run (with Cleartext Warning):
```bash
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```
*(Note: Cleartext HTTP is permitted ONLY when `APP_ENV=dev`. Android release manifests block cleartext traffic via `usesCleartextTraffic="false"`.)*

---

## 3. Firebase Setup Pre-requisite

1. Ensure `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` correspond to the active Firebase project.
2. Verify that Firebase Authentication has Email/Password and Google Sign-In enabled.
3. The backend must verify Firebase ID tokens passed in `Authorization: Bearer <token>` using Firebase Admin SDK.

---

## 4. Unconfirmed Contract Blocks (TO-CONFIRM Status)

At the time of writing (F8.3), the following contract blocks from `docs/API_CONTRACT.md` were flagged as **TO-CONFIRM**:

1. **Gamification Badge Award Rules (Jeevan)**:
   - Proposed badge criteria: `FIRST_LAUNCH` (complete first module), `EARLY_BIRD` (complete a module within 24h of signup), `MULTITASKER` (modules across 2 different courses), `COMEBACK_KID` (pass previously failed quiz).
2. **Dashboard Grades Aggregation & Letter Mapping (Jeevan)**:
   - Read-only aggregation of `AssignmentSubmission.score` and `QuizAttempt.score`. Proposed letter mapping: `A+ >= 90`, `A >= 80`, `B+ >= 75`, `B >= 70`, `C >= 60`, `D >= 50`, `F < 50`.
3. **Assignment Quiz Question Format (Ayaan)**:
   - Currently MCQ only (options list, single correct answer on server).
4. **Remedial Route Remounting & Explanations (Dev)**:
   - Remounting under `/api/v1/remedial/*` and including `questions[].correctIndex` and `explanation` in payloads (per contract rule allowing answer keys for zero-XP remedial only).
5. **Career Path Project Lifecycle & Enrollment (Ayaan & Dev)**:
   - Rule governing when `UserCareerPath` rows are generated and threshold for project brief generation (progress >= 50%).
6. **Starbuddy Endpoints (Dev)**:
   - All chat conversation and message endpoints (`/chat/conversations*`) are TO-CONFIRM. Blocked until backend implementation.

---

## 5. Manual Smoke Test Checklist per Endpoint

Execute this smoke test sequentially on Integration Day:

### Group 1: Auth & User
- [ ] `POST /auth/session`: Sign in with fresh Firebase user. Verify envelope `{ success: true, data: { user: {...}, onboardingCompleted: false } }`.
- [ ] `POST /onboarding`: Submit onboarding form. Verify 201 response and `Idempotency-Key` header sent. Test duplicate submission returns 409 and client treats as success.
- [ ] `POST /auth/session`: Re-check session. Verify `onboardingCompleted: true`.
- [ ] `GET /users/me`: Verify user profile returns name, email, careerPaths array.

### Group 2: Gamification & Profile
- [ ] `GET /gamification/me`: Verify XP, level, streak, and `activeToday` values match backend state.
- [ ] `GET /gamification/badges`: Verify list of badges with earned status and timestamp.
- [ ] `GET /certificates`: Verify certificates list and short-lived download URL.

### Group 3: Dashboard & Grades
- [ ] `GET /dashboard/home`: Verify greeting name, continue course card, recommended courses, and new courses.
- [ ] `GET /dashboard/grades`: Verify list of quiz/assignment scores and pagination with `?cursor=`.

### Group 4: Courses & Content
- [ ] `GET /courses`: Open Learn tab. Verify cursor pagination and filter by category/difficulty.
- [ ] `GET /courses/:courseId`: Open course details. Verify modules and assignments list loads.
- [ ] `GET /courses/:courseId/resources`: Open Resources. Verify external links and downloadable files.
- [ ] `GET /modules/:moduleId/content`: Play video module. Verify HLS stream URL (`.m3u8`) plays in player.
- [ ] `POST /modules/:moduleId/complete`: Finish video to 90%. Verify server awards XP and returns `gamification` result.

### Group 5: Quizzes & Remedial
- [ ] `POST /modules/:moduleId/quiz/attempts`: Start module quiz. Verify questions list without correct answers.
- [ ] `POST /quiz/attempts/:attemptId/submit`: Submit answers. Verify score and level-up modal if leveled up.
- [ ] `GET /assignments/:assignmentId`: View assignment details.
- [ ] `POST /assignments/:assignmentId/submissions`: Submit quiz with failing grade (<60%). Verify `remedialEligible: true`.
- [ ] `POST /remedial/generate`: Tap Remedial button. Verify generated questions with instant answer explanations.
- [ ] `POST /remedial/:remedialQuizId/submit`: Complete remedial. Verify score and zero XP awarded.

### Group 6: Uploads & Project Submissions
- [ ] `POST /uploads/presign`: Pick file. Verify presigned URL and `objectKey`.
- [ ] Direct Cloudflare R2 (S3-compatible presigned PUT) PUT: Verify chunked upload to `uploadUrl` succeeds.
- [ ] `POST /assignments/:assignmentId/file-submission`: Submit file metadata. Verify `PENDING_REVIEW`.

### Group 7: Career Paths & Projects
- [ ] `GET /career-paths/:id`: Open career path. Verify milestones and course requirements.
- [ ] `POST /career-paths/:id/enroll`: Tap enroll. Verify status changes to enrolled.
- [ ] `GET /career-paths/:id/project`: Check project tab. Verify null if <50% or project brief if unlocked.
- [ ] `POST /career-paths/:id/project`: Generate project. Verify brief and deliverables.
- [ ] `POST /projects/:projectId/submission`: Submit GitHub URL or uploaded archive. Verify status `PENDING_REVIEW`.

### Group 8: Opportunities & Search
- [ ] `GET /opportunities`: Open Opportunities tab. Verify internships and filter pills.
- [ ] `GET /opportunities/:id`: Open opportunity detail. Verify company and requirements.
- [ ] `POST /opportunities/:id/apply`: Submit application with cover note. Verify `SUBMITTED`.
- [ ] `GET /search?q=flutter&type=COURSE`: Typeahead search courses (debounced 400ms).
- [ ] `GET /search?q=flutter&type=OPPORTUNITY`: Typeahead search opportunities.

---

## 6. Token Expiration & Error Recovery Smoke Test

- [ ] Force token expiration: Revoke token or wait 1 hour. Trigger API request. Verify client automatically refreshes token and retries once transparently.
- [ ] 401 on refresh retry: Verify client clears session, logs out user, and redirects to login screen.
- [ ] 429 Rate Limit: Verify client respects `Retry-After` header without hammering backend.
- [ ] 502/503 Downtime: Verify friendly error dialog / snackbar without exposing raw backend stack traces.
