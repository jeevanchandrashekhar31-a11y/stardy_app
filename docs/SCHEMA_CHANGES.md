SCHEMA CHANGES: uploaded schema.prisma -> schema.prisma (V3)

Validation: parsed with Prisma's own schema validator (the wasm build, Prisma 7 line) after removing the datasource url line, which is unchanged from your original. Result: valid. A deliberately broken copy was rejected, so the check is real. NOT done: prisma migrate, prisma generate, or any run against a database. The engine download is blocked in my environment. Run `npx prisma validate` and `npx prisma migrate dev --create-only` yourself and read the generated SQL before applying it.

Line endings: the file is LF, matching your .gitattributes.

ADDED (driven by the frontend)
- Course.ratingAvg, ratingCount + model CourseRating. Rating write path and the rate-a-course UI are future scope. Until a rating exists the app hides the rating (count 0 = not shown).
- Model CourseResource: replaces the hardcoded ebook cards on the Resources tab.
- Module.section, durationSeconds, bunnyVideoId: the app groups lessons under chapter headings (section), shows lengths (durationSeconds), and plays Bunny Stream video by signed URL (bunnyVideoId, never a stored URL).
- Assignment.topics, dueAt: "Topics Included" and "Submission Deadline" on the assignment screen.
- Model AssignmentFileSubmission: the attachment flow on the assignment screen is instructor-reviewed. It is NOT the same thing as AssignmentSubmission (auto-graded quiz, feeds remedial, score NOT NULL). Separate model = Ayaan's graded path is untouched.
- Model ProjectSubmission (link and/or file, 1:1 with Project).
- Model Application + enum ApplicationStatus: in-app "Apply Now". Unique (userId, opportunityId).
- Opportunity.category, isPaid, isActive, logoUrl. applyUrl is now optional. This can break Ayaan's code if it assumes non-null. Check before migrating.
- CareerPath.skills: "Skills to Know".
- Badge.code (unique), sortOrder. description now means the human-readable award rule.
- Enums: ApplicationStatus, ReviewStatus, ResourceType, XpSource.

ADDED (driven by your own standards, not the frontend. Veto if you disagree)
- Model XpEvent, unique (userId, source, sourceId). Your Phase 3 rule is "never read-then-write XP, use unique constraints", and that needs something to be unique ON. Without it, double-submitting a quiz can double-award XP. 
- UserSettings.timezone default Asia/Kolkata: streak day boundaries are wrong without a timezone. Cheap column now, painful migration later.
- Index Course (createdAt, id) for cursor pagination; Opportunity (isActive, type, createdAt).

REMOVED (need your explicit OK)
- LinkedAccount: social login is a Firebase Auth provider, SM linking is deferred.
- StudySession: its only consumers were Pomodoro and Week Rewind, both deferred. Re-add with those features.

DELIBERATELY NOT TOUCHED
- QuizQuestion and the 2-value QuizAttemptStatus are unchanged from the file you uploaded. Your repo may already hold Ayaan's variant (QuizQuestion deleted, questions stored as JSON on QuizAttempt, a 4-value status enum). That sign-off is still open and I did not decide it silently. The API contract does not care which one you pick. Reconcile against the real schema in the repo BEFORE running any migration from this file.
- Subscription / Notification models: still deferred.
- OnboardingResponse already matches features doc 3.2. No change.

NOT IN SCHEMA, by design
- "Completed onboarding" is derived from the existence of an OnboardingResponse row. No boolean flag to drift out of sync.
- Grades: computed from AssignmentSubmission.score and QuizAttempt.score. No new table.
- Letter grade mapping lives in the API layer (see API_CONTRACT.md), one place only.

RAW SQL MIGRATION NEEDED (Prisma cannot declare these cleanly)
- Search: enable pg_trgm and add GIN trigram indexes on Course.title and Opportunity.title (and Opportunity.company). Without them search degrades to sequential scans.
- ProjectSubmission: CHECK (linkUrl IS NOT NULL OR fileKey IS NOT NULL).
- CourseRating: CHECK (value BETWEEN 1 AND 5).

DECISIONS I MADE FOR YOU, WITH RATINGS
- Assignment file upload: separate AssignmentFileSubmission model 8/10. Alternative: add a type column and nullable fields to AssignmentSubmission 5/10, because it loosens the model remedial depends on. Alternative: drop the file upload from the UI 3/10, because it deletes a feature the UI already has.
- Course rating: CourseRating model + denormalised average 8/10. Alternative: a plain editable rating number on Course 3/10, because it is admin-typed fake social proof.
