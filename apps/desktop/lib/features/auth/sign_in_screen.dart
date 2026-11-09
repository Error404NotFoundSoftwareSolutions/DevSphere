// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: redesigned authentication screen with dark obsidian (#050508) theme,
// ethereal neon cyan (#00F2FE) & deep blue (#0051FF) ambient glow, moving fluid wave shader,
// and glassmorphic card styling.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../ui/neon_background.dart';
import '../../services/google_token_exchange.dart';
import '../../services/oauth_loopback_server.dart';
import 'firebase_auth_service.dart';
import 'auth_session.dart';
import 'launching_rocket_card.dart';
import 'session_store.dart';
import 'sign_in_service.dart';

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
  final GlobalKey<LaunchingRocketCardState> _rocketKey =
      GlobalKey<LaunchingRocketCardState>();
  late final SignInService _signInService;
  late final FirebaseAuthService _firebaseAuthService;
  late final SessionStore _sessionStore;
  bool _isLoading = false;
  AuthException? _error;
  late bool _isCreateAccount;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = true;
  bool _rocketLaunched = false;
  int _currentSlide = 0;
  Timer? _slideTimer;

  void _triggerRocketLaunch() {
    setState(() {
      _rocketLaunched = false;
    });
    _rocketKey.currentState?.launch();
  }

  static final List<_ProductSlideData> _slides = [
    const _ProductSlideData(
      category: 'AI PAIR PROGRAMMER',
      title: 'Real-Time AI Coding\nCompanion',
      subtitle: 'Learn by building.',
      description:
          'Get intelligent hints, architectural reviews, and contextual guidance right inside your IDE without spoiling solutions.',
      illustration: _AiCompanionIllustration(),
    ),
    const _ProductSlideData(
      category: 'ISOLATED LABS',
      title: 'Zero-Config Sandboxed\nCloud Workspaces',
      subtitle: 'Native VS Code integration.',
      description:
          'Run, test, and debug code in fully isolated sandboxes with automated test verification and zero local setup overhead.',
      illustration: _SandboxIllustration(),
    ),
    const _ProductSlideData(
      category: 'PROOF OF SKILL',
      title: 'Cryptographically Verified\nSkill Credentials',
      subtitle: 'Verifiable proof of mastery.',
      description:
          'Earn tamper-proof badges verified against rigorous test suites and real code contributions to showcase on your portfolio.',
      illustration: _BadgeIllustration(),
    ),
    const _ProductSlideData(
      category: 'CAREER ACCELERATOR',
      title: 'Adaptive Roadmaps to\nOpen Source Contributions',
      subtitle: 'From beginner to shipping PRs.',
      description:
          'Follow curated learning paths designed to take you from core programming concepts directly into production open-source software.',
      illustration: _RoadmapIllustration(),
    ),
  ];

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
    _sessionStore = widget.sessionStore ?? SessionStore();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    if (widget.autoLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerRocketLaunch();
        }
      });
    }

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
    if (widget.autoLaunch && !oldWidget.autoLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerRocketLaunch();
        }
      });
    }
    if (widget.initialCreateAccount != oldWidget.initialCreateAccount) {
      setState(() {
        _isCreateAccount = widget.initialCreateAccount;
      });
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
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
    _triggerRocketLaunch();

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
    _triggerRocketLaunch();

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
    _triggerRocketLaunch();

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

  @override
  Widget build(BuildContext context) {
    return NeonGlowBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 780;

          if (isWide) {
            return Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 1040, maxHeight: 680),
                child: Padding(
                  padding: const EdgeInsets.all(BL.space6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left hero card
                      Expanded(
                        flex: 5,
                        child: _buildHeroCard(),
                      ),
                      const SizedBox(width: BL.space6),
                      // Right form panel
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: BL.space4),
                            child: _buildFormContent(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            // Responsive mobile / compact layout
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BL.space6),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactHeader(),
                      const SizedBox(height: BL.space6),
                      _buildFormContent(context),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo.png',
                  key: const Key('auth_logo_image'),
                  height: 68,
                  width: 68,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: BL.space4),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DevPilot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'by DevSphere',
                  style: TextStyle(
                    color: Color(0xFF00F2FE),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Learn by building.',
          style: TextStyle(
            color: Color(0xFF00F2FE),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return LaunchingRocketCard(
      key: _rocketKey,
      onLaunchComplete: () {
        if (mounted) {
          setState(() {
            _rocketLaunched = true;
          });
        }
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
              color: const Color(0xFF00F2FE).withOpacity(0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F2FE).withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Digital silk waves inside hero card
              Positioned.fill(
                child: CustomPaint(
                  painter: _DigitalSilkHeroPainter(),
                ),
              ),
              // Content overlay
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withOpacity(0.35),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/logo.png',
                              key: const Key('auth_logo_image'),
                              height: 52,
                              width: 52,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'DevPilot',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'by DevSphere',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF00F2FE),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Middle: Slideshow Illustration Card (fades in after rocket launch)
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _rocketLaunched
                              ? KeyedSubtree(
                                  key: ValueKey<int>(_currentSlide),
                                  child: _slides[_currentSlide].illustration,
                                )
                              : const SizedBox(
                                  key: ValueKey<String>('launch_pad_clearance'),
                                  height: 180,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bottom: Dynamic Product Slide Content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_currentSlide),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF00F2FE).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00F2FE)
                                      .withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                _slides[_currentSlide].category,
                                style: const TextStyle(
                                  color: Color(0xFF00F2FE),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _slides[_currentSlide].title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _slides[_currentSlide].subtitle,
                              style: const TextStyle(
                                color: Color(0xFF00F2FE),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _slides[_currentSlide].description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Interactive Slideshow Indicators & Navigation Controls
                    Row(
                      children: [
                        // Clickable Indicator bars
                        ...List.generate(_slides.length, (index) {
                          final isActive = index == _currentSlide;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _currentSlide = index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 6),
                              width: isActive ? 34 : 14,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF00F2FE)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00F2FE)
                                              .withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }),
                        const Spacer(),
                        // Prev slide button
                        InkWell(
                          key: const Key('auth_prev_slide_button'),
                          onTap: () {
                            setState(() {
                              _currentSlide =
                                  (_currentSlide - 1 + _slides.length) %
                                      _slides.length;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Next slide button
                        InkWell(
                          key: const Key('auth_next_slide_button'),
                          onTap: () {
                            setState(() {
                              _currentSlide =
                                  (_currentSlide + 1) % _slides.length;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    final inputFillColor = Colors.white.withOpacity(0.04);
    final inputBorderColor = Colors.white.withOpacity(0.12);
    const accentCyan = Color(0xFF00F2FE);
    const accentBlue = Color(0xFF0051FF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Top row with title and back navigation
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isCreateAccount ? 'Create an account' : 'Sign in',
                      key: const Key('auth_screen_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('auth_back_button'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    tooltip: 'Back to website',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/landing');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Toggle between Create Account and Sign In
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _isCreateAccount
                        ? 'Already have an account? '
                        : "Don't have an account? ",
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  GestureDetector(
                    key: const Key('auth_switch_mode_button'),
                    onTap: () {
                      setState(() {
                        _isCreateAccount = !_isCreateAccount;
                        _error = null;
                      });
                      _triggerRocketLaunch();
                    },
                    child: Text(
                      _isCreateAccount ? 'Log in' : 'Create an account',
                      style: const TextStyle(
                        color: accentCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sign in with Google button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  key: const Key('auth_google_button'),
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: inputFillColor,
                    side: BorderSide(
                      color: _error != null
                          ? const Color(0xFFE11D48).withOpacity(0.4)
                          : inputBorderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GoogleColorIcon(size: 16),
                      const SizedBox(width: 6),
                      const Icon(Icons.login, size: 15, color: Colors.white70),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _error != null
                              ? 'Retry Sign In'
                              : 'Sign in with Google',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _isCreateAccount
                          ? 'Or register with email'
                          : 'Or sign in with email',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email & Password Fields
              if (_isCreateAccount) ...[
                // First name & Last name row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('auth_first_name_field'),
                        controller: _firstNameController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _inputDecoration(
                          'First name',
                          inputFillColor,
                          inputBorderColor,
                          accentCyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('auth_last_name_field'),
                        controller: _lastNameController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _inputDecoration(
                          'Last name',
                          inputFillColor,
                          inputBorderColor,
                          accentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Email field
              TextFormField(
                key: const Key('auth_email_field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDecoration(
                  'Email address',
                  inputFillColor,
                  inputBorderColor,
                  accentCyan,
                ),
              ),
              const SizedBox(height: 12),

              // Password field
              TextFormField(
                key: const Key('auth_password_field'),
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDecoration(
                  'Password',
                  inputFillColor,
                  inputBorderColor,
                  accentCyan,
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),

              if (_isCreateAccount) ...[
                const SizedBox(height: 12),
                // Password Confirmation field
                TextFormField(
                  key: const Key('auth_confirm_password_field'),
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(
                    'Confirm password',
                    inputFillColor,
                    inputBorderColor,
                    accentCyan,
                    suffix: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => setState(() =>
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Terms & Conditions checkbox
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        key: const Key('auth_terms_checkbox'),
                        value: _agreedToTerms,
                        activeColor: accentCyan,
                        checkColor: const Color(0xFF050508),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        side: const BorderSide(color: Colors.white38),
                        onChanged: (val) =>
                            setState(() => _agreedToTerms = val ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: accentCyan,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Error container
              if (_error != null) ...[
                Container(
                  key: const Key('auth_error_container'),
                  padding: const EdgeInsets.all(BL.space3),
                  margin: const EdgeInsets.only(bottom: BL.space3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF381524),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFE11D48).withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _error!.message,
                        key: const Key('auth_error_message'),
                        style: const TextStyle(
                          color: Color(0xFFFDA4AF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: BL.space1),
                      Text(
                        _error!.recoveryAction,
                        key: const Key('auth_recovery_action'),
                        style: const TextStyle(
                          color: Color(0xFFFECDD3),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Primary gradient submit button (Create account or Sign in)
              Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [accentCyan, accentBlue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentCyan.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  key: const Key('auth_submit_button'),
                  onPressed: _isLoading
                      ? null
                      : (_isCreateAccount
                          ? _handleEmailSignUp
                          : _handleEmailSignIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFF050508),
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF050508),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isCreateAccount ? 'Create account' : 'Sign in',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF050508),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  static InputDecoration _inputDecoration(
    String hint,
    Color fillColor,
    Color borderColor,
    Color focusedColor, {
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: focusedColor, width: 1.8),
      ),
    );
  }
}

class _DigitalSilkHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Ambient radial glow in hero card
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.2),
        radius: 1.1,
        colors: [
          const Color(0xFF00F2FE).withOpacity(0.22),
          const Color(0xFF0051FF).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    const cyan = Color(0xFF00F2FE);
    const blue = Color(0xFF0051FF);

    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= 3; i++) {
      final path = Path();
      final baseY = size.height * (0.52 + 0.1 * i);
      final freq = 0.007 * i;
      final offset = i * 1.5;

      for (double x = 0; x <= size.width; x += 8) {
        final y = baseY +
            math.sin(x * freq + offset) * 26.0 +
            math.cos(x * freq * 0.7 - offset) * 16.0;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Outer glow
      ribbonPaint.strokeWidth = 6.0;
      ribbonPaint.color = Color.lerp(cyan, blue, i / 3.0)!.withOpacity(0.14);
      canvas.drawPath(path, ribbonPaint);

      // Core line
      ribbonPaint.strokeWidth = 1.6;
      ribbonPaint.color =
          Color.lerp(cyan, blue, (i - 1) / 2.0)!.withOpacity(0.65);
      canvas.drawPath(path, ribbonPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

class _ProductSlideData {
  final String category;
  final String title;
  final String subtitle;
  final String description;
  final Widget illustration;

  const _ProductSlideData({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustration,
  });
}

class _AiCompanionIllustration extends StatelessWidget {
  const _AiCompanionIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF090D18).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F2FE).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF5F56),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFBD2E),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF27C93F),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'devpilot_tutor.py',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F2FE).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 10, color: Color(0xFF00F2FE)),
                    SizedBox(width: 4),
                    Text(
                      'AI Active',
                      style: TextStyle(
                        color: Color(0xFF00F2FE),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'def optimize_flow(dataset):',
                  style: TextStyle(
                    color: Color(0xFF00F2FE),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '    # DevPilot: SIMD auto-vectorized',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '    return dataset.batch(64).verify()',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '14/14 tests passing • 99.8% quality score',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SandboxIllustration extends StatelessWidget {
  const _SandboxIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF090D18).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0051FF).withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0051FF).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 14, color: Color(0xFF00F2FE)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'DevSphere Cloud Sandbox',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0051FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ISOLATED',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _node(Icons.computer, 'Local Worker'),
              const Icon(Icons.arrow_forward,
                  size: 12, color: Color(0xFF00F2FE)),
              _node(Icons.code, 'VS Code'),
              const Icon(Icons.arrow_forward,
                  size: 12, color: Color(0xFF00F2FE)),
              _node(Icons.lock_clock, 'Secure IPC'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'SEC-03 Isolation Guard',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Zero Privilege Leaks',
                  style: TextStyle(
                    color: Color(0xFF00F2FE),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _node(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00F2FE).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.3)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF00F2FE)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BadgeIllustration extends StatelessWidget {
  const _BadgeIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF090D18).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F2FE).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00F2FE), Color(0xFF0051FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withOpacity(0.4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium,
                size: 32, color: Color(0xFF050508)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Python Systems Architecture',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Level 3 • Verified Mastery',
            style: TextStyle(
              color: Color(0xFF00F2FE),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 12, color: Color(0xFF00F2FE)),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tamper-proof Cryptographic Signature',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapIllustration extends StatelessWidget {
  const _RoadmapIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF090D18).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F2FE).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route, size: 14, color: Color(0xFF00F2FE)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Adaptive Career Roadmap',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 6),
              Text(
                '75% Complete',
                style: TextStyle(
                  color: Color(0xFF00F2FE),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _stepRow(Icons.check_circle, '1. Core Algorithms', 'Verified pass',
              true),
          const SizedBox(height: 6),
          _stepRow(
              Icons.check_circle, '2. Backend APIs', 'Verified pass', true),
          const SizedBox(height: 6),
          _stepRow(Icons.radio_button_checked, '3. DevPilot Studio Labs',
              'In Progress', false,
              isCurrent: true),
          const SizedBox(height: 6),
          _stepRow(Icons.stars, '4. Open-Source Pull Request',
              'Final milestone', false),
        ],
      ),
    );
  }

  static Widget _stepRow(
      IconData icon, String title, String status, bool completed,
      {bool isCurrent = false}) {
    final color = completed
        ? const Color(0xFF10B981)
        : (isCurrent ? const Color(0xFF00F2FE) : Colors.white30);
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isCurrent ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          status,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
