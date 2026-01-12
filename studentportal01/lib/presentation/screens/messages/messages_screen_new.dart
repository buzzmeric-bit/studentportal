import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB794F6),
            Color(0xFF9B87F5),
            Color(0xFF7C9AF5),
            Color(0xFF6BBAFF),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF06B6D4),
                                Color(0xFF3B82F6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mail_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Messages',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Messages de classe',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Messages List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate(_buildMessages()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMessages() {
    final messages = [
      {
        'sender': 'Prof. Mohammed Alami',
        'subject': 'Contrôle de Mathématiques',
        'preview': 'Le contrôle aura lieu mardi prochain à 10h. Préparez les chapitres 5 et 6...',
        'time': DateTime.now().subtract(const Duration(hours: 1)),
        'isUnread': true,
        'avatar': 'M',
        'color': const Color(0xFF8B5CF6),
        'hasAttachment': true,
      },
      {
        'sender': 'Administration',
        'subject': 'Inscription aux activités',
        'preview': 'Les inscriptions pour les activités parascolaires sont ouvertes jusqu\'au...',
        'time': DateTime.now().subtract(const Duration(hours: 3)),
        'isUnread': true,
        'avatar': 'A',
        'color': const Color(0xFF10B981),
        'hasAttachment': false,
      },
      {
        'sender': 'Prof. Fatima Zahra',
        'subject': 'Projet de groupe',
        'preview': 'N\'oubliez pas de soumettre vos projets avant vendredi. Les équipes doivent...',
        'time': DateTime.now().subtract(const Duration(days: 1)),
        'isUnread': true,
        'avatar': 'F',
        'color': const Color(0xFFEC4899),
        'hasAttachment': false,
      },
      {
        'sender': 'Bibliothèque',
        'subject': 'Rappel de retour',
        'preview': 'Vous avez 2 livres à retourner avant le 20 janvier. Merci de passer...',
        'time': DateTime.now().subtract(const Duration(days: 2)),
        'isUnread': false,
        'avatar': 'B',
        'color': const Color(0xFFF59E0B),
        'hasAttachment': false,
      },
      {
        'sender': 'Service scolarité',
        'subject': 'Relevé de notes',
        'preview': 'Votre relevé de notes du premier semestre est disponible sur votre espace...',
        'time': DateTime.now().subtract(const Duration(days: 3)),
        'isUnread': false,
        'avatar': 'S',
        'color': const Color(0xFF06B6D4),
        'hasAttachment': true,
      },
    ];

    return messages.map((message) {
      final isUnread = message['isUnread'] as bool;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isUnread
                    ? Colors.white.withOpacity(0.85)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(isUnread ? 0.6 : 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          message['color'] as Color,
                          (message['color'] as Color).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (message['color'] as Color).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        message['avatar'] as String,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                message['sender'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isUnread
                                      ? const Color(0xFF1F2937)
                                      : Colors.grey[700],
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                if (message['hasAttachment'] as bool)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.attach_file_rounded,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF06B6D4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message['subject'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isUnread
                                ? const Color(0xFF1F2937)
                                : Colors.grey[600],
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message['preview'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatTime(message['time'] as DateTime),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('d MMM', 'fr_FR').format(time);
    }
  }
}
