// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: the sign-in and create-account screen. A split layout: a deep-blue brand panel that shows what DevPilot
// does (four short, honest slides with small product previews) and a clean form with tabs, floating labels, a password
// strength meter, inline errors, forgot-password and terms dialogs. Light and dark. All sign-in logic is unchanged.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../data/app_prefs.dart';
import '../../ui/brand_mark.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../../services/google_token_exchange.dart';
import '../../services/oauth_loopback_server.dart';
import 'firebase_auth_service.dart';
import 'auth_session.dart';
import 'session_store.dart';
import 'sign_in_service.dart';

/// The accent used on the deep-blue card (white text sits on it in both themes).
const _cardAccent = Color(0xFF9DBBFF);

class SignInScreen extends StatefulWidget {
  final SignInService? signInService;
  final FirebaseAuthService? firebaseAuthService;
  final SessionStore? sessionStore;
  final VoidCallback? onSignInSuccess;
  final bool autoLaunch;
  final bool initialCreateAccount;

  const SignInScreen({
    super.key,
    this.signInService,
    this.firebaseAuthService,
    this.sessionStore,
    this.onSignInSuccess,
    this.autoLaunch = false,
    this.initialCreateAccount = true,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final SignInService _signInService;
  late final FirebaseAuthService _firebaseAuthService;
  late final SessionStore _sessionStore;
  bool _isLoading = false;
  AuthException? _error;
  late bool _isCreateAccount;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = true;
  int _currentSlide = 0;
  final ValueNotifier<Offset> _gaze = ValueNotifier(Offset.zero);
  bool _passwordFocused = false;
  Timer? _slideTimer;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _isCreateAccount = widget.initialCreateAccount;
    _signInService = widget.signInService ?? SignInService();
    _firebaseAuthService = widget.firebaseAuthService ?? FirebaseAuthService();
    _sessionStore = widget.sessionStore ?? SessionStore.app;
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _slideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() {
            _currentSlide = (_currentSlide + 1) % _slides.length;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SignInScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCreateAccount != oldWidget.initialCreateAccount) {
      setState(() {
        _isCreateAccount = widget.initialCreateAccount;
      });
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _gaze.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // If the client ID is still the placeholder, we cannot do a real OAuth flow.
      // Show a helpful setup message instead of silently failing.
      if (_signInService.isPlaceholderClientId) {
        throw const AuthException(
          type: AuthErrorType.unknown,
          message: 'Google Sign-In is not configured yet.',
          recoveryAction:
              'Ask the developer to set up a real OAuth 2.0 Client ID in Google Cloud Console.',
        );
      }

      // --- Step 1: Generate PKCE parameters ---
      final codeVerifier = PkceHelper.generateCodeVerifier();
      final challenge = PkceHelper.codeChallenge(codeVerifier);
      final state = PkceHelper.generateState();

      // --- Step 2: Start loopback server BEFORE opening the browser ---
      const redirectUri = 'http://127.0.0.1:8000/callback';
      final loopback = OAuthLoopbackServer(port: 8000);

      // --- Step 3: Build URL and open system browser ---
      final authUrl = _signInService.buildAuthUrl(
        redirectUri: redirectUri,
        codeChallenge: challenge,
        state: state,
      );
      final launched = await _signInService.startBrowserSignIn(authUrl);
      if (!launched) {
        throw AuthException.cancelled();
      }

      // --- Step 4: Wait for the authorization code from Google redirect ---
      final code = await loopback.waitForCode(
        timeout: const Duration(minutes: 5),
      );

      // --- Step 5: Exchange code + verifier for Google ID token ---
      final tokenExchange = GoogleTokenExchange();
      final googleIdToken = await tokenExchange.exchangeCodeForIdToken(
        code: code,
        codeVerifier: codeVerifier,
        clientId: _signInService.clientId,
        redirectUri: redirectUri,
      );

      // --- Step 6: Sign in with Firebase using the Google ID token ---
      final result = await _firebaseAuthService.signInWithGoogle(
        googleIdToken: googleIdToken,
      );
      if (result.idToken.isEmpty) {
        throw AuthException.cancelled();
      }

      // --- Step 7: Save Firebase session token ---
      await _sessionStore.saveToken(result.idToken);
      AuthSession.instance.signIn(AuthUser.fromFirebase(result));

      if (widget.onSignInSuccess != null) {
        widget.onSignInSuccess!();
      } else if (mounted) {
        context.go('/dashboard');
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

  Future<void> _handleEmailSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = const AuthException(
          type: AuthErrorType.unknown,
          message: 'Please enter a valid email address.',
          recoveryAction: 'Enter your email in the format name@example.com.',
        );
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _error = const AuthException(
          type: AuthErrorType.unknown,
          message: 'Password must be at least 6 characters.',
          recoveryAction: 'Please enter a password with 6 or more characters.',
        );
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _error = const AuthException(
          type: AuthErrorType.unknown,
          message: 'Passwords do not match.',
          recoveryAction: 'Please ensure both passwords match.',
        );
      });
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _error = const AuthException(
          type: AuthErrorType.unknown,
          message: 'Terms & Conditions agreement required.',
          recoveryAction:
              'Please check the box to agree to the Terms & Conditions.',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userResult = await _firebaseAuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userResult.idToken.isEmpty) {
        throw const AuthException(
          type: AuthErrorType.unknown,
          message: 'Failed to create user account.',
          recoveryAction: 'Please try signing up again.',
        );
      }

      await _sessionStore.saveToken(userResult.idToken);
      AuthSession.instance.signIn(AuthUser.fromFirebase(userResult));

      if (widget.onSignInSuccess != null) {
        widget.onSignInSuccess!();
      } else if (mounted) {
        context.go('/dashboard');
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

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = const AuthException(
          type: AuthErrorType.unknown,
          message: 'Please enter a valid email address.',
          recoveryAction: 'Enter your email in the format name@example.com.',
        );
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _error = const AuthException(
          type: AuthErrorType.unknown,
          message: 'Please enter your password.',
          recoveryAction: 'Enter your password to sign in.',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userResult = await _firebaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userResult.idToken.isEmpty) {
        throw const AuthException(
          type: AuthErrorType.unknown,
          message: 'Failed to sign in.',
          recoveryAction: 'Please check your login credentials and try again.',
        );
      }

      await _sessionStore.saveToken(userResult.idToken);
      AuthSession.instance.signIn(AuthUser.fromFirebase(userResult));

      if (widget.onSignInSuccess != null) {
        widget.onSignInSuccess!();
      } else if (mounted) {
        context.go('/dashboard');
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

  // ---------------------------------------------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------------------------------------------

  void _setMode(bool create) {
    if (_isLoading || create == _isCreateAccount) return;
    setState(() {
      _isCreateAccount = create;
      _error = null;
    });
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/landing');
    }
  }

  void _submit() {
    if (_isLoading) return;
    _isCreateAccount ? _handleEmailSignUp() : _handleEmailSignIn();
  }

  Future<void> _showTerms() {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BL.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconTile(
                      icon: Icons.shield_outlined,
                      tint: BL.tintBlue,
                      color: BL.blue,
                      size: 36),
                  const SizedBox(width: BL.space3),
                  Expanded(
                      child: Text('Terms and privacy, in short',
                          style: Theme.of(context).textTheme.titleLarge)),
                ]),
                const SizedBox(height: BL.space4),
                const _TermsPoint(
                    'Your account email and name identify your progress, roadmaps and credentials. Each person only sees their own.'),
                const _TermsPoint(
                    'Labs run on your own computer. AI features send what you type to the DevPilot service, which asks Google Gemini.'),
                const _TermsPoint(
                    'Badges are only issued from results the server has verified. Practice labs written by AI never give a badge.'),
                const _TermsPoint(
                    'The full legal text will be published before the public launch.'),
                const SizedBox(height: BL.space4),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showForgotPassword() {
    return showDialog<void>(
      context: context,
      builder: (context) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        send: (email) async {
          try {
            await _firebaseAuthService.sendPasswordReset(email: email);
          } catch (e) {
            throw e is AuthException ? e : _signInService.classifyError(e);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('auth_screen'),
      backgroundColor: BL.background,
      body: MouseRegion(
        onHover: (e) {
          final size = MediaQuery.sizeOf(context);
          _gaze.value = Offset((e.position.dx / size.width - 0.35) * 2,
              (e.position.dy / size.height - 0.4) * 2);
        },
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 900;
          if (!wide) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: BL.space4, vertical: BL.space4),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _buildFormColumn(compact: true),
                  ),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(BL.space4),
            child: Row(children: [
              Expanded(
                flex: 11,
                child: _BrandPanel(
                  slides: _slides,
                  index: _currentSlide,
                  animate: !_isTest,
                  onSelect: (i) => setState(() => _currentSlide = i),
                  mascot: _PilotMascot(
                    key: const Key('auth_mascot'),
                    gaze: _gaze,
                    hideEyes: _passwordFocused,
                    worried: _error != null,
                    animate: !_isTest,
                  ),
                ),
              ),
              Expanded(
                flex: 10,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: BL.space8, vertical: BL.space4),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildFormColumn(compact: false),
                    ),
                  ),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _buildFormColumn({required bool compact}) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Reveal(
          child: Row(children: [
            IconButton(
              key: const Key('auth_back_button'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to website',
              onPressed: _goBack,
            ),
            if (compact) ...[
              const SizedBox(width: BL.space2),
              BrandMark(key: const Key('auth_logo_image'), size: 32),
              const SizedBox(width: BL.space2),
              Text('DevPilot', style: text.titleMedium),
            ],
            const Spacer(),
            const _ThemeToggle(),
          ]),
        ),
        SizedBox(height: compact ? BL.space4 : BL.space6),
        Reveal(
          index: 1,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Column(
              key: ValueKey(_isCreateAccount),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCreateAccount ? 'Create an account' : 'Welcome back',
                  key: const Key('auth_screen_title'),
                  style: text.headlineMedium,
                ),
                const SizedBox(height: BL.space1),
                Text(
                  _isCreateAccount
                      ? 'Start with a guided lab. It takes a few minutes.'
                      : 'Sign in to pick up your labs, roadmap and badges.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: BL.space6),
        Reveal(
          index: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: PillTabs(
              labels: const ['Sign up', 'Sign in'],
              selected: _isCreateAccount ? 0 : 1,
              enabled: !_isLoading,
              onChanged: (i) => _setMode(i == 0),
            ),
          ),
        ),
        const SizedBox(height: BL.space4),
        Reveal(index: 3, child: _buildGoogleButton()),
        const SizedBox(height: BL.space4),
        Reveal(index: 3, child: const _OrDivider()),
        const SizedBox(height: BL.space4),
        Reveal(index: 4, child: _buildFields()),
        _buildError(),
        const SizedBox(height: BL.space4),
        Reveal(index: 5, child: _buildSubmit()),
        const SizedBox(height: BL.space4),
        Reveal(
          index: 6,
          child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                    _isCreateAccount
                        ? 'Already have an account? '
                        : "Don't have an account? ",
                    style: text.bodySmall),
                InkWell(
                  key: const Key('auth_switch_mode_button'),
                  borderRadius: BorderRadius.circular(BL.radiusSm),
                  onTap: _isLoading ? null : () => _setMode(!_isCreateAccount),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      _isCreateAccount ? 'Sign in' : 'Create account',
                      style: text.bodySmall?.copyWith(
                          color: BL.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ]),
        ),
        const SizedBox(height: BL.space2),
        Reveal(
          index: 6,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_outline, size: 13, color: BL.textDisabled),
            const SizedBox(width: 6),
            Flexible(
                child: Text('Sign-in is handled by Google Firebase.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall
                        ?.copyWith(fontSize: 11.5, color: BL.textDisabled))),
          ]),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        key: const Key('auth_google_button'),
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: BL.surface,
          side: BorderSide(
              color: _error != null
                  ? BL.danger.withValues(alpha: 0.5)
                  : BL.borderStrong),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const _GoogleColorIcon(size: 18),
          const SizedBox(width: BL.space3),
          Flexible(
            child: Text(
              _error != null ? 'Retry Sign In' : 'Sign in with Google',
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: BL.textPrimary),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFields() {
    final create = _isCreateAccount;
    final pw = _passwordController.text;
    final mismatch = create &&
        _confirmPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text != pw;
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Collapse(
        show: create,
        child: Padding(
          padding: const EdgeInsets.only(bottom: BL.space3),
          child: Row(children: [
            Expanded(
              child: _AuthField(
                fieldKey: const Key('auth_first_name_field'),
                controller: _firstNameController,
                label: 'First name',
                icon: Icons.person_outline,
                enabled: !_isLoading,
                action: TextInputAction.next,
              ),
            ),
            const SizedBox(width: BL.space3),
            Expanded(
              child: _AuthField(
                fieldKey: const Key('auth_last_name_field'),
                controller: _lastNameController,
                label: 'Last name',
                icon: Icons.badge_outlined,
                enabled: !_isLoading,
                action: TextInputAction.next,
              ),
            ),
          ]),
        ),
      ),
      _AuthField(
        fieldKey: const Key('auth_email_field'),
        controller: _emailController,
        label: 'Email address',
        icon: Icons.mail_outline,
        enabled: !_isLoading,
        keyboard: TextInputType.emailAddress,
        action: TextInputAction.next,
      ),
      const SizedBox(height: BL.space3),
      _AuthField(
        fieldKey: const Key('auth_password_field'),
        onFocus: (f) => setState(() => _passwordFocused = f),
        controller: _passwordController,
        label: 'Password',
        icon: Icons.lock_outline,
        enabled: !_isLoading,
        obscure: !_isPasswordVisible,
        onChanged: (_) => setState(() {}),
        action: create ? TextInputAction.next : TextInputAction.done,
        onSubmitted: create ? null : (_) => _submit(),
        suffix: _VisibilityButton(
          visible: _isPasswordVisible,
          onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      _Collapse(
        show: create && pw.isNotEmpty,
        child: Padding(
          padding: const EdgeInsets.only(top: BL.space2),
          child: _StrengthMeter(password: pw),
        ),
      ),
      _Collapse(
        show: create,
        child: Padding(
          padding: const EdgeInsets.only(top: BL.space3),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _AuthField(
              fieldKey: const Key('auth_confirm_password_field'),
              onFocus: (f) => setState(() => _passwordFocused = f),
              controller: _confirmPasswordController,
              label: 'Confirm password',
              icon: Icons.verified_user_outlined,
              enabled: !_isLoading,
              obscure: !_isConfirmPasswordVisible,
              onChanged: (_) => setState(() {}),
              action: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              invalid: mismatch,
              suffix: _VisibilityButton(
                visible: _isConfirmPasswordVisible,
                onTap: () => setState(() =>
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ),
            _Collapse(
              show: mismatch,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Row(children: [
                  Icon(Icons.error_outline, size: 14, color: BL.danger),
                  const SizedBox(width: 6),
                  Text('The two passwords are different.',
                      style: text.bodySmall
                          ?.copyWith(color: BL.danger, fontSize: 12)),
                ]),
              ),
            ),
            const SizedBox(height: BL.space3),
            Row(children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  key: const Key('auth_terms_checkbox'),
                  value: _agreedToTerms,
                  onChanged: _isLoading
                      ? null
                      : (v) => setState(() => _agreedToTerms = v ?? true),
                ),
              ),
              const SizedBox(width: BL.space2),
              Expanded(
                child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('I agree to the ', style: text.bodySmall),
                      InkWell(
                        onTap: _showTerms,
                        child: Text('terms and privacy notes',
                            style: text.bodySmall?.copyWith(
                                color: BL.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
              ),
            ]),
          ]),
        ),
      ),
      _Collapse(
        show: !create,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton(
              key: const Key('auth_forgot_password_button'),
              onPressed: _isLoading ? null : _showForgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildError() {
    final err = _error;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, a) => SizeTransition(
        sizeFactor: a,
        axisAlignment: -1,
        child: FadeTransition(opacity: a, child: child),
      ),
      child: err == null
          ? const SizedBox.shrink(key: ValueKey('no-error'))
          : Padding(
              key: ValueKey('${err.message}|${err.recoveryAction}'),
              padding: const EdgeInsets.only(top: BL.space4),
              child: Container(
                key: const Key('auth_error_container'),
                padding: const EdgeInsets.all(BL.space3),
                decoration: BoxDecoration(
                  color: BL.tintRose,
                  borderRadius: BorderRadius.circular(BL.radiusMd),
                  border: Border.all(color: BL.danger.withValues(alpha: 0.45)),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 18, color: BL.danger),
                      const SizedBox(width: BL.space3),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(err.message,
                                  key: const Key('auth_error_message'),
                                  style: TextStyle(
                                      color: BL.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5)),
                              const SizedBox(height: 2),
                              Text(err.recoveryAction,
                                  key: const Key('auth_recovery_action'),
                                  style: TextStyle(
                                      color: BL.textSecondary, fontSize: 12.5)),
                            ]),
                      ),
                      InkWell(
                        onTap: () => setState(() => _error = null),
                        child: Icon(Icons.close,
                            size: 16, color: BL.textSecondary),
                      ),
                    ]),
              ),
            ),
    );
  }

  Widget _buildSubmit() {
    return SizedBox(
      height: 46,
      child: FilledButton(
        key: const Key('auth_submit_button'),
        onPressed: _isLoading ? null : _submit,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isLoading
              ? SizedBox(
                  key: const ValueKey('busy'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: BL.onPrimary),
                )
              : Row(
                  key: ValueKey(_isCreateAccount),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isCreateAccount ? 'Create account' : 'Sign in'),
                    const SizedBox(width: BL.space2),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
        ),
      ),
    );
  }

  late final List<_SlideData> _slides = const [
    _SlideData(
      icon: Icons.terminal,
      title: 'Guided labs, right in VS Code',
      body:
          'Each lab is a short project with steps, starter files and a check you can run yourself.',
      preview: _LabPreview(),
    ),
    _SlideData(
      icon: Icons.chat_bubble_outline,
      title: 'A tutor that gives hints, not answers',
      body:
          'Ask in your own language. The tutor answers in 9 languages and nudges you towards the fix.',
      preview: _TutorPreview(),
    ),
    _SlideData(
      icon: Icons.fact_check_outlined,
      title: 'Checks that read your real Git work',
      body:
          'Branches, commits and conflicts are inspected in your actual repository, not a quiz.',
      preview: _CheckPreview(),
    ),
    _SlideData(
      icon: Icons.workspace_premium_outlined,
      title: 'Badges you can stand behind',
      body:
          'A badge is only issued from a result the server has verified. Practice labs never award one.',
      preview: _BadgePreview(),
    ),
  ];

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');
}

// -----------------------------------------------------------------------------------------------------------------
// Pieces
// -----------------------------------------------------------------------------------------------------------------

class _TermsPoint extends StatelessWidget {
  const _TermsPoint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: BL.space3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 16, color: BL.success),
          ),
          const SizedBox(width: BL.space3),
          Expanded(
              child: Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.45))),
        ]),
      );
}

