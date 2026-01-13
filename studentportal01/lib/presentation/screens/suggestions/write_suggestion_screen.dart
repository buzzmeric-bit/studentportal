import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/suggestions_provider.dart';

class WriteSuggestionScreen extends ConsumerStatefulWidget {
  const WriteSuggestionScreen({super.key});

  @override
  ConsumerState<WriteSuggestionScreen> createState() =>
      _WriteSuggestionScreenState();
}

/// Suggestion types relevant for Tunisian students
const Map<String, String> suggestionTypes = {
  'reclamation_note': 'Réclamation de note',
  'absence': 'Absence / Justification',
  'emploi_temps': 'Emploi du temps',
  'inscription': 'Inscription / Réinscription',
  'paiement': 'Paiement / Frais de scolarité',
  'orientation': 'Orientation / Changement de filière',
  'bourse': 'Bourse / Aide sociale',
  'transport': 'Transport / Hébergement',
  'restauration': 'Restauration universitaire',
  'bibliotheque': 'Bibliothèque / Ressources',
  'vie_universitaire': 'Vie universitaire / Activités',
  'infrastructure': 'Infrastructure / Équipements',
  'securite': 'Sécurité / Hygiène',
  'autre': 'Autre',
};

/// Get icon for suggestion type
IconData getTypeIcon(String type) {
  switch (type) {
    case 'reclamation_note': return Icons.grading_rounded;
    case 'absence': return Icons.event_busy_rounded;
    case 'emploi_temps': return Icons.calendar_month_rounded;
    case 'inscription': return Icons.app_registration_rounded;
    case 'paiement': return Icons.payment_rounded;
    case 'orientation': return Icons.explore_rounded;
    case 'bourse': return Icons.school_rounded;
    case 'transport': return Icons.directions_bus_rounded;
    case 'restauration': return Icons.restaurant_rounded;
    case 'bibliotheque': return Icons.local_library_rounded;
    case 'vie_universitaire': return Icons.groups_rounded;
    case 'infrastructure': return Icons.apartment_rounded;
    case 'securite': return Icons.security_rounded;
    case 'autre': return Icons.more_horiz_rounded;
    default: return Icons.lightbulb_rounded;
  }
}

/// Get color for suggestion type
Color getTypeColor(String type) {
  switch (type) {
    case 'reclamation_note': return const Color(0xFFEF4444);
    case 'absence': return const Color(0xFFF59E0B);
    case 'emploi_temps': return const Color(0xFF3B82F6);
    case 'inscription': return const Color(0xFF8B5CF6);
    case 'paiement': return const Color(0xFF10B981);
    case 'orientation': return const Color(0xFFEC4899);
    case 'bourse': return const Color(0xFF14B8A6);
    case 'transport': return const Color(0xFF78716C);
    case 'restauration': return const Color(0xFFEAB308);
    case 'bibliotheque': return const Color(0xFF0EA5E9);
    case 'vie_universitaire': return const Color(0xFFA855F7);
    case 'infrastructure': return const Color(0xFF64748B);
    case 'securite': return const Color(0xFFDC2626);
    case 'autre': return const Color(0xFF6B7280);
    default: return const Color(0xFF9CA3AF);
  }
}

class _WriteSuggestionScreenState extends ConsumerState<WriteSuggestionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<PlatformFile> _attachedFiles = [];
  bool _isSubmitting = false;
  String _selectedType = 'autre';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif'],
      );

      if (result != null) {
        setState(() {
          _attachedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection des fichiers: $e'),
          ),
        );
      }
    }
  }

  Future<void> _submitSuggestion() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) throw Exception('Non authentifié');

      // Upload files if any
      List<String>? attachmentUrls;
      List<String>? attachmentNames;
      List<String>? attachmentTypes;

      if (_attachedFiles.isNotEmpty) {
        attachmentUrls = [];
        attachmentNames = [];
        attachmentTypes = [];

        for (final file in _attachedFiles) {
          try {
            final bytes = file.bytes;
            if (bytes != null) {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final storePath = '$userId/$timestamp\_${file.name}';

              await supabase.storage
                  .from('suggestions')
                  .uploadBinary(storePath, bytes);

              final url = supabase.storage
                  .from('suggestions')
                  .getPublicUrl(storePath);

              attachmentUrls.add(url);
              attachmentNames.add(file.name);
              attachmentTypes.add(file.extension ?? '');
            }
          } catch (e) {
            print('Error uploading file: $e');
          }
        }
      }

      // Create suggestion using repository
      await ref
          .read(suggestionRepositoryProvider)
          .createSuggestion(
            title: _titleController.text.trim(),
            body: _contentController.text.trim(),
            suggestionType: _selectedType,
            attachmentUrls: attachmentUrls,
            attachmentNames: attachmentNames,
            attachmentTypes: attachmentTypes,
          );

      // Refresh list
      ref.invalidate(suggestionsProvider);

      if (mounted) {
        context.go('/suggestions');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion envoyée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Build modern glassy type selector with radio buttons
  Widget _buildTypeSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: suggestionTypes.entries.map((entry) {
              final isSelected = _selectedType == entry.key;
              final typeColor = getTypeColor(entry.key);
              final typeIcon = getTypeIcon(entry.key);
              
              return GestureDetector(
                onTap: () => setState(() => _selectedType = entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? typeColor.withOpacity(0.15) 
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? typeColor : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: typeColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Radio indicator
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? typeColor : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: typeColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        typeIcon,
                        size: 18,
                        color: isSelected ? typeColor : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? typeColor : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8D5F2), // Lavender / lilac
            Color(0xFFD4C4E8), // Soft lilac
            Color(0xFFC9D6F0), // Light periwinkle
            Color(0xFFE0EAF5), // Icy blue-white
            Color(0xFFF0F5FA), // Cool icy white
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/suggestions'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.grey[700],
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nouvelle suggestion',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey[900],
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Partagez votre idée',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Field
                            Text(
                              'Titre',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _titleController,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[900],
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Titre de votre suggestion',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Suggestion Type Selection - Modern Glassy Radio Grid
                            Text(
                              'Type de suggestion',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTypeSelector(),
                            const SizedBox(height: 24),
                            // Description Field
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _contentController,
                                maxLines: 6,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[900],
                                  height: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Décrivez votre suggestion en détail...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(20),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Attached files
                            if (_attachedFiles.isNotEmpty) ...[
                              Text(
                                'Fichiers joints (${_attachedFiles.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[700],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_attachedFiles.length, (index) {
                                final file = _attachedFiles[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF8B5CF6,
                                      ).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF8B5CF6,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.insert_drive_file_rounded,
                                          size: 20,
                                          color: const Color(0xFF8B5CF6),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[900],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${(file.size / 1024).toStringAsFixed(1)} KB',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _attachedFiles.removeAt(index);
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF8B5CF6,
                                        ).withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _pickFiles,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.attach_file_rounded,
                                                color: const Color(0xFF8B5CF6),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  'Fichier',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF8B5CF6,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8B5CF6),
                                          Color(0xFF6366F1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF8B5CF6,
                                          ).withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isSubmitting
                                            ? null
                                            : _submitSuggestion,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Center(
                                          child: _isSubmitting
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          Colors.white,
                                                        ),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.send_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Envoyer',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
}
