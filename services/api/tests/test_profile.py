# User story: US-03 Create and manage my profile (Sprint 1, MVP)
# Requirements: FR-PROF-002..008
# Implemented here: tests for TC-FR-PROF-003-01 through TC-FR-PROF-008-01

from app.core import audit
from app.db import memory
from conftest import OPERATOR, OTHER, STUDENT


def test_tc_fr_prof_003_01_profile_refuses_dob_phone_address(client):
    """TC-FR-PROF-003-01: Profile supports optional college, course, academic year,

    interests, but strictly refuses date of birth, phone number, and address.
    """
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )

    # Date of birth is rejected
    r_dob = client.put(
        "/v1/me/profile",
        json={"display_name": "Asha", "date_of_birth": "2000-01-01"},
        headers=STUDENT,
    )
    assert r_dob.status_code == 422

    # Phone number is rejected
    r_phone = client.put(
        "/v1/me/profile",
        json={"display_name": "Asha", "phone_number": "+1234567890"},
        headers=STUDENT,
    )
    assert r_phone.status_code == 422

    # Address is rejected
    r_addr = client.put(
        "/v1/me/profile",
        json={"display_name": "Asha", "address": "123 Main Street"},
        headers=STUDENT,
    )
    assert r_addr.status_code == 422

    # Valid optional fields are accepted
    r_valid = client.put(
        "/v1/me/profile",
        json={
            "display_name": "Asha",
            "college": "PES University",
            "course": "Computer Science",
            "academic_year": "3rd Year / 6th Semester",
            "interests": ["python", "distributed systems"],
        },
        headers=STUDENT,
    )
    assert r_valid.status_code == 200
    data = r_valid.json()
    assert data["display_name"] == "Asha"
    assert data["college"] == "PES University"
    assert data["course"] == "Computer Science"
    assert data["academic_year"] == "3rd Year / 6th Semester"
    assert data["interests"] == ["python", "distributed systems"]


def test_tc_fr_prof_004_01_backend_validates_profile_fields(client):
    """TC-FR-PROF-004-01: Backend validates profile fields (type, length, allowed characters)

    and rejects invalid input with field-level messages.
    """
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )

    # 1. Invalid type for display_name (integer instead of string)
    r_type = client.put(
        "/v1/me/profile",
        json={"display_name": 12345},
        headers=STUDENT,
    )
    assert r_type.status_code == 422
    errors = r_type.json()["detail"]
    assert any("display_name" in str(err["loc"]) for err in errors)

    # 2. Invalid type for interests (string instead of list)
    r_list = client.put(
        "/v1/me/profile",
        json={"display_name": "Asha", "interests": "not-a-list"},
        headers=STUDENT,
    )
    assert r_list.status_code == 422
    assert any("interests" in str(err["loc"]) for err in r_list.json()["detail"])

    # 3. Invalid length: empty display_name
    r_empty = client.put(
        "/v1/me/profile",
        json={"display_name": ""},
        headers=STUDENT,
    )
    assert r_empty.status_code == 422
    assert any("display_name" in str(err["loc"]) for err in r_empty.json()["detail"])

    # 4. Invalid length: display_name exceeding 60 characters
    r_long = client.put(
        "/v1/me/profile",
        json={"display_name": "A" * 61},
        headers=STUDENT,
    )
    assert r_long.status_code == 422
    assert any("display_name" in str(err["loc"]) for err in r_long.json()["detail"])

    # 5. Invalid characters: script tags or forbidden characters in display_name
    r_chars = client.put(
        "/v1/me/profile",
        json={"display_name": "<script>alert('xss')</script>"},
        headers=STUDENT,
    )
    assert r_chars.status_code == 422
    assert any("display_name" in str(err["loc"]) for err in r_chars.json()["detail"])


def test_tc_fr_prof_005_01_profile_created_and_updated_for_authenticated_user(client):
    """TC-FR-PROF-005-01: Profile is created and updated for the authenticated user ID."""
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )

    r = client.put(
        "/v1/me/profile",
        json={"display_name": "Student A"},
        headers=STUDENT,
    )
    assert r.status_code == 200

    me_profile = client.get("/v1/me/profile", headers=STUDENT).json()
    assert me_profile["display_name"] == "Student A"


def test_tc_fr_prof_005_02_user_id_in_body_is_ignored(client):
    """TC-FR-PROF-005-02: User ID in body is ignored: Student A's profile changes;

    B's profile is unchanged.
    """
    # 1. Setup Student B's consent and profile
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=OTHER,
    )
    client.put(
        "/v1/me/profile",
        json={"display_name": "Student B Original"},
        headers=OTHER,
    )
    student_b_me = client.get("/v1/me", headers=OTHER).json()
    student_b_id = student_b_me["user_id"]

    # 2. Setup Student A's consent
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )

    # 3. Student A puts a profile with Student B's user_id in the body
    r_put = client.put(
        "/v1/me/profile",
        json={"user_id": student_b_id, "display_name": "Student A Modified"},
        headers=STUDENT,
    )
    assert r_put.status_code == 200

    # 4. Student A's profile changed
    prof_a = client.get("/v1/me/profile", headers=STUDENT).json()
    assert prof_a["display_name"] == "Student A Modified"

    # 5. Student B's profile is unchanged
    prof_b = client.get("/v1/me/profile", headers=OTHER).json()
    assert prof_b["display_name"] == "Student B Original"