/// Shows [child] when [show] is true, growing and fading in; shrinks away when it is false.
class _Collapse extends StatelessWidget {
  const _Collapse({required this.show, required this.child});
  final bool show;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (c, a) => SizeTransition(
            sizeFactor: a,
            axisAlignment: -1,
            child: FadeTransition(opacity: a, child: c)),
        child: show
            ? KeyedSubtree(key: const ValueKey('shown'), child: child)
            : const SizedBox.shrink(key: ValueKey('hidden')),
      );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Rule()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BL.space3),
          child: Text('or use your email',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 12)),
        ),
        const Expanded(child: Rule()),
      ]);
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.visible, required this.onTap});
  final bool visible;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: visible ? 'Hide password' : 'Show password',
        splashRadius: 18,
        icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18),
        onPressed: onTap,
      );
}

class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.obscure = false,
    this.suffix,
    this.keyboard,
    this.action,
    this.onChanged,
    this.onSubmitted,
    this.invalid = false,
    this.onFocus,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool invalid;
  final ValueChanged<bool>? onFocus;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() {});
      widget.onFocus?.call(_focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final color =
        widget.invalid ? BL.danger : (focused ? BL.primary : BL.textSecondary);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(BL.radiusMd),
        borderSide: BorderSide(color: c, width: w));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BL.radiusMd),
        boxShadow: focused
            ? [
                BoxShadow(
                    color: BL.primary.withValues(alpha: 0.16),
                    blurRadius: 0,
                    spreadRadius: 3)
              ]
            : const [],
      ),
      child: TextField(
        key: widget.fieldKey,
        controller: widget.controller,
        focusNode: _focus,
        enabled: widget.enabled,
        obscureText: widget.obscure,
        keyboardType: widget.keyboard,
        textInputAction: widget.action,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: TextStyle(color: BL.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: color, fontSize: 14),
          floatingLabelStyle: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w600),
          prefixIcon: Icon(widget.icon, size: 18, color: color),
          suffixIcon: widget.suffix,
          filled: true,
          fillColor: BL.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: BL.space3, vertical: 15),
          enabledBorder: border(widget.invalid ? BL.danger : BL.borderStrong),
          focusedBorder: border(widget.invalid ? BL.danger : BL.primary, 1.5),
          disabledBorder: border(BL.border),
          border: border(BL.borderStrong),
        ),
      ),
    );
  }
}

