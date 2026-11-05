import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui/neon_background.dart';

/// Desktop-optimized landing page screen matching modern fintech/Web3 interfaces like Linear.
/// Features:
/// - Dark obsidian theme (#050508)
/// - Ethereal neon cyan (#00F2FE) & deep blue (#0051FF) ambient glow
/// - Top floating navbar with glowing cyan border CTA
/// - Centered hero section with bold typography & dual CTAs
/// - 3-column glassmorphism feature cards
/// - Desktop-responsive layout with constrained max width (1200px)
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonGlowBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top floating navbar
                      _buildFloatingNavbar(context),
                      const SizedBox(height: 72),

                      // 2. Desktop Hero Section
                      _buildHeroSection(context),
                      const SizedBox(height: 80),

                      // 3. Glassmorphism Feature Cards (3 columns on desktop)
                      _buildFeatureCards(isWide),
                      const SizedBox(height: 80),

                      // 4. Subtle footer
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingNavbar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              // Brand logo & title
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'DevSphere',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Navigation Links (hidden on very small viewports)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _navLink('Features'),
                  const SizedBox(width: 28),
                  _navLink('Curriculum'),
                  const SizedBox(width: 28),
                  _navLink('Roadmaps'),
                  const SizedBox(width: 28),
                  _navLink('Documentation'),
                ],
              ),
              const SizedBox(width: 32),

              // Pill-shaped CTA with glowing cyan border
              GestureDetector(
                key: const Key('landing_navbar_signin_button'),
                onTap: () => context.go('/?launch=true&mode=signin'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F2FE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF00F2FE),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Color(0xFF00F2FE),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pill announcement tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0051FF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00F2FE).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00F2FE),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'DevSphere 2.0 • Intelligent Learning IDE',
                style: TextStyle(
                  color: Color(0xFF00F2FE),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bold hero title
        const Text(
          'Engineering Mastery,\nAccelerated by AI.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 54,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 20),

        // Muted subtitle
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Learn by building real software with automated companion verification, '
            'personalized roadmaps, and isolated sandbox development environments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 36),

        // Two CTA buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Primary glowing CTA
            GestureDetector(
              key: const Key('landing_get_started_button'),
              onTap: () => context.go('/?launch=true'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F2FE), Color(0xFF0051FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Started Free',
                      style: TextStyle(
                        color: Color(0xFF050508),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Color(0xFF050508),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Secondary glass CTA
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: OutlinedButton(
                  onPressed: () => context.go('/dashboard'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    backgroundColor: Colors.white.withOpacity(0.04),
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Explore Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCards(bool isWide) {
    const cards = [
      (
        icon: Icons.code,
        title: 'Companion IDE',
        desc:
            'Native VS Code integration with guided step execution, live output streaming, and automatic companion setup.'
      ),
      (
        icon: Icons.verified_user_outlined,
        title: 'Verified Badges',
        desc:
            'Cryptographically verifiable achievements awarded exclusively when code passes strict automated test suites.'
      ),
      (
        icon: Icons.hub_outlined,
        title: 'Isolated Sandboxes',
        desc:
            'Zero privilege leaks: local worker architecture guarantees sandboxed execution with complete isolation.'
      ),
    ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: _featureCard(c.icon, c.title, c.desc),
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: cards
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _featureCard(c.icon, c.title, c.desc),
            ),
          )
          .toList(),
    );
  }

  Widget _featureCard(IconData icon, String title, String description) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F2FE).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00F2FE).withOpacity(0.25),
                  ),
                ),
                child: Icon(icon, color: const Color(0xFF00F2FE), size: 22),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        '© 2026 DevSphere. All rights reserved.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 12,
        ),
      ),
    );
  }
}

