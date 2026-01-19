import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/app_localizations.dart';

// Provider to fetch contact info from Supabase
final contactInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('app_settings')
        .select()
        .eq('key', 'contact_info')
        .maybeSingle();
    
    if (response != null && response['value'] != null) {
      return Map<String, dynamic>.from(response['value'] as Map);
    }
  } catch (e) {
    debugPrint('Error fetching contact info: $e');
  }
  
  // Default values
  return {
    'phone': '53 518 054',
    'email': 'lyceepythagore19@gmail.com',
    'address': 'Rue El Emir Faicel, Kairouan',
    'facebook': 'https://www.facebook.com/profile.php?id=100064041700592',
    'maps': 'https://www.google.com/maps/dir/35.831194,10.594667/35.6744015,10.1017/@35.7573801,10.0281956,10z',
    'website': 'https://aziz-tounsi.github.io/',
    'hours': 'Lun - Sam: 08:00 - 17:00',
  };
});

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final contactInfoAsync = ref.watch(contactInfoProvider);

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
          child: contactInfoAsync.when(
            data: (contactInfo) => CustomScrollView(
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1F2937)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          l10n.contact,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header Card - Glassy
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.support_agent,
                                    color: Color(0xFF3B82F6),
                                    size: 48,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  l10n.needHelp,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.contactDesc,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Contact Options
                      _PremiumContactCard(
                        icon: Icons.phone_outlined,
                        iconColor: const Color(0xFF10B981),
                        title: l10n.callUs,
                        subtitle: contactInfo['phone'] ?? '',
                        onTap: () => _launchPhone(contactInfo['phone'] ?? ''),
                      ),
                      const SizedBox(height: 12),
                      _PremiumContactCard(
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Email',
                        subtitle: contactInfo['email'] ?? '',
                        onTap: () => _launchEmail(contactInfo['email'] ?? ''),
                      ),
                      const SizedBox(height: 12),
                      _PremiumContactCard(
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFFEF4444),
                        title: l10n.visitUs,
                        subtitle: contactInfo['address'] ?? '',
                        onTap: () => _launchUrl(contactInfo['maps'] ?? ''),
                      ),
                      const SizedBox(height: 12),
                      _PremiumContactCard(
                        icon: Icons.access_time_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        title: l10n.officeHours,
                        subtitle: contactInfo['hours'] ?? '',
                        onTap: null,
                      ),
                      const SizedBox(height: 32),
                      
                      // Social Media Section
                      Text(
                        l10n.followUs,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PremiumSocialButtonSmall(
                            icon: Icons.facebook,
                            color: const Color(0xFF1877F2),
                            onTap: () => _launchUrl(contactInfo['facebook'] ?? ''),
                          ),
                          const SizedBox(width: 12),
                          _PremiumSocialButtonSmall(
                            icon: Icons.public,
                            color: const Color(0xFF3B82F6),
                            onTap: () => _launchUrl(contactInfo['website'] ?? ''),
                          ),
                          const SizedBox(width: 12),
                          _PremiumSocialButtonSmall(
                            icon: Icons.map_outlined,
                            color: const Color(0xFFEF4444),
                            onTap: () => _launchUrl(contactInfo['maps'] ?? ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Erreur de chargement')),
          ),
        ),
      ),
    );
  }
}

class _PremiumContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _PremiumContactCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumSocialButtonSmall extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PremiumSocialButtonSmall({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