/// 0 (empty) .. 4 (strong)
int passwordStrength(String p) {
  if (p.isEmpty) return 0;
  var s = 0;
  if (p.length >= 8) s++;
  if (p.length >= 12) s++;
  if (RegExp(r'[a-z]').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p)) s++;
  if (RegExp(r'\d').hasMatch(p) && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
  if (p.length < 6) return 1;
  return s.clamp(1, 4);
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});
  final String password;
  @override
  Widget build(BuildContext context) {
    final s = passwordStrength(password);
    const labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
    final colors = [BL.border, BL.danger, BL.warning, BL.info, BL.success];
    return Row(key: const Key('auth_strength_meter'), children: [
      for (var i = 1; i <= 4; i++) ...[
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 4,
            decoration: BoxDecoration(
                color: i <= s ? colors[s] : BL.border,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        if (i < 4) const SizedBox(width: 4),
      ],
      const SizedBox(width: BL.space3),
      SizedBox(
        width: 48,
        child: Text(labels[s],
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: colors[s])),
      ),
    ]);
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();
  @override
  Widget build(BuildContext context) {
    // The screen also works without an app-wide provider scope (in small tests), so the switch hides itself there.
    if (context.getInheritedWidgetOfExactType<UncontrolledProviderScope>() ==
        null) return const SizedBox.shrink();
    return Consumer(builder: (context, ref, _) {
      final dark = ref.watch(themeDarkProvider);
      return IconButton(
        key: const Key('auth_theme_toggle'),
        tooltip:
            dark ? 'Switch to the light theme' : 'Switch to the dark theme',
        icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        onPressed: () => ref.read(themeDarkProvider.notifier).toggle(),
      );
    });
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail, required this.send});
  final String initialEmail;
  final Future<void> Function(String email) send;
  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  bool _sent = false;
  String? _problem;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
          () => _problem = 'Enter your email in the format name@example.com.');
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      await widget.send(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted)
        setState(() => _problem = e is AuthException
            ? '${e.message} ${e.recoveryAction}'
            : 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BL.space6),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            alignment: Alignment.topCenter,
            child: _sent
                ? Column(
                    key: const Key('reset-sent'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        IconTile(
                            icon: Icons.mark_email_read_outlined,
                            tint: BL.tintTeal,
                            color: BL.teal,
                            size: 44),
                        const SizedBox(height: BL.space4),
                        Text('Check your inbox', style: text.titleLarge),
                        const SizedBox(height: BL.space2),
                        Text(
                            'If an account exists for that address, a link to choose a new password is on its way. It can take a minute.',
                            style: text.bodySmall),
                        const SizedBox(height: BL.space6),
                        Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Done'))),
                      ])
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        IconTile(
                            icon: Icons.lock_reset,
                            tint: BL.tintBlue,
                            color: BL.blue,
                            size: 44),
                        const SizedBox(height: BL.space4),
                        Text('Reset your password', style: text.titleLarge),
                        const SizedBox(height: BL.space2),
                        Text(
                            'Enter the email you signed up with and we will send a reset link.',
                            style: text.bodySmall),
                        const SizedBox(height: BL.space4),
                        _AuthField(
                          fieldKey: const Key('reset-email-field'),
                          controller: _email,
                          label: 'Email address',
                          icon: Icons.mail_outline,
                          enabled: !_busy,
                          keyboard: TextInputType.emailAddress,
                          action: TextInputAction.done,
                          onSubmitted: (_) => _go(),
                        ),
                        if (_problem != null) ...[
                          const SizedBox(height: BL.space2),
                          Text(_problem!,
                              key: const Key('reset-problem'),
                              style:
                                  TextStyle(color: BL.danger, fontSize: 12.5)),
                        ],
                        const SizedBox(height: BL.space6),
                        Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: BL.space2,
                            children: [
                              TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: const Text('Cancel')),
                              FilledButton(
                                key: const Key('reset-send'),
                                onPressed: _busy ? null : _go,
                                child: _busy
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: BL.onPrimary))
                                    : const Text('Send reset link'),
                              ),
                            ]),
                      ]),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------------------------------------------
