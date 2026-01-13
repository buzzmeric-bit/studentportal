// ignore_for_file: unused_element, unused_field, unused_import

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../providers/suggestions_provider.dart';
import '../../widgets/detail_modal_sheet.dart';
import 'write_suggestion_screen.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late AnimationController _searchAnimationController;
  late Animation<double> _searchWidthAnimation;
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  List<PlatformFile> _attachedFiles = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchWidthAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 150), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suggestionsAsync = ref.watch(suggestionsProvider);

    return Stack(
      children: [
        Container(
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
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header with animated search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: _buildAnimatedHeader(l10n),
                  ),
                ),

                // Content
                suggestionsAsync.when(
                  data: (suggestions) {
                    // Apply filters and search
                    var filtered = suggestions.where((s) {
                      // Filter by status
                      bool matchesFilter = true;
                      switch (_selectedFilter) {
                        case 'pending':
                          matchesFilter = s.status == 'pending' && !s.isRead;
                          break;
                        case 'read':
                          matchesFilter = s.isRead;
                          break;
                        case 'replied':
                          matchesFilter = s.replies.isNotEmpty;
                          break;
                      }

                      // Apply search
                      if (_searchQuery.isNotEmpty) {
                        return matchesFilter &&
                            (s.title.toLowerCase().contains(_searchQuery) ||
                                s.body.toLowerCase().contains(_searchQuery));
                      }

                      return matchesFilter;
                    }).toList();

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (filtered.isNotEmpty) ...[
                            ...filtered.map(
                              (suggestion) => _buildSuggestionCard(suggestion),
                            ),
                          ] else if (suggestions.isEmpty) ...[
                            const SizedBox(height: 40),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 64,
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune suggestion',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black.withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 40),
                            Center(
                              child: Text(
                                'Aucun résultat',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ]),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Erreur: $error',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // FloatingActionButton positioned manually
        Positioned(
          right: 16,
          bottom: 96, // Above the nav bar
          child: FloatingActionButton(
            onPressed: () {
              context.go('/write-suggestion');
            },
            backgroundColor: const Color(0xFF8B5CF6),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildNewSuggestionCard(BuildContext context, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
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
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nouvelle suggestion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  hintText: 'Titre',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 4,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  hintText: 'Décrivez votre suggestion...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              // File attachments
              if (_attachedFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(_attachedFiles.length, (index) {
                  final file = _attachedFiles[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.name,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _attachedFiles.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Joindre'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        side: const BorderSide(color: Color(0xFF8B5CF6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitSuggestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Envoyer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
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
    );
  }

  Widget _buildSuggestionsListHeader(BuildContext context, int count) {
    return Row(
      children: [
        const Text(
          'Mes suggestions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$count suggestion${count > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Suggestion suggestion) {
    final statusColor = _getStatusColor(suggestion);
    final statusLabel = _getStatusLabel(suggestion);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showSuggestionDetail(suggestion),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(suggestion.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(suggestion),
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Type badge row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(
                            suggestion.suggestionType,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getTypeColor(
                              suggestion.suggestionType,
                            ).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getTypeLabel(suggestion.suggestionType),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getTypeColor(suggestion.suggestionType),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    suggestion.body,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.hasAttachment ||
                      suggestion.replies.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (suggestion.hasAttachment)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${suggestion.attachments.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        if (suggestion.hasAttachment &&
                            suggestion.replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (suggestion.replies.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble,
                                size: 14,
                                color: Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${suggestion.replies.length} réponse${suggestion.replies.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                      ],
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

  // Helper methods
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
            attachmentUrls: attachmentUrls,
            attachmentNames: attachmentNames,
            attachmentTypes: attachmentTypes,
          );

      // Clear form
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _attachedFiles.clear();
      });

      // Refresh list
      ref.invalidate(suggestionsProvider);

      if (mounted) {
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

  void _showSuggestionDetail(Suggestion suggestion) {
    DetailModalSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(suggestion).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(suggestion),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(suggestion),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(suggestion.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              suggestion.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            // Body
            Text(
              suggestion.body,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            // Attachments
            if (suggestion.attachments.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Pièces jointes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              ...suggestion.attachments.map((att) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          att.fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            // Replies
            if (suggestion.replies.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Réponses de l\'administration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              ...suggestion.replies.map((reply) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Administration',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(reply.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        reply.replyText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(Suggestion suggestion) {
    if (suggestion.replies.isNotEmpty) return Colors.green;
    if (suggestion.isRead) return Colors.blue;
    return Colors.orange;
  }

  String _getStatusLabel(Suggestion suggestion) {
    if (suggestion.replies.isNotEmpty) return 'Répondu';
    if (suggestion.isRead) return 'Lu';
    return 'En attente';
  }

  IconData _getStatusIcon(Suggestion suggestion) {
    if (suggestion.replies.isNotEmpty) return Icons.check_circle;
    if (suggestion.isRead) return Icons.visibility;
    return Icons.schedule;
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'reclamation_note':
        return 'Note';
      case 'absence':
        return 'Absence';
      case 'emploi_temps':
        return 'EDT';
      case 'inscription':
        return 'Inscription';
      case 'paiement':
        return 'Paiement';
      case 'stage':
        return 'Stage/PFE';
      case 'orientation':
        return 'Orientation';
      case 'bourse':
        return 'Bourse';
      case 'transport':
        return 'Transport';
      case 'restauration':
        return 'Resto';
      case 'bibliotheque':
        return 'Biblio';
      case 'vie_universitaire':
        return 'Vie univ.';
      case 'infrastructure':
        return 'Infra.';
      case 'securite':
        return 'Sécurité';
      case 'autre':
        return 'Autre';
      default:
        return 'Général';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'reclamation_note':
        return const Color(0xFFEF4444);
      case 'absence':
        return const Color(0xFFF59E0B);
      case 'emploi_temps':
        return const Color(0xFF3B82F6);
      case 'inscription':
        return const Color(0xFF8B5CF6);
      case 'paiement':
        return const Color(0xFF10B981);
      case 'stage':
        return const Color(0xFF6366F1);
      case 'orientation':
        return const Color(0xFFEC4899);
      case 'bourse':
        return const Color(0xFF14B8A6);
      case 'transport':
        return const Color(0xFF78716C);
      case 'restauration':
        return const Color(0xFFEAB308);
      case 'bibliotheque':
        return const Color(0xFF0EA5E9);
      case 'vie_universitaire':
        return const Color(0xFFA855F7);
      case 'infrastructure':
        return const Color(0xFF64748B);
      case 'securite':
        return const Color(0xFFDC2626);
      case 'autre':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}j';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Widget _buildAnimatedHeader(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _searchAnimationController,
      builder: (context, child) {
        final slideValue = _searchAnimationController.value;
        final fadeOut = 1.0 - slideValue;
        final fadeIn = slideValue;

        return SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Normal header - slides out and fades
              Transform.translate(
                offset: Offset(-80 * slideValue, 0),
                child: Opacity(
                  opacity: fadeOut.clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 1.0 - (0.3 * slideValue),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.suggestions,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Partagez vos idées',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleSearch,
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
                            Icons.search_rounded,
                            color: Colors.grey[700],
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Search bar - slides in from right
              Transform.translate(
                offset: Offset(
                  MediaQuery.of(context).size.width * (1 - slideValue),
                  0,
                ),
                child: Opacity(
                  opacity: fadeIn.clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleSearch,
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
                            Icons.close_rounded,
                            color: Colors.grey[700],
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search field - pill shaped
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Icon(
                                Icons.search_rounded,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (value) =>
                                      setState(() => _searchQuery = value),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
