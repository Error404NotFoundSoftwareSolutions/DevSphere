# [US-03] Student Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement student profile creation, validation, management, and privacy controls across the Python FastAPI backend and Flutter desktop client, strictly enforcing data minimization (no date of birth, phone number, or address) and role-based access control with audited operator inspection.

**Architecture:** 
1. **Backend API (`services/api`)**: Enhance `/v1/me/profile`, `/v1/students/{user_id}/profile`, and `/v1/operator/students/{user_id}/profile` in FastAPI with Pydantic field validation (allowed characters, length constraints, field-level error messages), token-derived user ID scoping (ignoring user IDs in request bodies), cross-student read denial (403/404), and audited operator read access. Fix cross-student read leaks in submission endpoints.
2. **Data & Storage Layer (`apps/desktop/lib/features/firestore`)**: Expand `StudentProfile` and `FirestoreService` to include optional `academicYear` / semester and ensure robust serialization while preventing prohibited fields (DOB, phone, address).
3. **Desktop UI (`apps/desktop/lib/features/profile`)**: Implement `ProfileScreen` with display name prefilling from auth, editable input fields for optional academic details and interests, form validation, privacy indicators, and post-onboarding profile editing support.

**Tech Stack:** FastAPI, Pydantic v2, Python 3.12, Flutter 3.x, Cloud Firestore SDK, Dart.

---

### File Structure Map

- **Backend Logic & Routers:**
  - `services/api/app/routers/me.py`: Profile Pydantic schema with regex/length validation, ignore body `user_id`, student cross-read denial.
  - `services/api/app/routers/operator.py`: Add `GET /v1/operator/students/{user_id}/profile` with operator role verification and audit event logging.
  - `services/api/app/routers/submissions.py`: Secure `GET /v1/submissions/{submission_id}` against cross-student unauthorized reads.
  - `services/api/tests/test_profile.py`: Automated tests for all FR-PROF-002 through FR-PROF-008 backend requirements and test cases (`TC-FR-PROF-004-01`, `TC-FR-PROF-005-01`, `TC-FR-PROF-005-02`, `TC-FR-PROF-006-01`, `TC-FR-PROF-006-02`, `TC-FR-PROF-007-01`, `TC-FR-PROF-008-01`).
- **Flutter Desktop Client:**
  - `apps/desktop/lib/features/firestore/firestore_service.dart`: Add `academicYear` field to `StudentProfile` and update Firestore serialization.
  - `apps/desktop/lib/features/profile/profile_screen.dart`: Rich profile management screen supporting display name collection (prefilled & editable), optional college details, privacy badges, and editing after onboarding.
  - `apps/desktop/test/profile_test.dart`: Flutter widget and integration tests for `TC-FR-PROF-002-01`, `TC-FR-PROF-003-01`, and `TC-FR-PROF-008-01`.
  - `apps/desktop/test/firebase_services_test.dart`: Verify updated `StudentProfile` serialization with `academicYear`.
- **Documentation & Tracking:**
  - `docs/backlog/issues/US-03.md`: Update test case tick marks.
  - `docs/backlog/creation_log.md`: Record passed test cases.
  - `docs/CHANGELOG.md`: Record US-03 completion under Unreleased.

---

### Task 1: Backend Profile Validation & Token-Derived User ID (FR-PROF-003, FR-PROF-004, FR-PROF-005)

**Files:**
- Modify: `services/api/app/routers/me.py`
- Test: `services/api/tests/test_profile.py`