// Brand panel
// -----------------------------------------------------------------------------------------------------------------

class _SlideData {
  const _SlideData(
      {required this.icon,
      required this.title,
      required this.body,
      required this.preview});
  final IconData icon;
  final String title;
  final String body;
  final Widget preview;
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel(
      {required this.slides,
      required this.index,
      required this.onSelect,
      required this.animate,
      required this.mascot});
  final Widget mascot;
  final List<_SlideData> slides;
  final int index;
  final ValueChanged<int> onSelect;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final slide = slides[index];
    final white = Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        key: const Key('auth_brand_panel'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [BL.heroStart, BL.heroEnd]),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
          Positioned(
            right: -120,
            top: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cardAccent.withValues(alpha: 0.14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Reveal(
                child: Row(children: [
                  const BrandMark(
                      key: Key('auth_logo_image'), size: 40, onDark: true),
                  const SizedBox(width: BL.space3),
                  Text('DevPilot',
                      style: TextStyle(
                          color: white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3)),
                ]),
              ),
              Expanded(
                  child: Center(
                      child: FittedBox(fit: BoxFit.scaleDown, child: mascot))),
              SizedBox(
                height: 250,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: animate ? 420 : 1),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0.04, 0), end: Offset.zero)
                            .animate(a),
                        child: child),
                  ),
                  child: Align(
                    key: ValueKey(index),
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: slide.preview),
                  ),
                ),
              ),
              const SizedBox(height: BL.space8),
              AnimatedSwitcher(
                duration: Duration(milliseconds: animate ? 300 : 1),
                child: Column(
                  key: ValueKey('t$index'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slide.title,
                        key: const Key('auth_slide_title'),
                        style: TextStyle(
                            color: white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.2)),
                    const SizedBox(height: BL.space2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Text(slide.body,
                          style: TextStyle(
                              color: white.withValues(alpha: 0.78),
                              fontSize: 14.5,
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BL.space6),
              Row(children: [
                for (var i = 0; i < slides.length; i++)
                  GestureDetector(
                    key: Key('auth_slide_dot_$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                      child: _SlideDot(active: i == index, animate: animate),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SlideDot extends StatelessWidget {
  const _SlideDot({required this.active, required this.animate});
  final bool active;
  final bool animate;
  @override
  Widget build(BuildContext context) {
    final w = active ? 36.0 : 8.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: w,
      height: 6,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 0.28 : 0.3),
          borderRadius: BorderRadius.circular(3)),
      child: active
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: animate ? 0 : 1, end: 1),
              duration: Duration(milliseconds: animate ? 5000 : 1),
              builder: (context, t, _) => Container(
                width: 36 * t,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3)),
              ),
            )
          : null,
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (var x = 20.0; x < size.width; x += 28) {
      for (var y = 20.0; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: child,
      );
}

TextStyle _mono(double size,
        {double alpha = 0.9, FontWeight weight = FontWeight.w400}) =>
    BL.codeStyle.copyWith(
        fontSize: size,
        color: Colors.white.withValues(alpha: alpha),
        fontWeight: weight);

class _LabPreview extends StatelessWidget {
  const _LabPreview();
  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String label,
            {required bool done, bool current = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Icon(icon,
                size: 18,
                color: done
                    ? const Color(0xFF7BE0B0)
                    : Colors.white.withValues(alpha: current ? 1 : 0.5)),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: Colors.white
                        .withValues(alpha: done || current ? 1 : 0.6),
                    fontSize: 14,
                    fontWeight: current ? FontWeight.w600 : FontWeight.w400)),
          ]),
        );
    return _Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('git-first-commit', style: _mono(12, alpha: 0.7)),
          const Spacer(),
          Text('2 of 4', style: _mono(12, alpha: 0.7)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: Colors.white),
        ),
        const SizedBox(height: 10),
        row(Icons.check_circle, 'Create a repository', done: true),
        row(Icons.check_circle, 'Stage and commit', done: true),
        row(Icons.play_circle_fill, 'Create a branch',
            done: false, current: true),
        row(Icons.radio_button_unchecked, 'Merge it back', done: false),
      ]),
    );
  }
}

