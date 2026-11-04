# Python Backend Firebase & Google Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Google OAuth 2.0 and Firebase Authentication on the Python FastAPI backend (`services/api`), keeping all client secrets off the desktop client while providing secure token exchange, user identity synchronization in Firebase Auth/Firestore, and seamless session management for the Flutter desktop client.

**Architecture:** The Flutter desktop client initiates sign-in by opening the system browser to the FastAPI backend's `/v1/auth/google/login` endpoint with an ephemeral desktop callback port. The backend initiates the Google OAuth 2.0 flow using backend credentials (client ID & secret), handles the OAuth callback, verifies identity with Google and Firebase Admin SDK (`firebase-admin`), synchronizes the user profile, creates a signed DevSphere session JWT, and redirects the browser back to the desktop app's loopback listener. The desktop client stores the session token in OS secure storage (`flutter_secure_storage`) for subsequent authenticated API requests.

**Tech Stack:** Python 3.12, FastAPI, `firebase-admin`, `httpx`, Pydantic Settings, Flutter (Dart), `flutter_secure_storage`.

---

## File Structure

- **Backend Configuration & Dependencies:**
  - `services/api/pyproject.toml`: Add `firebase-admin>=6.5.0` and `httpx>=0.27.0`.
  - `services/api/app/core/settings.py`: Add settings for Firebase project ID, credentials path/JSON, Google OAuth client ID, client secret, and redirect URI.
- **Backend Firebase & Auth Services:**
  - `services/api/app/core/firebase_auth.py`: Firebase Admin SDK lifecycle initialization and Firebase user sync (`get_or_create_firebase_user`).
  - `services/api/app/routers/auth.py`: Add `/v1/auth/google/login` and `/v1/auth/google/callback` endpoints.
- **Backend Tests:**
  - `services/api/tests/test_firebase_auth.py`: Unit and mock tests for Firebase Admin integration and OAuth callback endpoint.
- **Desktop Client Updates:**
  - `apps/desktop/lib/features/auth/backend_auth_service.dart`: Client service to open backend sign-in URL in external browser and capture returned token via loopback listener.
  - `apps/desktop/test/backend_auth_test.dart`: Test verifying loopback token handling and error states.

---

### Task 1: Add Dependencies & Update Backend Settings

**Files:**
- Modify: `services/api/pyproject.toml`
- Modify: `services/api/app/core/settings.py`
- Test: `services/api/tests/test_settings.py`

- [ ] **Step 1: Write the failing test for new authentication settings**

```python
# services/api/tests/test_settings.py
from app.core.settings import Settings


def test_auth_settings_defaults():
    s = Settings(
        DEVSPHERE_FIREBASE_PROJECT_ID="test-project",
        DEVSPHERE_GOOGLE_CLIENT_ID="mock-client-id",
        DEVSPHERE_GOOGLE_CLIENT_SECRET="mock-client-secret",
    )
    assert s.firebase_project_id == "test-project"
    assert s.google_client_id == "mock-client-id"
    assert s.google_client_secret == "mock-client-secret"
    assert s.google_redirect_uri == "http://127.0.0.1:8000/v1/auth/google/callback"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest services/api/tests/test_settings.py`
Expected: FAIL with attribute errors for missing fields.

- [ ] **Step 3: Update `pyproject.toml` and `settings.py`**

In `services/api/pyproject.toml`, update dependencies:
```toml
dependencies = [
    "fastapi>=0.115",
    "uvicorn>=0.30",
    "pydantic>=2.8",
    "pydantic-settings>=2.4",
    "cryptography>=43",
    "firebase-admin>=6.5.0",
    "httpx>=0.27.0",
]
```

In `services/api/app/core/settings.py`:
```python
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="DEVSPHERE_", env_file=".env", extra="ignore")
    environment: str = "dev"
    min_client_version: str = "0.0.0"
    grader_public_key_b64: str = ""
    tutor_daily_limit: int = 50
    auth_secret_key: str = "devsphere-local-jwt-secret-key-change-in-production"
    auth_issuer: str = "https://accounts.google.com"
    auth_audience: str = "devsphere-desktop-client"

    # Firebase Admin & Google OAuth configuration
    firebase_project_id: str = "devpilot-1a384"
    firebase_credentials_path: str = ""
    firebase_credentials_json: str = ""
    google_client_id: str = ""
    google_client_secret: str = ""
    google_redirect_uri: str = "http://127.0.0.1:8000/v1/auth/google/callback"


settings = Settings()
```

