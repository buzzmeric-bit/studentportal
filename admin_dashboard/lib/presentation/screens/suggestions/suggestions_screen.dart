// ignore_for_file: unused_element

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/suggestions_provider.dart';
import '../../widgets/admin_sidebar.dart';
import '../users/user_detail_screen.dart';

// =====================================================
// SMART SEARCH HELPERS (same as announcements)
// =====================================================

/// Normalize string for smart search (remove accents, lowercase)
String _normalizeForSearch(String text) {
  const accents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝŸ';
  const normalized = 'aaaaaaceeeeiiiinooooouuuuyyAAAAAAÇEEEEIIIINOOOOOUUUUYY';
  var result = text.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    result = result.replaceAll(accents[i], normalized[i].toLowerCase());
  }
  return result;
}

/// Get all searchable fields for a suggestion (including formatted dates)
String _getSearchableFields(Suggestion s) {
  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm EEEE MMMM', 'fr_FR');

  // Type labels mapping for Tunisian students
  String typeLabel;
  switch (s.suggestionType) {
    case 'reclamation_note':
      typeLabel = 'réclamation note grade examen';
      break;
    case 'absence':
      typeLabel = 'absence justification manque cours';
      break;
    case 'emploi_temps':
      typeLabel = 'emploi temps horaire planning seance';
      break;
    case 'inscription':
      typeLabel = 'inscription réinscription dossier';
      break;
    case 'paiement':
      typeLabel = 'paiement frais scolarité cotisation argent';
      break;
    case 'orientation':
      typeLabel = 'orientation filière changement spécialité';
      break;
    case 'bourse':
      typeLabel = 'bourse aide sociale financière';
      break;
    case 'transport':
      typeLabel = 'transport hébergement foyer bus';
      break;
    case 'restauration':
      typeLabel = 'restauration resto universitaire cantine';
      break;
    case 'bibliotheque':
      typeLabel = 'bibliothèque ressources livres';
      break;
    case 'vie_universitaire':
      typeLabel = 'vie universitaire activités club';
      break;
    case 'infrastructure':
      typeLabel = 'infrastructure équipements salle';
      break;
    case 'securite':
      typeLabel = 'sécurité hygiène';
      break;
    case 'autre':
      typeLabel = 'autre divers';
      break;
    default:
      typeLabel = 'général general';
  }

  // Status labels
  String statusLabel;
  switch (s.status) {
    case 'pending':
      statusLabel = 'en attente pending';
      break;
    case 'in_review':
      statusLabel = 'en cours review examen';
      break;
    case 'replied':
      statusLabel = 'répondu reply';
      break;
    case 'closed':
      statusLabel = 'fermé closed';
      break;
    default:
      statusLabel = s.status;
  }

  // Build all searchable text
  final fields = [
    s.subject,
    s.content,
    s.studentName ?? '',
    s.studentCode ?? '',
    s.className ?? '',
    typeLabel,
    statusLabel,
    dateFormatter.format(s.createdAt),
    s.isRead ? 'lu read' : 'non lu unread nouveau',
    s.hasAttachment ? 'pièce jointe fichier attachment' : '',
  ];

  return fields.join(' ');
}