class _TutorPreview extends StatelessWidget {
  const _TutorPreview();
  @override
  Widget build(BuildContext context) {
    Widget bubble(String t, {required bool me}) => Align(
          alignment: me ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: me ? Colors.white : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: me
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(t,
                style: TextStyle(
                    color: me ? const Color(0xFF14213D) : Colors.white,
                    fontSize: 13.5,
                    height: 1.4)),
          ),
        );
    return _Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        bubble('Why does my loop skip the last item?', me: true),
        bubble(
            'Hint: look at where range() stops. Does it include its end value?',
            me: false),
        const SizedBox(height: 6),
        Row(children: [
          for (final l in const ['EN', 'हिन्दी', 'தமிழ்', '+6'])
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3))),
              child: Text(l,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5)),
            ),
        ]),
      ]),
    );
  }
}

class _CheckPreview extends StatelessWidget {
  const _CheckPreview();
  @override
  Widget build(BuildContext context) {
    Widget row(bool ok, String t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Text(ok ? '[pass]' : '[fail]',
                style: _mono(12.5, alpha: 1, weight: FontWeight.w700).copyWith(
                    color: ok
                        ? const Color(0xFF7BE0B0)
                        : const Color(0xFFFF9DB0))),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: _mono(12.5))),
          ]),
        );
    return _Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(r'$ devpilot check', style: _mono(12.5, alpha: 0.65)),
        const SizedBox(height: 8),
        row(true, 'branch fix/typo exists'),
        row(true, 'commit message has a summary line'),
        row(false, 'conflict markers left in app.py'),
        const SizedBox(height: 6),
        Text('Fix the file, then run the check again.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5)),
      ]),
    );
  }
}