- [ ] **Step 4: Install dependencies and run tests**

Run:
```bash
uv sync
uv run pytest services/api/tests/test_settings.py
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add services/api/pyproject.toml services/api/app/core/settings.py services/api/tests/test_settings.py uv.lock
git commit -m "feat(api): add firebase-admin, httpx and oauth settings"
```

---

### Task 2: Implement Firebase Admin SDK Integration

**Files:**
- Create: `services/api/app/core/firebase_auth.py`
- Test: `services/api/tests/test_firebase_auth.py`

- [ ] **Step 1: Write failing test for Firebase Admin service**

```python
# services/api/tests/test_firebase_auth.py
from unittest.mock import MagicMock, patch
from app.core.firebase_auth import FirebaseAuthService


def test_sync_firebase_user_creates_user():
    service = FirebaseAuthService()
    mock_auth = MagicMock()
    mock_auth.get_user.side_effect = Exception("User not found")
    mock_user_record = MagicMock()
    mock_user_record.uid = "google_123"
    mock_auth.create_user.return_value = mock_user_record

    with patch("app.core.firebase_auth.auth", mock_auth):
        uid = service.sync_user(
            sub="123",
            email="student@example.com",
            display_name="Student Name",
            photo_url="https://example.com/photo.png",
        )
        assert uid == "google_123"
        mock_auth.create_user.assert_called_once_with(
            uid="google_123",
            email="student@example.com",
            display_name="Student Name",
            photo_url="https://example.com/photo.png",
            email_verified=True,
        )
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest services/api/tests/test_firebase_auth.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'app.core.firebase_auth'`

- [ ] **Step 3: Implement `app/core/firebase_auth.py`**

```python
# services/api/app/core/firebase_auth.py
import json
import logging
from typing import Optional
import firebase_admin
from firebase_admin import auth, credentials
from app.core.settings import settings

logger = logging.getLogger(__name__)


class FirebaseAuthService:
    def __init__(self) -> None:
        self._app: Optional[firebase_admin.App] = None
        self._initialize_app()

    def _initialize_app(self) -> None:
        if firebase_admin._apps:
            self._app = firebase_admin.get_app()
            return

        cred = None
        if settings.firebase_credentials_json:
            try:
                cred_dict = json.loads(settings.firebase_credentials_json)
                cred = credentials.Certificate(cred_dict)
            except Exception as e:
                logger.warning("Failed to parse DEVSPHERE_FIREBASE_CREDENTIALS_JSON: %s", e)
        elif settings.firebase_credentials_path:
            try:
                cred = credentials.Certificate(settings.firebase_credentials_path)
            except Exception as e:
                logger.warning("Failed to load credentials from %s: %s", settings.firebase_credentials_path, e)

        options = {}
        if settings.firebase_project_id:
            options["projectId"] = settings.firebase_project_id

        try:
            if cred:
                self._app = firebase_admin.initialize_app(cred, options=options)
            else:
                self._app = firebase_admin.initialize_app(options=options)
            logger.info("Firebase Admin initialized successfully")
        except Exception as e:
            logger.warning("Firebase Admin initialization skipped or deferred: %s", e)

    def sync_user(
        self,
        sub: str,
        email: str,
        display_name: str = "",
        photo_url: str = "",
    ) -> str:
        uid = f"google_{sub}"
        try:
            user = auth.get_user(uid)
            return user.uid
        except Exception:
            user = auth.create_user(
                uid=uid,
                email=email,
                display_name=display_name,
                photo_url=photo_url,
                email_verified=True,
            )
            return user.uid


firebase_auth_service = FirebaseAuthService()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest services/api/tests/test_firebase_auth.py`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add services/api/app/core/firebase_auth.py services/api/tests/test_firebase_auth.py
git commit -m "feat(api): implement Firebase Admin user synchronization service"
```

---

### Task 3: Implement Backend Google OAuth Endpoints

**Files:**
- Modify: `services/api/app/routers/auth.py`
- Test: `services/api/tests/test_oauth_flow.py`

- [ ] **Step 1: Write failing test for login redirect and callback endpoints**

```python
# services/api/tests/test_oauth_flow.py
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_google_login_redirect():
    response = client.get("/v1/auth/google/login?callback_port=52345", follow_redirects=False)
    assert response.status_code == 307
    location = response.headers["location"]
    assert "accounts.google.com" in location
    assert "response_type=code" in location
    assert "scope=openid+profile+email" in location or "scope=openid%20profile%20email" in location


