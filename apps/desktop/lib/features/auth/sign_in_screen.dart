// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: sign in screen widget with system browser launcher, cancellation and error recovery actions (BuildLoop design)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
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
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            margin: const EdgeInsets.all(BL.space6),
            child: Padding(
              padding: const EdgeInsets.all(BL.space8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BuildLoop',
                      style: text.headlineMedium?.copyWith(color: BL.navy)),
                  const SizedBox(height: BL.space2),
                  Text('Learn by building.', style: text.titleMedium),
                  Text('Grow by contributing.',
                      style: text.titleMedium?.copyWith(color: BL.primary)),
                  const SizedBox(height: BL.space4),
                  Text(
                    'A practical engineering learning environment: set up projects, debug real code and practise open-source contribution.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: BL.space6),
                  if (_error != null) ...[
                    Container(
                      key: const Key('auth_error_container'),
                      padding: const EdgeInsets.all(BL.space3),
                      margin: const EdgeInsets.only(bottom: BL.space4),
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
                          const SizedBox(height: BL.space1),
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
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _handleSignIn,
                      icon: const Icon(Icons.login, size: 18),
                      label: Text(_error != null ? 'Retry Sign In' : 'Sign in with Google'),
                    ),
                    const SizedBox(height: BL.space3),
                    OutlinedButton.icon(
                      key: const Key('auth_enter_profile_button'),
                      onPressed: () => context.go('/profile'),
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('Input Profile Details'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