class _BadgePreview extends StatelessWidget {
  const _BadgePreview();
  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: const EdgeInsets.all(22),
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 6))
              ]),
          child: const Icon(Icons.verified, size: 34, color: Color(0xFF2459E6)),
        ),
        const SizedBox(width: BL.space4),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Git Basics',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFF7BE0B0).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Verified by the server',
                  style: TextStyle(
                      color: Color(0xFF9BF0C6),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Text('Score 92 · checked just now', style: _mono(11.5, alpha: 0.7)),
          ]),
        ),
      ]),
    );
  }
}

class _GoogleColorIcon extends StatelessWidget {
  final double size;
  const _GoogleColorIcon({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final r = radius - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: r);

    // Blue arc & bar
    canvas.drawArc(rect, -0.6, 1.2, false, bluePaint);
    final blueBarPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
          center.dx - 1, center.dy - strokeWidth / 2, r + 1, strokeWidth),
      blueBarPaint,
    );

    // Green arc
    canvas.drawArc(rect, 0.6, 1.3, false, greenPaint);
    // Yellow arc
    canvas.drawArc(rect, 1.9, 1.2, false, yellowPaint);
    // Red arc
    canvas.drawArc(rect, 3.1, 1.5, false, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------------------------------------------
// Pilot, the mascot
// -----------------------------------------------------------------------------------------------------------------

/// A small robot that floats, blinks and follows the pointer with its eyes. It covers its eyes while a password is
/// typed and looks worried when sign-in fails. The loop only runs when [animate] is true (never in tests).
class _PilotMascot extends StatefulWidget {
  const _PilotMascot(
      {super.key,
      required this.gaze,
      required this.hideEyes,
      required this.worried,
      required this.animate});
  final ValueListenable<Offset> gaze;
  final bool hideEyes;
  final bool worried;
  final bool animate;

  @override
  State<_PilotMascot> createState() => _PilotMascotState();
}

class _PilotMascotState extends State<_PilotMascot>
    with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 5));
  late final AnimationController _wave = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void initState() {
    super.initState();
    if (widget.animate && !reducedMotionFlag) {
      _loop.repeat();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _wave.forward();
      });
    }
  }

  bool get reducedMotionFlag => false;

  @override
  void dispose() {
    _loop.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = !widget.animate || reducedMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.hideEyes ? 1 : 0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, hide, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: widget.worried ? 1 : 0),
        duration: const Duration(milliseconds: 250),
        builder: (context, worry, _) => ValueListenableBuilder<Offset>(
          valueListenable: widget.gaze,
          builder: (context, gaze, _) => AnimatedBuilder(
            animation: Listenable.merge([_loop, _wave]),
            builder: (context, _) {
              final t = still ? 0.0 : _loop.value;
              final bob = still ? 0.0 : math.sin(t * 2 * math.pi) * 6;
              // a quick blink near the end of each loop
              final blink = (t > 0.9 && t < 0.95) ? 1.0 : 0.0;
              return CustomPaint(
                size: const Size(220, 230),
                painter: _PilotPainter(
                    gaze: gaze,
                    hide: hide.clamp(0.0, 1.0),
                    wave: _wave.value,
                    blink: blink,
                    bob: bob,
                    worry: worry),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PilotPainter extends CustomPainter {
  _PilotPainter(
      {required this.gaze,
      required this.hide,
      required this.wave,
      required this.blink,
      required this.bob,
      required this.worry});
  final Offset gaze;
  final double hide;
  final double wave; // 0..1 progress of the hello wave
  final double blink;
  final double bob;
  final double worry;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 220;
    canvas.scale(sx, sx);
    final white = Paint()..color = Colors.white.withValues(alpha: 0.96);
    final soft = Paint()..color = Colors.white.withValues(alpha: 0.82);
    final edge = Paint()
      ..color = const Color(0xFFB8C8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // shadow on the ground, smaller when the robot floats higher
    final lift = (bob + 6) / 12; // 0..1
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(110, 222), width: 120 - lift * 26, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.18 - lift * 0.06),
    );

    canvas.save();
    canvas.translate(0, -bob);

    // antenna with a glowing tip
    canvas.drawLine(
        const Offset(110, 40),
        const Offset(110, 18),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    final tip =
        Color.lerp(const Color(0xFF7BE0B0), const Color(0xFFFFB86B), worry)!;
    canvas.drawCircle(const Offset(110, 14), 12,
        Paint()..color = tip.withValues(alpha: 0.28));
    canvas.drawCircle(const Offset(110, 14), 7, Paint()..color = tip);

    // body
    final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 170, 80, 40), const Radius.circular(18));
    canvas.drawRRect(body, soft);
    canvas.drawCircle(const Offset(110, 190), 6, Paint()..color = tip);

    // ears and head
    canvas.drawCircle(const Offset(26, 106), 11, soft);
    canvas.drawCircle(const Offset(194, 106), 11, soft);
    final head = RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 42, 160, 130), const Radius.circular(42));
    canvas.drawRRect(head, white);
    canvas.drawRRect(head, edge);

    // face screen
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(48, 62, 124, 88), const Radius.circular(28)),
        Paint()..color = const Color(0xFF0F1B3D));

    // eyes follow the pointer (up to 6 px), close for a blink or when hidden
    final g =
        Offset(gaze.dx.clamp(-1.0, 1.0) * 6, gaze.dy.clamp(-1.0, 1.0) * 4);
    final open = (1 - blink) * (1 - hide);
    final eye = Paint()..color = const Color(0xFF8FB4FF);
    for (final cx in const [86.0, 134.0]) {
      final h = 8 + 14 * open * (1 - 0.25 * worry);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + g.dx, 98 + g.dy + (worry * -2)),
              width: 16,
              height: h),
          eye);
    }

    // mouth: a smile that turns into a small worried line
    final mouth = Path()
      ..moveTo(98, 128)
      ..quadraticBezierTo(110, 128 + 12 * (1 - 2 * worry), 122, 128);
    canvas.drawPath(
        mouth,
        Paint()
          ..color = const Color(0xFF8FB4FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round);
    canvas.restore();

    // hands rise to cover the eyes
    for (final left in const [true, false]) {
      final rest = Offset(left ? 50 : 170, 196 - bob);
      final up = Offset(left ? 88 : 132, 104 - bob);
      var p = Offset.lerp(rest, up, hide)!;
      if (!left && hide == 0 && wave > 0 && wave < 1) {
        // lift the right hand beside the head and swing it a few times
        final lift = math.sin(wave * math.pi).clamp(0.0, 1.0);
        p = Offset.lerp(rest,
            Offset(200 + math.sin(wave * 6 * math.pi) * 10, 120 - bob), lift)!;
      }
      canvas.drawCircle(p, 15, white);
      canvas.drawCircle(p, 15, edge);
    }
  }

  @override
  bool shouldRepaint(covariant _PilotPainter o) =>
      o.gaze != gaze ||
      o.hide != hide ||
      o.wave != wave ||
      o.blink != blink ||
      o.bob != bob ||
      o.worry != worry;
}