- [ ] **Step 1: Write the failing tests for FR-PROF-004 and FR-PROF-005**
  Add test functions in `services/api/tests/test_profile.py` with test case IDs `TC-FR-PROF-004-01`, `TC-FR-PROF-005-01`, and `TC-FR-PROF-005-02`:
  - `TC-FR-PROF-004-01`: test invalid types (e.g., int for display_name, str for interests), invalid lengths (empty string or >60 chars for display_name), invalid characters (e.g. `<script>`, control characters) - verify 422 response with field-level error messages in `detail`.
  - `TC-FR-PROF-005-01`: test profile created and updated for authenticated user.
  - `TC-FR-PROF-005-02`: test user ID in request body is ignored (Student A passes Student B's user_id in PUT body; Student A's profile updates, Student B's profile is unchanged).

- [ ] **Step 2: Run tests to verify they fail**
  Run: `uv run pytest services/api/tests/test_profile.py -v`
  Expected: FAIL on the new validation and user ID tests.

- [ ] **Step 3: Update `Profile` model and `put_profile` in `services/api/app/routers/me.py`**
  - Define `Profile` schema with:
    - `display_name`: `str = Field(min_length=1, max_length=60, pattern=r"^[\w\s.'-]+$")`
    - `college`: `str | None = Field(default=None, max_length=100)`
    - `course`: `str | None = Field(default=None, max_length=100)`
    - `academic_year`: `str | None = Field(default=None, max_length=50)`
    - `interests`: `list[str] = Field(default_factory=list, max_length=20)`
    - `user_id`: `str | None = None` (explicitly allowed so client passing `user_id` does not fail 422, but stripped before saving)
    - `model_config = ConfigDict(extra="forbid")`
  - In `put_profile`, dump model excluding `user_id`, store in `memory.USERS[user.user_id]["profile"]`.

- [ ] **Step 4: Run tests to verify they pass**
  Run: `uv run pytest services/api/tests/test_profile.py -v`
  Expected: PASS

- [ ] **Step 5: Run ruff check on services/api**
  Run: `uv run ruff check services/api/`
  Expected: All checks passed.

---

### Task 2: Cross-Student Read Prevention & Audited Operator Inspection (FR-PROF-006, FR-PROF-007)

**Files:**
- Modify: `services/api/app/routers/me.py`
- Modify: `services/api/app/routers/operator.py`
- Modify: `services/api/app/routers/submissions.py`
- Test: `services/api/tests/test_profile.py`

- [ ] **Step 1: Write the failing tests for FR-PROF-006 and FR-PROF-007**
  Add tests in `services/api/tests/test_profile.py`:
  - `test_tc_fr_prof_006_01_student_reads_own_profile_only(client)`: Verify Student A reads their own profile; student cannot access operator routes.
  - `test_tc_fr_prof_006_02_cross_student_read_attempt(client)`: Student A requests Student B's profile, attempts, and submissions by ID; verify 403 or 404 on every request; verify no data returned; verify operator read of Student B's profile as operator succeeds and creates an audit event.
  - `test_tc_fr_prof_007_01_profile_private_by_default(client)`: Verify profile data is private by default and not discoverable or queryable by other students.

- [ ] **Step 2: Run tests to verify they fail**
  Run: `uv run pytest services/api/tests/test_profile.py -v`
  Expected: FAIL on cross-student and operator endpoints.

- [ ] **Step 3: Implement endpoints and authorization checks**
  - In `services/api/app/routers/operator.py`:
    Add `GET /v1/operator/students/{user_id}/profile`:
    Requires `require_operator`.
    Records audit: `audit.record(op.user_id, "operator_read_profile", user_id, "operator_inspection")`.
    Returns student profile or raises 404.
  - In `services/api/app/routers/me.py`:
    Add `GET /v1/students/{user_id}/profile`:
    If `user.user_id != user_id and user.role != "operator"`: raise 403 or 404.
    If operator: record audit and return profile.
    If own user: return profile.
  - In `services/api/app/routers/submissions.py`:
    In `get_submission`: verify attempt ownership `attempt["user_id"] == user.user_id or user.role == "operator"`. If not, raise 404.

- [ ] **Step 4: Run tests to verify they pass**
  Run: `uv run pytest services/api/tests/test_profile.py -v`
  Expected: PASS

- [ ] **Step 5: Run full pytest suite**
  Run: `uv run pytest`
  Expected: All passed.

---

### Task 3: Desktop Firestore Data Model & Serialization Update (FR-PROF-003)

**Files:**
- Modify: `apps/desktop/lib/features/firestore/firestore_service.dart`
- Modify: `apps/desktop/test/firebase_services_test.dart`

- [ ] **Step 1: Write test for StudentProfile with academicYear**
  In `apps/desktop/test/firebase_services_test.dart`, update the `StudentProfile` test to include `academicYear` in serialization and deserialization, and assert that prohibited fields (`dateOfBirth`, `dob`, `phone`, `address`) are strictly absent.

- [ ] **Step 2: Run test to verify it fails**
  Run: `melos exec --scope="desktop" -- "flutter test test/firebase_services_test.dart"`
  Expected: FAIL (academicYear not recognized).

- [ ] **Step 3: Update `StudentProfile` in `firestore_service.dart`**
  Add `final String? academicYear;` to `StudentProfile`, include in constructor, `fromFirestore`, and `toFirestore`.

- [ ] **Step 4: Run test to verify it passes**
  Run: `melos exec --scope="desktop" -- "flutter test test/firebase_services_test.dart"`
  Expected: PASS

---

### Task 4: Flutter Desktop Profile UI & Onboarding/Post-Onboarding Management (FR-PROF-002, FR-PROF-003, FR-PROF-008)

**Files:**
- Modify: `apps/desktop/lib/features/profile/profile_screen.dart`
- Create: `apps/desktop/test/profile_test.dart`

- [ ] **Step 1: Write tests in `apps/desktop/test/profile_test.dart`**
  Add widget tests covering:
  - `TC-FR-PROF-002-01`: Displays display name prefilled from identity provider, editable; all other fields optional; saving with only display name succeeds; empty display name validation error.
  - `TC-FR-PROF-003-01`: Inspection test verifying presence of college, course, academic year, interests, and STRICT absence of date of birth, phone number, address fields.
  - `TC-FR-PROF-008-01`: Student can view existing profile values and edit them after onboarding; save callback emits updated profile.

- [ ] **Step 2: Run tests to verify they fail**
  Run: `melos exec --scope="desktop" -- "flutter test test/profile_test.dart"`
  Expected: FAIL (missing fields/widgets).

- [ ] **Step 3: Implement `ProfileScreen` in `apps/desktop/lib/features/profile/profile_screen.dart`**
  Build a comprehensive, user-friendly profile form with:
  - Header: `// User story: US-03 Create and manage my profile (Sprint 1, MVP)`
  - Prefilled `initialDisplayName`, `initialCollege`, `initialCourse`, `initialAcademicYear`, `initialInterests`.
  - TextFormField for display name with key `profile_display_name_field`, validator requiring non-empty string.
  - Optional TextFormFields for college (`profile_college_field`), course (`profile_course_field`), academic year (`profile_academic_year_field`).
  - Interests chips / tag input (`profile_interests_field`).
  - Privacy notice banner explaining "Profile data is private by default and visible only to you."
  - Save button with key `profile_save_button`.
  - Callbacks `onSave(StudentProfile profile)` and integration with `FirestoreService` if passed.

- [ ] **Step 4: Run tests to verify they pass**
  Run: `melos exec --scope="desktop" -- "flutter test test/profile_test.dart"`
  Expected: PASS

---

### Task 5: Verification Suite & Documentation Updates

**Files:**
- Modify: `docs/backlog/issues/US-03.md`
- Modify: `docs/backlog/creation_log.md`
- Modify: `docs/CHANGELOG.md`
- Validate: `start.sh`

- [ ] **Step 1: Run all verification commands**
  - `uv run ruff check .`
  - `uv run pytest`
  - `melos run check`
  - `bash -n ./start.sh`
  - `python tools/check_docs.py`

- [ ] **Step 2: Update documentation**
  - In `docs/backlog/issues/US-03.md`: tick all 9 test cases `[x]` and update requirements covered.
  - In `docs/backlog/creation_log.md`: record test pass results for US-03.
  - In `docs/CHANGELOG.md`: document US-03 profile management and privacy controls under "Unreleased".
  - Re-run `python tools/check_docs.py` to ensure docs consistency.

- [ ] **Step 3: Review git status and diff**
  Verify no unwanted files, secrets, or temporary files are present.

