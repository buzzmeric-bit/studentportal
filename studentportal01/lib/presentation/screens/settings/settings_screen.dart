import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8D5F2),
              Color(0xFFD4C4E8),
              Color(0xFFC9D6F0),
              Color(0xFFE0EAF5),
              Color(0xFFF0F5FA),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Futuristic Header
              SliverToBoxAdapter(child: _buildHeader(context, l10n)),

              // Settings Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    // Language Section
                    _buildAnimatedCard(
                      delay: 0,
                      child: _FuturisticLanguageSection(
                        currentLocale: currentLocale,
                        onLocaleChanged: (code) =>
                            ref.read(localeProvider.notifier).setLocale(code),
                        l10n: l10n,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notifications Section
                    _buildAnimatedCard(
                      delay: 2,
                      child: _FuturisticNotificationsSection(l10n: l10n),
                    ),
                    const SizedBox(height: 40),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back Button with glow
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(
                          alpha: 0.15 + _pulseController.value * 0.1,
                        ),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF6366F1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Static Title (no shimmer animation)
                Text(
                  l10n.settings,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personnalisez votre expérience',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({required int delay, required Widget child}) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _entranceController,
              curve: Interval(
                0.1 * delay,
                0.4 + 0.1 * delay,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(
              0.1 * delay,
              0.4 + 0.1 * delay,
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

// Futuristic Language Section with Pill Selector
class _FuturisticLanguageSection extends StatefulWidget {
  final Locale currentLocale;
  final Function(String) onLocaleChanged;
  final AppLocalizations l10n;

  const _FuturisticLanguageSection({
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.l10n,
  });

  @override
  State<_FuturisticLanguageSection> createState() =>
      _FuturisticLanguageSectionState();
}

class _FuturisticLanguageSectionState extends State<_FuturisticLanguageSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  final List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français'},
    {'code': 'en', 'name': 'English'},
    {'code': 'ar', 'name': 'العربية'},
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  int get _selectedIndex => _languages.indexWhere(
    (l) => l['code'] == widget.currentLocale.languageCode,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.7),
                Colors.white.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeaderFuturistic(
                icon: Icons.language_rounded,
                title: widget.l10n.language,
                gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              const SizedBox(height: 16),
              // Pill Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200]?.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pillWidth =
                        (constraints.maxWidth - 8) / _languages.length;
                    return Stack(
                      children: [
                        // Animated Selection Indicator
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          left: _selectedIndex * pillWidth,
                          child: AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              return Container(
                                width: pillWidth,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withValues(
                                        alpha:
                                            0.3 + _glowController.value * 0.2,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // Language Options
                        Row(
                          children: _languages.map((lang) {
                            final isSelected =
                                lang['code'] ==
                                widget.currentLocale.languageCode;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    widget.onLocaleChanged(lang['code']!),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: Text(
                                    lang['name']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Futuristic Notifications Section
class _FuturisticNotificationsSection extends StatefulWidget {
  final AppLocalizations l10n;

  const _FuturisticNotificationsSection({required this.l10n});

  @override
  State<_FuturisticNotificationsSection> createState() =>
      _FuturisticNotificationsSectionState();
}

class _FuturisticNotificationsSectionState
    extends State<_FuturisticNotificationsSection> {
  bool _announcements = true;
  bool _messages = true;
  bool _results = true;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.7),
                Colors.white.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeaderFuturistic(
                icon: Icons.notifications_rounded,
                title: widget.l10n.notifications,
                gradientColors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
              ),
              const SizedBox(height: 16),
              _FuturisticToggle(
                icon: Icons.campaign_rounded,
                label: widget.l10n.announcements,
                value: _announcements,
                color: const Color(0xFF3B82F6),
                onChanged: (v) => setState(() => _announcements = v),
              ),
              const SizedBox(height: 12),
              _FuturisticToggle(
                icon: Icons.message_rounded,
                label: widget.l10n.messages,
                value: _messages,
                color: const Color(0xFF10B981),
                onChanged: (v) => setState(() => _messages = v),
              ),
              const SizedBox(height: 12),
              _FuturisticToggle(
                icon: Icons.grade_rounded,
                label: widget.l10n.resultats,
                value: _results,
                color: const Color(0xFFEF4444),
                onChanged: (v) => setState(() => _results = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Futuristic Toggle Switch
class _FuturisticToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _FuturisticToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.1)
              : Colors.grey[100]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: value
                      ? [color, color.withValues(alpha: 0.7)]
                      : [Colors.grey[300]!, Colors.grey[400]!],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: value ? color : Colors.grey[600],
                ),
              ),
            ),
            // Futuristic Toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                gradient: value
                    ? LinearGradient(
                        colors: [color, color.withValues(alpha: 0.8)],
                      )
                    : null,
                color: value ? null : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: value ? 26 : 2,
                    top: 2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: value
                          ? Icon(Icons.check_rounded, size: 16, color: color)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Futuristic About Card
class _FuturisticAboutCard extends StatefulWidget {
  const _FuturisticAboutCard();

  @override
  State<_FuturisticAboutCard> createState() => _FuturisticAboutCardState();
}

class _FuturisticAboutCardState extends State<_FuturisticAboutCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_floatController.value * math.pi) * 3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.6),
                      const Color(0xFF6366F1).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Logo with glow
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(
                              alpha: 0.2 + _floatController.value * 0.1,
                            ),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/pythaonelogo.png',
                          width: 48,
                          height: 48,
                          errorBuilder: (_, __, ___) => ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ).createShader(bounds);
                            },
                            child: const Icon(
                              Icons.school_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [Color(0xFF1F2937), Color(0xFF6366F1)],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              'PythaOne',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lycée Pilote Privé Pythagore',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Version Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Section Header with gradient icon
class _SectionHeaderFuturistic extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<Color> gradientColors;

  const _SectionHeaderFuturistic({
    required this.icon,
    required this.title,
    required this.gradientColors,
  });

  @override
  State<_SectionHeaderFuturistic> createState() =>
      _SectionHeaderFuturisticState();
}

class _SectionHeaderFuturisticState extends State<_SectionHeaderFuturistic>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: widget.gradientColors),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors[0].withValues(
                      alpha: 0.3 + _pulseController.value * 0.2,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            );
          },
        ),
        const SizedBox(width: 14),
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
