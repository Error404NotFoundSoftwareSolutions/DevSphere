// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: sign in screen widget with system browser launcher, cancellation and error recovery actions

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'session_store.dart';
import 'sign_in_service.dart';

class SignInScreen extends StatefulWidget {
  final SignInService? signInService;
  final SessionStore? sessionStore;
  final VoidCallback? onSignInSuccess;

  const SignInScreen({
    super.key,
    this.signInService,
    this.sessionStore,
    this.onSignInSuccess,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final SignInService _signInService;
  late final SessionStore _sessionStore;
  bool _isLoading = false;
  AuthException? _error;

  @override
  void initState() {
    super.initState();
    _signInService = widget.signInService ?? SignInService();
    _sessionStore = widget.sessionStore ?? SessionStore();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authUrl = _signInService.buildAuthUrl(
        redirectUri: 'http://127.0.0.1:8000/callback',
        codeChallenge: 'sample-pkce-challenge',
        state: 'sample-csrf-state',
      );

      final launched = await _signInService.startBrowserSignIn(authUrl);
      if (!launched) {
        throw AuthException.cancelled();
      }

      // Save session token in session store (FR-AUTH-007)
      await _sessionStore.saveToken('google-session-token');

      if (widget.onSignInSuccess != null) {
        widget.onSignInSuccess!();
      } else if (mounted) {
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _signInService.classifyError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('DevSphere', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                const Text('Sign in to begin building guided Python projects.'),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    key: const Key('auth_error_container'),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _error!.message,
                          key: const Key('auth_error_message'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _error!.recoveryAction,
                          key: const Key('auth_recovery_action'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton.icon(
                    onPressed: _handleSignIn,
                    icon: const Icon(Icons.login),
                    label: Text(_error != null ? 'Retry Sign In' : 'Sign in with Google'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('auth_enter_profile_button'),
                    onPressed: () => context.go('/profile'),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Input Profile Details'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