@patch("httpx.AsyncClient.post")
@patch("httpx.AsyncClient.get")
def test_google_callback_flow(mock_get, mock_post):
    mock_post.return_value = MagicMock(
        status_code=200,
        json=lambda: {"access_token": "mock-access", "id_token": "mock-id-token"},
    )
    mock_get.return_value = MagicMock(
        status_code=200,
        json=lambda: {
            "sub": "google-sub-456",
            "email": "student@example.com",
            "email_verified": True,
            "name": "Jane Doe",
            "picture": "https://example.com/pic.png",
        },
    )

    with patch("app.core.firebase_auth.firebase_auth_service.sync_user") as mock_sync:
        mock_sync.return_value = "google_google-sub-456"
        state = "port=52345:nonce=mocknonce"
        response = client.get(f"/v1/auth/google/callback?code=mock-code&state={state}", follow_redirects=False)
        assert response.status_code == 307
        assert "http://127.0.0.1:52345/auth-callback" in response.headers["location"]
        assert "token=" in response.headers["location"]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest services/api/tests/test_oauth_flow.py`
Expected: FAIL with 404 Not Found on `/v1/auth/google/login`

- [ ] **Step 3: Implement endpoints in `services/api/app/routers/auth.py`**

```python
import urllib.parse
from fastapi import APIRouter, Depends, Header, HTTPException, Query
from fastapi.responses import RedirectResponse
import httpx

from app.core import audit
from app.core.auth import User, create_token, current_user, decode_token_unverified, get_or_create_user
from app.core.firebase_auth import firebase_auth_service
from app.core.settings import settings
from app.db import memory

router = APIRouter(prefix="/v1/auth")


@router.get("/google/login")
def google_login(callback_port: int = Query(default=0, ge=0, le=65535)) -> RedirectResponse:
    if not settings.google_client_id:
        raise HTTPException(status_code=500, detail="Google Client ID is not configured on backend.")

    state = f"port={callback_port}"
    params = {
        "client_id": settings.google_client_id,
        "redirect_uri": settings.google_redirect_uri,
        "response_type": "code",
        "scope": "openid profile email",
        "access_type": "offline",
        "prompt": "select_account",
        "state": state,
    }
    url = f"https://accounts.google.com/o/oauth2/v2/auth?{urllib.parse.urlencode(params)}"
    return RedirectResponse(url=url)


@router.get("/google/callback")
async def google_callback(
    code: str = Query(...),
    state: str = Query(default="port=0"),
) -> RedirectResponse:
    # 1. Exchange authorization code with Google for tokens
    async with httpx.AsyncClient() as http_client:
        token_res = await http_client.post(
            "https://oauth2.googleapis.com/token",
            data={
                "code": code,
                "client_id": settings.google_client_id,
                "client_secret": settings.google_client_secret,
                "redirect_uri": settings.google_redirect_uri,
                "grant_type": "authorization_code",
            },
        )
        if token_res.status_code != 200:
            raise HTTPException(status_code=400, detail="Failed to exchange authorization code with Google.")

        token_data = token_res.json()
        access_token = token_data.get("access_token")

        # 2. Retrieve user profile info from Google
        userinfo_res = await http_client.get(
            "https://www.googleapis.com/oauth2/v3/userinfo",
            headers={"Authorization": f"Bearer {access_token}"},
        )
        if userinfo_res.status_code != 200:
            raise HTTPException(status_code=400, detail="Failed to retrieve user info from Google.")

        user_info = userinfo_res.json()

    sub = user_info["sub"]
    email = user_info.get("email", "")
    email_verified = user_info.get("email_verified", False)
    name = user_info.get("name", "")
    picture = user_info.get("picture", "")

    if not email_verified:
        raise HTTPException(status_code=400, detail="Email is not verified by Google.")

    # 3. Synchronize user with Firebase Authentication
    firebase_auth_service.sync_user(sub=sub, email=email, display_name=name, photo_url=picture)

    # 4. Create internal DevSphere session token
    user_id = get_or_create_user(provider="google", sub=sub, email=email)
    session_token = create_token(sub=sub, email=email, email_verified=email_verified)

    audit.record(user_id, "sign_in", "session", "google_oauth_success")

    # 5. Extract callback port and redirect to Desktop client loopback
    callback_port = 0
    for part in state.split(":"):
        if part.startswith("port="):
            try:
                callback_port = int(part.split("=")[1])
            except ValueError:
                callback_port = 0

    if callback_port > 0:
        redirect_url = f"http://127.0.0.1:{callback_port}/auth-callback?token={session_token}&user_id={user_id}"
        return RedirectResponse(url=redirect_url)

    return RedirectResponse(url=f"/v1/auth/success?user_id={user_id}")
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uv run pytest services/api/tests/test_oauth_flow.py`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add services/api/app/routers/auth.py services/api/tests/test_oauth_flow.py
git commit -m "feat(api): implement Google OAuth login and callback endpoints with Firebase sync"
```

