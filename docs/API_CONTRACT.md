STARDY AI API CONTRACT v1 (frontend <-> backend)

Status: DRAFT written from the frontend audit. This file is the single source of truth the frontend is built against and the backend is built to. If code and this file disagree, this file wins until it is edited. Items marked TO-CONFIRM are in Dev's or Ayaan's modules and must be agreed with them before their phase starts.

GLOBAL RULES
- Base path: /api/v1. Existing /api/remedial/* routes get re-mounted under /api/v1.
- Auth: header Authorization: Bearer <Firebase ID token>. There are no public routes in this contract.
- Success: { "success": true, "data": ... }. Failure: { "success": false, "error": "human-safe message" }. Nothing else. error is a string, never a stack trace, never an internal ID.
- Machine-readable meaning comes from the HTTP status only: 400 validation, 401 missing/expired/invalid token, 403 forbidden, 404 not found OR not yours (never reveal which), 409 conflict / already done, 429 rate limited (always with Retry-After seconds), 5xx server.
- Pagination on every list: ?limit= (default 20, max 50) and ?cursor= (opaque string). Response data: { "items": [...], "nextCursor": string|null }. Lists that are bounded by design (a course's modules) say so explicitly.
- Idempotency: every POST marked [IDEM] requires header Idempotency-Key: <uuid v4>. Same key + same user + same route within 24h returns the original response, not a second write. Client generates ONE key per user action and reuses it on retry.
- Client sends X-Request-Id: <uuid> on every request (log correlation only).
- Dates: ISO 8601 UTC strings.
- IDs: opaque strings (uuid). The client never parses them.
- Enums are UPPER_SNAKE strings. The client must tolerate an unknown enum value (treat as a safe default, never crash).
- Answer keys: correct answers for graded quizzes and assignments NEVER appear in any response. The only exception is remedial (zero XP, zero grade impact), see Remedial.

SHARED TYPES
CourseSummary: { id, title, category: CREATIVE|BUSINESS|TECH, difficulty: BEGINNER|INTERMEDIATE|ADVANCED, thumbnailUrl: string|null, ratingAvg: number, ratingCount: int, durationSeconds: int|null, moduleCount: int, progressPercent: int|null }
  progressPercent is null if the user has not started the course. The app hides the rating when ratingCount is 0.
OpportunitySummary: { id, title, company, location: string|null, type: INTERNSHIP|FREELANCE, category: CREATIVE|BUSINESS|TECH, isPaid: bool, logoUrl: string|null, hasApplied: bool }
GamificationResult: { xpAwarded: int, xp: int, level: int, leveledUp: bool, newLevel: int|null, badgesUnlocked: [{ code, name, iconUrl: string|null }] }
  The level-up screen is shown ONLY when leveledUp is true. The client never computes XP or level.
QuizQuestion (graded): { id, question, options: [string] }   (MCQ only. No answer key.)

AUTH + USER
POST /auth/session   (NO Idempotency-Key: the upsert is naturally idempotent, and a cached response would hide onboardingCompleted changing from false to true)
  Called by the app after every successful Firebase sign-in and again after onboarding completes. Creates User, UserStats, UserSettings in one transaction on first call (upsert on firebaseUid; a unique-violation race re-reads and returns the existing row).
  Body: { displayName?: string (max 80) }   Name is taken from the token claim, then displayName, then the email local part. Signup collects email + password only.
  200: { user: { id, name, username: string|null, email, profilePictureUrl: string|null }, onboardingCompleted: bool }
  Role is deliberately NOT returned: the client never makes an authorization decision.
GET /users/me
  200: { id, name, username|null, email, profilePictureUrl|null, createdAt, careerPaths: [{ id, title, progress: int }] }
POST /onboarding [IDEM]
  Body: { careerGoal: string (2-100), purpose: LEARN_SKILLS|LEVEL_UP|GROW_CAREER|FREELANCING|INTERNSHIP, howHeard: SOCIAL_MEDIA|GOOGLE|INFLUENCER|SCHOOL, influencerName?: string (max 80, required iff howHeard=INFLUENCER), referralCodeUsed?: string (max 32, only iff INFLUENCER), expectation: string (10-500), hasUsedSimilarApps: bool, similarAppsExperience?: string (max 500, only iff hasUsedSimilarApps) }
  Unknown fields are rejected (400). 201: { completed: true }. 409 if already completed (the app treats 409 as success and moves on).

GAMIFICATION / PROFILE / DASHBOARD
GET /gamification/me
  200: { xp, level, xpIntoLevel, xpForNextLevel, currentStreak, longestStreak, lastActiveAt: string|null, activeToday: bool }
GET /gamification/badges
  200: { items: [{ id, code, name, description, iconUrl|null, earned: bool, earnedAt: string|null }] }   (bounded list, all badges)
  PROPOSED award rules (TO-CONFIRM, Jeevan): FIRST_LAUNCH = complete your first module. EARLY_BIRD = complete a module within 24h of signup. MULTITASKER = at least 1 completed module in 2 different courses. COMEBACK_KID = pass a module quiz you previously failed. Timezone-free on purpose.
GET /certificates
  200: { items: [{ id, courseId, courseTitle, title, certificateUrl: string|null (short-lived signed URL), issuedAt }], nextCursor }
GET /dashboard/home
  200: { greetingName: string, continueCourse: { courseId, title, thumbnailUrl|null, progressPercent: int, nextModuleId: string|null } | null, recommended: [CourseSummary] (max 10), newCourses: [CourseSummary] (max 10), careerPaths: [{ id, title, progress }] }
GET /dashboard/grades?courseId=<optional>&cursor&limit
  200: { items: [{ kind: ASSIGNMENT|QUIZ, refId, title, courseTitle, percentage: int, letter, submittedAt }], nextCursor }
  Letter mapping (PROPOSED, computed server-side only): A+ >= 90, A >= 80, B+ >= 75, B >= 70, C >= 60, D >= 50, F < 50.
  Owner: dashboard module (read-only aggregation of AssignmentSubmission.score and QuizAttempt.score). TO-CONFIRM, Jeevan.

COURSES + CONTENT (Ayaan's modules)
GET /courses?difficulty=&category=&cursor&limit -> { items: [CourseSummary], nextCursor }
GET /courses/:courseId
  200: CourseSummary + { description, createdAt, modules: [{ id, title, order, section: string|null, contentType: VIDEO|AUDIO|TEXT, durationSeconds|null, isCompleted: bool }] (bounded, max 200), assignments: [{ id, title, dueAt|null }] }
GET /courses/:courseId/resources -> { items: [{ id, title, author|null, type: LINK|FILE, url: string }] }   (FILE urls are short-lived signed URLs; LINK urls are https only)
GET /modules/:moduleId/content
  200: { contentType, url: string|null, expiresAt: string|null, textContent: string|null }
  VIDEO: url is a short-lived signed HLS (.m3u8) URL from Bunny Stream. AUDIO: signed CDN URL. TEXT: textContent. When the URL expires or playback gets 403, the app calls this again. It never caches the URL beyond expiresAt.
POST /modules/:moduleId/complete [IDEM]
  Called when a VIDEO/AUDIO reaches 90% or the user taps "mark complete" on TEXT. The 90% is a client heuristic and is spoofable (a user can scrub to the end). The SERVER must enforce a minimum elapsed time since the module content was last fetched (at least 50% of durationSeconds for VIDEO/AUDIO) before awarding XP; an earlier completion is accepted but awards nothing.
  200: { isCompleted: true, gamification: GamificationResult | null }

MODULE QUIZ (Ayaan)
POST /modules/:moduleId/quiz/attempts [IDEM]
  Resumes the user's IN_PROGRESS attempt if one exists. 201/200: { attemptId, startedAt, questions: [QuizQuestion] }
POST /quiz/attempts/:attemptId/submit [IDEM]
  Body: { answers: [{ questionId, selectedIndex: int }] }
  200: { score: int (0-100), passed: bool, correctCount, totalCount, gamification: GamificationResult | null }
  409 if already submitted. Module quizzes never trigger remedial.

ASSIGNMENTS (Ayaan)
GET /assignments/:assignmentId
  200: { id, courseId, title, instructions, topics: [string], dueAt|null, fileSubmission: { status: PENDING_REVIEW|REVIEWED, fileName, submittedAt, feedback: string|null } | null, quizSubmission: { score, submittedAt, remedialEligible: bool } | null }
GET /assignments/:assignmentId/quiz -> { questions: [QuizQuestion] }   (TO-CONFIRM Ayaan: assignment questions are MCQ only for now)
POST /assignments/:assignmentId/submissions [IDEM]
  Body: { answers: [{ questionId, selectedIndex }], startedAt?: ISO date }   startedAt is untrusted, server clamps it to [now-24h, now].
  201: { submissionId, score, passed, correctCount, totalCount, remedialEligible: bool (true iff score < 60), gamification: GamificationResult | null }
  409 if the user already submitted this assignment.
POST /assignments/:assignmentId/file-submission [IDEM]
  Body: { objectKey, fileName, sizeBytes }  (objectKey comes from /uploads/presign)
  201: { status: PENDING_REVIEW, submittedAt }. The server re-checks that the object exists, its real size, and its magic bytes BEFORE accepting. A bad file is deleted and the call returns 400.

UPLOADS (Jeevan)
POST /uploads/presign
  Body: { purpose: ASSIGNMENT_FILE|PROJECT_FILE|AVATAR, targetId: string (assignmentId/projectId; omit for AVATAR), fileName (max 120), contentType, sizeBytes }
  200: { uploadUrl, method: "PUT", headers: { ... }, objectKey, expiresAt, maxBytes }
  Allowed types per purpose and the hard size cap are decided by the SERVER and returned as maxBytes; the app's own checks are UX only. Rate limited, fail-closed on limiter error (uploads are expensive).

REMEDIAL (Dev, TO-CONFIRM: re-mount under /api/v1 and add questions[].correctIndex/explanation to the payload)
POST /remedial/generate [IDEM]  Body: { assignmentSubmissionId }  -> { remedialQuizId, status, weakConcepts: [string], questions: [{ id, question, options, correctIndex: int, explanation: string|null }] }
GET /remedial/:remedialQuizId -> same shape
POST /remedial/:remedialQuizId/submit [IDEM]  Body: { answers: [{ questionId, selectedIndex }] } -> { score, status: COMPLETED }
  Remedial responses NEVER contain gamification. The app never shows the level-up screen after remedial. Exposing correctIndex here is deliberate: remedial has zero XP and zero grade impact, so there is nothing to cheat, and it allows instant per-question feedback without an extra endpoint.

CAREER PATHS + PROJECTS
GET /career-paths -> { items: [{ id, title, description, skills: [string], progress: int|null }], nextCursor }
GET /career-paths/:id -> { id, title, description, skills, enrolled: bool, progress: int, courses: [{ courseId, title, difficulty, thumbnailUrl|null, order, progressPercent|null }] (bounded) }
POST /career-paths/:id/enroll [IDEM] -> { enrolled: true }   (TO-CONFIRM Ayaan: today nothing defines when UserCareerPath rows are created)
GET /career-paths/:id/project (Dev, TO-CONFIRM)
  200: { eligible: bool, progress: int, project: { id, title, description, requirements: [string], deliverables: [string], stretchGoals: [string], submission: { status, linkUrl|null, fileName|null, submittedAt } | null } | null }
  A not-yet-generated project is data (project: null), not a 404.
POST /career-paths/:id/project [IDEM] (Dev, TO-CONFIRM) -> same shape. Generates once; allowed only at progress >= 50, else 409. Never triggered by a GET.
POST /projects/:projectId/submission [IDEM]
  Body: { linkUrl?: https URL (max 500), objectKey?, fileName?, sizeBytes? } at least one of linkUrl / objectKey required.
  200: { status: PENDING_REVIEW, submittedAt, gamification: GamificationResult | null }

OPPORTUNITIES (Ayaan)
GET /opportunities?type=&category=&cursor&limit -> { items: [OpportunitySummary], nextCursor }
GET /opportunities/:id -> OpportunitySummary + { description, applyUrl: string|null }
POST /opportunities/:id/apply [IDEM]  Body: { coverNote?: string (max 1000) } -> 201 { status: SUBMITTED, appliedAt }. 409 if already applied (the app treats this as applied).

SEARCH (Jeevan, new scope)
GET /search?q=<2-60 chars>&type=COURSE|OPPORTUNITY&cursor&limit -> { items: [CourseSummary] | [OpportunitySummary], nextCursor }
  One entity type per request so pagination stays cursor-based. Rate limited 30/min/user, fail-open.

STARBUDDY (Dev, TO-CONFIRM everything in this block)
GET /chat/conversations -> { items: [{ id, title|null, updatedAt }], nextCursor }
POST /chat/conversations [IDEM] -> { id }
GET /chat/conversations/:id/messages?cursor&limit -> { items: [{ id, role: USER|ASSISTANT, content, createdAt }], nextCursor }
POST /chat/conversations/:id/messages [IDEM]  Body: { content: string (1-2000) } -> { userMessage, assistantMessage }
  429 = daily cap (Retry-After). 409 = blocked because a quiz is in progress. Message text is plain text; the app renders it as plain text, never as HTML.
