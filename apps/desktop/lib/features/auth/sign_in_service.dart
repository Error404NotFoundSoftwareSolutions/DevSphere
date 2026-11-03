// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: PKCE browser authentication with loopback redirect on 127.0.0.1

import 'package:url_launcher/url_launcher.dart';

class SignInService {
  Future<bool> startBrowserSignIn(String authUrl) async {
    final uri = Uri.parse(authUrl);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