/// Highlight matching text in a string
Widget _highlightText(
  String text,
  String query,
  TextStyle? baseStyle, {
  int maxLines = 2,
}) {
  if (query.isEmpty)
    return Text(
      text,
      style: baseStyle,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );

  final normalizedText = _normalizeForSearch(text);
  final normalizedQuery = _normalizeForSearch(query);
  final tokens = normalizedQuery
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  if (tokens.isEmpty)
    return Text(
      text,
      style: baseStyle,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );

  // Find all match positions
  List<_MatchRange> matches = [];
  for (final token in tokens) {
    int start = 0;
    while (true) {
      final index = normalizedText.indexOf(token, start);
      if (index == -1) break;
      matches.add(_MatchRange(index, index + token.length));
      start = index + 1;
    }
  }

  if (matches.isEmpty)
    return Text(
      text,
      style: baseStyle,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );

  // Sort and merge overlapping ranges
  matches.sort((a, b) => a.start.compareTo(b.start));
  List<_MatchRange> merged = [];
  for (final m in matches) {
    if (merged.isEmpty || merged.last.end < m.start) {
      merged.add(m);
    } else {
      merged.last = _MatchRange(
        merged.last.start,
        m.end > merged.last.end ? m.end : merged.last.end,
      );
    }
  }

  // Build text spans
  List<TextSpan> spans = [];
  int lastEnd = 0;
  for (final m in merged) {
    if (m.start > lastEnd) {
      spans.add(
        TextSpan(text: text.substring(lastEnd, m.start), style: baseStyle),
      );
    }
    spans.add(
      TextSpan(
        text: text.substring(m.start, m.end),
        style:
            baseStyle?.copyWith(
              backgroundColor: Colors.yellow.shade200,
              fontWeight: FontWeight.bold,
            ) ??
            TextStyle(
              backgroundColor: Colors.yellow.shade200,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
    lastEnd = m.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
  }

  return RichText(
    text: TextSpan(children: spans),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

class _MatchRange {
  int start;
  int end;
  _MatchRange(this.start, this.end);
}

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _showFilters = false;
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
        _selectionMode = true;
      }
    });
  }

  void _selectAll(List<Suggestion> suggestions) {
    setState(() {
      if (_selectedIds.length == suggestions.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(suggestions.map((s) => s.id));
        _selectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer ${_selectedIds.length} suggestion(s) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(suggestionsProvider.notifier)
          .deleteMultiple(_selectedIds.toList());
      _clearSelection();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(suggestionsProvider.notifier).setSearchQuery(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(suggestionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/suggestions'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, suggestionsAsync),
                if (_showFilters) _buildFilterBar(context, suggestionsAsync),
                Expanded(
                  child: suggestionsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Erreur: $e'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref
                                .read(suggestionsProvider.notifier)
                                .refresh(),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                    data: (state) => _buildContent(context, ref, state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AsyncValue<SuggestionsState> suggestionsAsync,
  ) {
    // Selection mode top bar
    if (_selectionMode) {
      return Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
              tooltip: 'Annuler la sélection',
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedIds.length} sélectionné(s)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 16),
            suggestionsAsync.whenOrNull(
                  data: (state) => TextButton.icon(
                    icon: Icon(
                      _selectedIds.length == state.filtered.length
                          ? Icons.deselect
                          : Icons.select_all,
                    ),
                    label: Text(
                      _selectedIds.length == state.filtered.length
                          ? 'Désélectionner tout'
                          : 'Sélectionner tout',
                    ),
                    onPressed: () => _selectAll(state.filtered),
                  ),
                ) ??
                const SizedBox.shrink(),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Supprimer'),
              onPressed: _deleteSelected,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Normal top bar
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Suggestions',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          // Statistics badges
          suggestionsAsync.whenOrNull(
                data: (state) => Row(
                  children: [
                    if (state.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.unreadCount} non lu(s)',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (state.pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.pendingCount} en attente',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
          const SizedBox(width: 24),
          // Search bar - same style as announcements
          SizedBox(
            width: 350,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(suggestionsProvider.notifier)
                              .setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter toggle button - same style as announcements
          Badge(
            isLabelVisible: _hasActiveFilters(suggestionsAsync),
            child: IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              ),
              tooltip: 'Filtres',
              onPressed: () => setState(() => _showFilters = !_showFilters),
              color: _showFilters ? Colors.blue : null,
            ),
          ),
          const Spacer(),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.read(suggestionsProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(AsyncValue<SuggestionsState> suggestionsAsync) {
    return suggestionsAsync.whenOrNull(
          data: (state) =>
              state.statusFilter != 'all' ||
              state.typeFilter != 'all' ||
              state.classFilter != 'all' ||
              state.dateFrom != null ||
              state.dateTo != null,
        ) ??
        false;
  }

  Widget _buildFilterBar(
    BuildContext context,
    AsyncValue<SuggestionsState> suggestionsAsync,
  ) {
    return suggestionsAsync.whenOrNull(
          data: (state) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Status filter
                DropdownButton<String>(
                  value: state.statusFilter,
                  hint: const Text('Statut'),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tous les statuts'),
                    ),
                    DropdownMenuItem(value: 'unread', child: Text('Non lus')),
                    DropdownMenuItem(value: 'read', child: Text('Lus')),
                    DropdownMenuItem(value: 'sent', child: Text('Envoyé')),
                    DropdownMenuItem(value: 'replied', child: Text('Répondu')),
                  ],
                  onChanged: (v) => ref
                      .read(suggestionsProvider.notifier)
                      .setStatusFilter(v!),
                ),
                // Type filter
                DropdownButton<String>(
                  value: state.typeFilter,
                  hint: const Text('Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tous les types'),
                    ),
                    DropdownMenuItem(value: 'general', child: Text('Général')),
                    DropdownMenuItem(
                      value: 'reclamation_note',
                      child: Text('Réclamation note'),
                    ),
                    DropdownMenuItem(value: 'absence', child: Text('Absence')),
                    DropdownMenuItem(
                      value: 'emploi_temps',
                      child: Text('Emploi du temps'),
                    ),
                    DropdownMenuItem(
                      value: 'inscription',
                      child: Text('Inscription'),
                    ),
                    DropdownMenuItem(
                      value: 'paiement',
                      child: Text('Paiement'),
                    ),
                    DropdownMenuItem(
                      value: 'stage',
                      child: Text('Stage / PFE'),
                    ),
                    DropdownMenuItem(
                      value: 'orientation',
                      child: Text('Orientation'),
                    ),
                    DropdownMenuItem(value: 'bourse', child: Text('Bourse')),
                    DropdownMenuItem(
                      value: 'transport',
                      child: Text('Transport'),
                    ),
                    DropdownMenuItem(
                      value: 'restauration',
                      child: Text('Restauration'),
                    ),
                    DropdownMenuItem(
                      value: 'bibliotheque',
                      child: Text('Bibliothèque'),
                    ),
                    DropdownMenuItem(
                      value: 'vie_universitaire',
                      child: Text('Vie universitaire'),
                    ),
                    DropdownMenuItem(
                      value: 'infrastructure',
                      child: Text('Infrastructure'),
                    ),
                    DropdownMenuItem(
                      value: 'securite',
                      child: Text('Sécurité'),
                    ),
                    DropdownMenuItem(value: 'autre', child: Text('Autre')),
                  ],
                  onChanged: (v) =>
                      ref.read(suggestionsProvider.notifier).setTypeFilter(v!),
                ),
                // Class filter
                if (state.uniqueClasses.isNotEmpty)
                  DropdownButton<String>(
                    value: state.classFilter,
                    hint: const Text('Classe'),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Toutes les classes'),
                      ),
                      ...state.uniqueClasses.map(
                        (classId) => DropdownMenuItem(
                          value: classId,
                          child: Text(state.classNames[classId] ?? classId),
                        ),
                      ),
                    ],
                    onChanged: (v) => ref
                        .read(suggestionsProvider.notifier)
                        .setClassFilter(v!),
                  ),
                // Date range
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    state.dateFrom != null
                        ? '${DateFormat('dd/MM').format(state.dateFrom!)} - ${state.dateTo != null ? DateFormat('dd/MM').format(state.dateTo!) : '...'}'
                        : 'Période',
                  ),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange:
                          state.dateFrom != null && state.dateTo != null
                          ? DateTimeRange(
                              start: state.dateFrom!,
                              end: state.dateTo!,
                            )
                          : null,
                    );
                    if (range != null) {
                      ref
                          .read(suggestionsProvider.notifier)
                          .setDateRange(range.start, range.end);
                    }
                  },
                ),
                // Sort dropdown
                DropdownButton<String>(
                  value: state.sortBy,
                  hint: const Text('Trier par'),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(value: 'class', child: Text('Classe')),
                    DropdownMenuItem(value: 'type', child: Text('Type')),
                    DropdownMenuItem(value: 'status', child: Text('Statut')),
                  ],
                  onChanged: (v) =>
                      ref.read(suggestionsProvider.notifier).setSortBy(v!),
                ),
                IconButton(
                  icon: Icon(
                    state.sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  tooltip: state.sortAscending ? 'Croissant' : 'Décroissant',
                  onPressed: () => ref
                      .read(suggestionsProvider.notifier)
                      .setSortBy(state.sortBy),
                ),
                // Clear filters
                if (_hasActiveFilters(suggestionsAsync))
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Réinitialiser'),
                    onPressed: () =>
                        ref.read(suggestionsProvider.notifier).clearFilters(),
                  ),
              ],
            ),
          ),
        ) ??
        const SizedBox.shrink();
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SuggestionsState state,
  ) {
    final searchQuery = state.searchQuery;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: state.filtered.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune suggestion',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (state.suggestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Essayez de modifier les filtres',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.filtered.length,
                itemBuilder: (context, index) {
                  final s = state.filtered[index];
                  return _SuggestionCard(
                    suggestion: s,
                    searchQuery: searchQuery,
                    isSelected: _selectedIds.contains(s.id),
                    selectionMode: _selectionMode,
                    onSelect: () => _toggleSelection(s.id),
                    onAction: (action) => _handleAction(action, s),
                  );
                },
              ),
      ),
    );
  }

  void _handleAction(String action, Suggestion s) {
    switch (action) {
      case 'reply':
        _showReplyDialog(context, ref, s);
        break;
      case 'read':
        ref.read(suggestionsProvider.notifier).markAsRead(s.id);
        break;
      case 'unread':
        ref.read(suggestionsProvider.notifier).markAsUnread(s.id);
        break;
      case 'view':
        _showDetailDialog(context, s);
        break;
      case 'delete':
        _confirmDelete(s);
        break;
      case 'viewStudent':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UserDetailScreen(userId: s.studentId, userName: s.studentName),
          ),
        );
        break;
    }
  }

  Future<void> _confirmDelete(Suggestion s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer la suggestion "${s.subject}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(suggestionsProvider.notifier).delete(s.id);
    }
  }

  void _showReplyDialog(BuildContext context, WidgetRef ref, Suggestion s) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Répondre à: ${s.subject}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original message preview
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          s.studentName ?? 'Anonyme',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (s.className != null) ...[
                          const Text(' • '),
                          Text(
                            s.className!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Votre réponse',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isEmpty) return;
              ref
                  .read(suggestionsProvider.notifier)
                  .reply(s.id, controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Suggestion s) {
    // Get type color for theming
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
        default: return const Color(0xFF6B7280);
      }
    }
    
    final typeColor = getTypeColor(s.suggestionType);
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: typeColor.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Header with gradient accent
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      typeColor.withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Top bar with close button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                      child: Row(
                        children: [
                          // Type indicator dot
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: typeColor.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _TypeBadge(type: s.suggestionType),
                          const SizedBox(width: 8),
                          _StatusChip(status: s.status),
                          const Spacer(),
                          // Unread indicator
                          if (!s.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Nouveau',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[400]),
                            onPressed: () => Navigator.pop(ctx),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Subject title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              s.subject,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(s.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Divider
              Container(height: 1, color: Colors.grey[100]),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student info card - modern design
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailScreen(
                                userId: s.studentId,
                                userName: s.studentName,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                typeColor.withOpacity(0.08),
                                typeColor.withOpacity(0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: typeColor.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar with gradient
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      typeColor.withOpacity(0.8),
                                      typeColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: typeColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    s.studentName?.substring(0, 1).toUpperCase() ?? 'A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.studentName ?? 'Étudiant',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (s.studentCode != null && s.studentCode!.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.grey[200]!),
                                            ),
                                            child: Text(
                                              s.studentCode!,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (s.className != null && s.className!.isNotEmpty) ...[
                                          Icon(Icons.school_outlined, size: 14, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.className!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_outline, size: 16, color: typeColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Profil',
                                      style: TextStyle(
                                        color: typeColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios, size: 12, color: typeColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Message content - clean design
                      Row(
                        children: [
                          Icon(Icons.message_outlined, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Text(
                            'Message',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                        child: SelectableText(
                          s.content.isNotEmpty ? s.content : '(Aucun contenu)',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      
                      // Attachments with modern design
                      if (s.attachments.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(Icons.attach_file, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            Text(
                              'Pièces jointes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${s.attachments.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AttachmentsGrid(attachments: s.attachments),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Modern Actions Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey[100]!),
                  ),
                ),
                child: Row(
                  children: [
                    // Delete button - subtle
                    TextButton.icon(
                      icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
                      label: Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.red[400]),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDelete(s);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const Spacer(),
                    // Mark as read/unread
                    if (!s.isRead)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.mark_email_read, size: 18),
                        label: const Text('Marquer lu'),
                        onPressed: () {
                          ref.read(suggestionsProvider.notifier).markAsRead(s.id);
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          side: BorderSide(color: Colors.grey[300]!),
                          foregroundColor: Colors.grey[700],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        icon: const Icon(Icons.mark_email_unread, size: 18),
                        label: const Text('Non lu'),
                        onPressed: () {
                          ref.read(suggestionsProvider.notifier).markAsUnread(s.id);
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          side: BorderSide(color: Colors.grey[300]!),
                          foregroundColor: Colors.grey[700],
                        ),
                      ),
                    const SizedBox(width: 12),
                    // Reply button - prominent
                    ElevatedButton.icon(
                      icon: const Icon(Icons.reply, size: 18),
                      label: const Text('Répondre'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReplyDialog(context, ref, s);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: typeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
}

class _SuggestionCard extends StatelessWidget {
  final Suggestion suggestion;
  final String searchQuery;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onSelect;
  final Function(String) onAction;

  const _SuggestionCard({
    required this.suggestion,
    required this.searchQuery,
    required this.isSelected,
    required this.selectionMode,
    required this.onSelect,
    required this.onAction,
  });

  /// Get color for suggestion type
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

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final typeColor = _getTypeColor(s.suggestionType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shadowColor: isSelected ? Colors.blue.withOpacity(0.3) : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: Colors.blue.shade400, width: 2)
            : s.isRead 
                ? BorderSide.none
                : BorderSide(color: typeColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: selectionMode ? onSelect : () => onAction('view'),
        onLongPress: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: User Avatar (like announcement type icon)
              GestureDetector(
                onTap: selectionMode ? null : () => onAction('viewStudent'),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        typeColor.withOpacity(0.8),
                        typeColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          s.studentName?.substring(0, 1).toUpperCase() ?? 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      // Unread indicator
                      if (!s.isRead)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              
              // Middle: Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Subject + Selection checkbox
                    Row(
                      children: [
                        if (selectionMode) ...[
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (_) => onSelect(),
                              activeColor: Colors.blue,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: _highlightText(
                            s.subject,
                            searchQuery,
                            TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: s.isRead ? Colors.grey[800] : Colors.black,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Student info row
                    GestureDetector(
                      onTap: selectionMode ? null : () => onAction('viewStudent'),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: _highlightText(
                              s.studentName ?? 'Étudiant',
                              searchQuery,
                              TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          if (s.studentCode != null && s.studentCode!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                s.studentCode!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if (s.className != null && s.className!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.school_outlined, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 3),
                            Text(
                              s.className!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (!selectionMode) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 12,
                              color: Colors.blue.shade300,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Content preview
                    _highlightText(
                      s.content.isNotEmpty ? s.content : '(Aucun contenu)',
                      searchQuery,
                      TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    
                    // Bottom row: Type badge, status, attachments indicator, date
                    Row(
                      children: [
                        _TypeBadge(type: s.suggestionType),
                        const SizedBox(width: 8),
                        _StatusChip(status: s.status),
                        if (s.hasAttachment || s.attachments.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 12,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${s.attachments.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yy HH:mm').format(s.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Right: Action menu
              if (!selectionMode)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'reply',
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Répondre'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: s.isRead ? 'unread' : 'read',
                      child: Row(
                        children: [
                          Icon(
                            s.isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(s.isRead ? 'Marquer non lu' : 'Marquer lu'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'viewStudent',
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18),
                          const SizedBox(width: 8),
                          const Text('Voir étudiant'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
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
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case 'pending':
        bg = Colors.orange;
        label = 'En attente';
        break;
      case 'in_review':
        bg = Colors.blue;
        label = 'En cours';
        break;
      case 'replied':
        bg = Colors.green;
        label = 'Répondu';
        break;
      case 'closed':
        bg = Colors.grey;
        label = 'Fermé';
        break;
      default:
        bg = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: bg, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (type) {
      case 'reclamation_note':
        bg = const Color(0xFFEF4444);
        label = 'Note';
        break;
      case 'absence':
        bg = const Color(0xFFF59E0B);
        label = 'Absence';
        break;
      case 'emploi_temps':
        bg = const Color(0xFF3B82F6);
        label = 'EDT';
        break;
      case 'inscription':
        bg = const Color(0xFF8B5CF6);
        label = 'Inscription';
        break;
      case 'paiement':
        bg = const Color(0xFF10B981);
        label = 'Paiement';
        break;
      case 'orientation':
        bg = const Color(0xFFEC4899);
        label = 'Orientation';
        break;
      case 'bourse':
        bg = const Color(0xFF14B8A6);
        label = 'Bourse';
        break;
      case 'transport':
        bg = const Color(0xFF78716C);
        label = 'Transport';
        break;
      case 'restauration':
        bg = const Color(0xFFEAB308);
        label = 'Resto';
        break;
      case 'bibliotheque':
        bg = const Color(0xFF0EA5E9);
        label = 'Biblio';
        break;
      case 'vie_universitaire':
        bg = const Color(0xFFA855F7);
        label = 'Vie univ.';
        break;
      case 'infrastructure':
        bg = const Color(0xFF64748B);
        label = 'Infra.';
        break;
      case 'securite':
        bg = const Color(0xFFDC2626);
        label = 'Sécurité';
        break;
      case 'autre':
        bg = const Color(0xFF6B7280);
        label = 'Autre';
        break;
      default:
        bg = const Color(0xFF9CA3AF);
        label = 'Général';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final SuggestionAttachment attachment;
  const _AttachmentChip({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        attachment.isImage ? Icons.image : Icons.insert_drive_file,
        size: 16,
      ),
      label: Text(attachment.fileName, style: const TextStyle(fontSize: 12)),
      onPressed: () async {
        final uri = Uri.parse(attachment.fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
    );
  }
}

/// Horizontal preview of attachments in the card
class _AttachmentsPreview extends StatelessWidget {
  final List<SuggestionAttachment> attachments;
  const _AttachmentsPreview({required this.attachments});

  @override
  Widget build(BuildContext context) {
    final images = attachments.where((a) => a.isImage).toList();
    final files = attachments.where((a) => !a.isImage).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 6),
              Text(
                '${attachments.length} pièce(s) jointe(s)',
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final img = images[index];
                  return GestureDetector(
                    onTap: () => _showImageDialog(context, img),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img.fileUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (files.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: files
                  .map(
                    (f) => Chip(
                      avatar: const Icon(Icons.insert_drive_file, size: 14),
                      label: Text(
                        f.fileName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, SuggestionAttachment img) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(img.fileName),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    final uri = Uri.parse(img.fileUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  img.fileUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image, size: 64)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid display for attachments in the detail dialog
class _AttachmentsGrid extends StatelessWidget {
  final List<SuggestionAttachment> attachments;
  const _AttachmentsGrid({required this.attachments});

  @override
  Widget build(BuildContext context) {
    final images = attachments.where((a) => a.isImage).toList();
    final files = attachments.where((a) => !a.isImage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images grid with preview
        if (images.isNotEmpty) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: images
                .map((img) => _ImageThumbnail(attachment: img))
                .toList(),
          ),
          if (files.isNotEmpty) const SizedBox(height: 16),
        ],
        // File list
        if (files.isNotEmpty)
          ...files.map(
            (f) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insert_drive_file, color: Colors.grey),
              ),
              title: Text(f.fileName),
              subtitle: f.fileSize != null
                  ? Text(_formatFileSize(f.fileSize!))
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  final uri = Uri.parse(f.fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ImageThumbnail extends StatelessWidget {
  final SuggestionAttachment attachment;
  const _ImageThumbnail({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                attachment.fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    attachment.fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    attachment.fileUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.all(40),
                      child: const Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () async {
                      final uri = Uri.parse(attachment.fileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Text(
                  attachment.fileName,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