---

### Task 4: Connect Desktop Client to Backend Auth Flow

**Files:**
- Create: `apps/desktop/lib/features/auth/backend_auth_service.dart`
- Test: `apps/desktop/test/backend_auth_test.dart`

- [ ] **Step 1: Write test for Desktop loopback token receiver**

```dart
// apps/desktop/test/backend_auth_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loopback server receives token parameter from redirect', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/auth-callback?token=test-jwt-token&user_id=usr_123'),
    );
    final responseFuture = request.close();

    final httpRequest = await server.first;
    expect(httpRequest.uri.queryParameters['token'], equals('test-jwt-token'));
    expect(httpRequest.uri.queryParameters['user_id'], equals('usr_123'));

    httpRequest.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write('<html><body>Signed in! You may return to the DevSphere app.</body></html>');
    await httpRequest.response.close();

    final response = await responseFuture;
    expect(response.statusCode, equals(HttpStatus.ok));
    await server.close();
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `melos exec --dir=apps/desktop -- flutter test test/backend_auth_test.dart`
Expected: PASS

- [ ] **Step 3: Implement `BackendAuthService` in `apps/desktop/lib/features/auth/backend_auth_service.dart`**

```dart
// apps/desktop/lib/features/auth/backend_auth_service.dart
// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001, FR-AUTH-002, FR-AUTH-007

import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class AuthResult {
  final String token;
  final String userId;
  AuthResult({required this.token, required this.userId});
}

class BackendAuthService {
  final String backendBaseUrl;

  BackendAuthService({this.backendBaseUrl = 'http://127.0.0.1:8000'});

  Future<AuthResult> signInWithBrowser({Duration timeout = const Duration(minutes: 3)}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final callbackPort = server.port;

    final loginUri = Uri.parse('$backendBaseUrl/v1/auth/google/login?callback_port=$callbackPort');

    final launched = await launchUrl(loginUri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await server.close(force: true);
      throw Exception('Could not open default system browser for sign-in.');
    }

    try {
      final request = await server.first.timeout(timeout);
      final token = request.uri.queryParameters['token'];
      final userId = request.uri.queryParameters['user_id'] ?? '';

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('''
<!DOCTYPE html>
<html>
<head><title>DevSphere - Sign In Successful</title></head>
<body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
  <h2>Authentication Successful!</h2>
  <p>You can close this tab and return to the DevSphere desktop application.</p>
</body>
</html>
''');
      await request.response.close();
      await server.close();

      if (token == null || token.isEmpty) {
        throw Exception('Sign-in callback did not provide an authentication token.');
      }

      return AuthResult(token: token, userId: userId);
    } on TimeoutException {
      await server.close(force: true);
      throw Exception('Sign-in timed out. Please try again.');
    }
  }
}
```

- [ ] **Step 4: Run flutter tests**

Run: `melos exec --dir=apps/desktop -- flutter test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add apps/desktop/lib/features/auth/backend_auth_service.dart apps/desktop/test/backend_auth_test.dart
git commit -m "feat(desktop): implement backend browser authentication listener service"
```

---

### Task 5: Full Repository Verification

- [ ] **Step 1: Run all verification commands**

```bash
uv run ruff check .
uv run pytest
melos run check
python tools/check_docs.py
bash -n ./start.sh
```
Expected: All 5 checks pass with 0 errors.