def test_tc_fr_prof_006_01_student_reads_own_profile_and_records(client):
    """TC-FR-PROF-006-01: A student shall be able to read only their own profile and records;

    operator access shall require the operator role.
    """
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )
    client.put(
        "/v1/me/profile",
        json={"display_name": "Asha"},
        headers=STUDENT,
    )

    # Student reads own profile
    r_own = client.get("/v1/me/profile", headers=STUDENT)
    assert r_own.status_code == 200
    assert r_own.json()["display_name"] == "Asha"

    # Student cannot reach operator endpoints
    r_op = client.get(
        "/v1/operator/students/usr_some_id/profile",
        headers=STUDENT,
    )
    assert r_op.status_code == 403


def test_tc_fr_prof_006_02_cross_student_read_attempt(client):
    """TC-FR-PROF-006-02: Cross-student read attempt: As student A, request B's profile,

    attempts, submissions and results by ID. 403 or 404 on every request; no data returned;
    operator read as operator succeeds and creates an audit event.
    """
    # 1. Setup Student B with consent, profile, attempt, and submission
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=OTHER,
    )
    client.put(
        "/v1/me/profile",
        json={"display_name": "Student B", "college": "PES Tech"},
        headers=OTHER,
    )
    student_b_info = client.get("/v1/me", headers=OTHER).json()
    student_b_id = student_b_info["user_id"]

    # Student B creates an attempt and submission
    memory.LABS["lab-test-01"] = {"id": "lab-test-01", "version": 1}
    r_att = client.post("/v1/attempts", json={"lab_id": "lab-test-01"}, headers=OTHER)
    assert r_att.status_code == 201
    attempt_b_id = r_att.json()["id"]

    r_sub = client.post(f"/v1/attempts/{attempt_b_id}/submissions", headers=OTHER)
    assert r_sub.status_code == 201
    submission_b_id = r_sub.json()["id"]

    # 2. Setup Student A
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )

    # 3. Student A attempts to read Student B's profile by ID
    r_prof_direct = client.get(f"/v1/students/{student_b_id}/profile", headers=STUDENT)
    assert r_prof_direct.status_code in (403, 404)
    assert "Student B" not in r_prof_direct.text

    # Student A attempts to read via operator route
    r_prof_op = client.get(
        f"/v1/operator/students/{student_b_id}/profile",
        headers=STUDENT,
    )
    assert r_prof_op.status_code in (403, 404)
    assert "Student B" not in r_prof_op.text

    # 4. Student A attempts to read Student B's attempt
    r_att_cross = client.get(f"/v1/attempts/{attempt_b_id}", headers=STUDENT)
    assert r_att_cross.status_code in (403, 404)
    assert "lab-test-01" not in r_att_cross.text

    # 5. Student A attempts to read Student B's submission
    r_sub_cross = client.get(f"/v1/submissions/{submission_b_id}", headers=STUDENT)
    assert r_sub_cross.status_code in (403, 404)
    assert attempt_b_id not in r_sub_cross.text

    # 6. Operator read of Student B's profile succeeds and creates an audit event
    audit_count_before = len(audit.AUDIT)
    r_operator_read = client.get(
        f"/v1/operator/students/{student_b_id}/profile",
        headers=OPERATOR,
    )
    assert r_operator_read.status_code == 200
    assert r_operator_read.json()["display_name"] == "Student B"
    assert len(audit.AUDIT) > audit_count_before

    # Verify audit event details
    last_audit = audit.AUDIT[-1]
    assert last_audit["action"] in ("operator_read_profile", "read_profile")
    assert last_audit["target"] == student_b_id


def test_tc_fr_prof_007_01_profile_data_private_by_default(client):
    """TC-FR-PROF-007-01: Profile data is private by default and not visible to other students."""
    # Unauthenticated / anonymous read is rejected
    r_unauth = client.get("/v1/me/profile")
    assert r_unauth.status_code == 401

    # Student A cannot see Student B's profile
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=OTHER,
    )
    client.put(
        "/v1/me/profile",
        json={"display_name": "Private Student"},
        headers=OTHER,
    )
    other_id = client.get("/v1/me", headers=OTHER).json()["user_id"]

    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )
    r = client.get(f"/v1/students/{other_id}/profile", headers=STUDENT)
    assert r.status_code in (403, 404)
    assert "Private Student" not in r.text


def test_tc_fr_prof_008_01_student_views_and_edits_profile_after_onboarding(client):
    """TC-FR-PROF-008-01: A student shall be able to view and edit their profile after onboarding."""
    # Initial onboarding: consent and first profile creation
    client.put(
        "/v1/me/consent",
        json={"notice_version": "1.0", "age_check_passed": True},
        headers=STUDENT,
    )
    client.put(
        "/v1/me/profile",
        json={
            "display_name": "Asha Initial",
            "college": "College A",
            "course": "Engineering",
        },
        headers=STUDENT,
    )

    # View after onboarding
    view1 = client.get("/v1/me/profile", headers=STUDENT)
    assert view1.status_code == 200
    assert view1.json()["display_name"] == "Asha Initial"
    assert view1.json()["college"] == "College A"

    # Edit profile later
    edit_resp = client.put(
        "/v1/me/profile",
        json={
            "display_name": "Asha Updated",
            "college": "College B",
            "course": "Computer Science",
            "academic_year": "Final Year",
            "interests": ["rust", "compilers"],
        },
        headers=STUDENT,
    )
    assert edit_resp.status_code == 200

    # View again: updated values returned
    view2 = client.get("/v1/me/profile", headers=STUDENT)
    assert view2.status_code == 200
    data = view2.json()
    assert data["display_name"] == "Asha Updated"
    assert data["college"] == "College B"
    assert data["course"] == "Computer Science"
    assert data["academic_year"] == "Final Year"
    assert data["interests"] == ["rust", "compilers"]
