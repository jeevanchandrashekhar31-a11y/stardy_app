DOC UPDATES TO MAKE (so your docs match what you decided on 2026-10-07)

Edit these by hand. Per your own rule, if a doc and chat disagree the doc wins, so these edits matter.

1. BACKEND_ROLES_MASTER_V2.md
 a. Jeevan section, add: src/modules/search/ - cross-entity search (courses + opportunities), new scope decided 2026-10-07. READ-ONLY on tables Ayaan owns (Course, Opportunity), select{} only, no writes. GET /api/v1/search, one entity type per request, cursor-paged, Redis rate limit 30/min/user fail-open, pg_trgm indexes.
 b. Ayaan section and the line "No standalone search module": replace with "Superseded 2026-10-07: search is a standalone module owned by Jeevan. Browse filters (difficulty, category, type) stay as query params inside course/ and opportunity/."
 c. Ayaan section, add: Application model + POST /opportunities/:id/apply (inside src/modules/opportunity/), AssignmentFileSubmission and ProjectSubmission file-confirm endpoints, CourseResource, career path enrol endpoint. Jeevan's admin module reads and updates Application status and the two file-submission review statuses.
 d. Open items, add the TO-CONFIRM list in section 5 below.

2. STARDY_FEATURES_DOC_V2.md
 a. Section 4.3: strike the "No standalone search module" bullet. Add "Search module - decided 2026-10-07, see roles doc".
 b. Section 4.3 (resolved), add: in-app Apply (Application model), project submission (ProjectSubmission), assignment file submission (AssignmentFileSubmission), Bunny Stream playback replaces YouTube, course rating model (display only).
 c. Section 4.1 (deferred), add, all "UI absent or inert, no backend work": Leaderboard screen, Pomodoro timer, App Tutorial, Journey mapping, Notifications screen (bell icon stays inert), Personal Information edit screen (+ PATCH /users/me), Theme/Language wiring in Settings, course rating submit UI, StudySession model. Social links and Week Rewind are already there: add "UI hidden behind compile-time flags in the app". Add also: quiz answer review after submission (grades page; flag answerReview) - needs a post-submission review endpoint.

3. PHASE_PLAN_V2.md
 a. Phase 2 Dashboard: add GET /dashboard/home and GET /dashboard/grades (letter mapping server-side). Remove StudySession write logic.
 b. Phase 3 Gamification: remove Leaderboard. Add XpEvent ledger (idempotent awards) and badge award engine for the four proposed codes.
 c. Phase 4 Settings + Notifications: both currently have NO consumer in the app (settings rows are static dialogs, notifications is a bell icon). Decide: defer the phase, or build only what the app can call. My advice: defer.
 d. Phase 5 Uploads: purposes ASSIGNMENT_FILE, PROJECT_FILE, AVATAR; server validates magic bytes after the PUT and deletes bad objects.
 e. Add Phase 9 - Search (after Phase 8, or before Phase 8 if you want search sooner; it has no dependency on admin). Depends on Phase 1.
 f. Phase 7 Onboarding: the app now calls POST /onboarding after sign-up; GET onboarding status is folded into POST /auth/session.

4. BACKEND SCHEMA
 Reconcile schema.prisma (V3) with the schema actually in the repo BEFORE migrating. Read SCHEMA_CHANGES.md "DELIBERATELY NOT TOUCHED".

5. TO-CONFIRM BEFORE THE PHASE THAT CALLS THEM (the contract marks these; the app is built to the contract, so these owners must agree or the contract is edited first)
 - Dev: remedial re-mount under /api/v1 and correctIndex + explanation in the remedial payload; project GET/POST at /career-paths/:id/project; the whole STARBUDDY block.
 - Ayaan: assignment quiz is MCQ-only; career path enrol endpoint and when UserCareerPath rows are created; applyUrl becoming nullable; Opportunity.category/isPaid/isActive.
 - Jeevan: badge award rules, letter-grade thresholds, grades endpoint living in the dashboard module.
