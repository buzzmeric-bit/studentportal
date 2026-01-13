import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/announcements_provider.dart';
import '../../widgets/admin_sidebar.dart';

/// Text formatter that capitalizes the first letter of each word
class CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    final String formatted = _capitalizeWords(newValue.text);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    final parts = <String>[];
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      if (char == ' ' || char == '-') {
        if (buffer.isNotEmpty) {
          parts.add(_capitalizeWord(buffer.toString()));
          buffer.clear();
        }
        parts.add(char);
      } else {
        buffer.write(char);
      }
    }
    
    if (buffer.isNotEmpty) {
      parts.add(_capitalizeWord(buffer.toString()));
    }
    
    return parts.join();
  }

  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }
}

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

/// Get all searchable fields for an announcement (including formatted dates)
String _getSearchableFields(AnnouncementModel a) {
  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm EEEE MMMM', 'fr_FR');
  final timeFormatter = DateFormat('HH:mm', 'fr_FR');

  // Type labels mapping
  String typeLabel;
  switch (a.announcementType) {
    case 'teacher_absent':
      typeLabel = 'absence prof enseignant';
      break;
    case 'room_change':
      typeLabel = 'changement salle';
      break;
    case 'reminder':
      typeLabel = 'rappel';
      break;
    case 'exam':
      typeLabel = 'examen controle test';
      break;
    case 'closure':
      typeLabel = 'fermeture fermé';
      break;
    case 'trip':
      typeLabel = 'sortie voyage excursion visite';
      break;
    case 'party':
      typeLabel = 'fête événement celebration soirée';
      break;
    case 'payment':
      typeLabel = 'paiement frais cotisation';
      break;
    default:
      typeLabel = 'général general';
  }

  // Scope labels
  final scopeLabel = a.scope == 'global'
      ? 'note info global publique'
      : 'message classe';

  // Build all searchable text
  final fields = [
    a.title,
    a.content,
    a.senderLabel ?? '',
    a.className ?? '',
    typeLabel,
    scopeLabel,
    dateFormatter.format(a.createdAt),
    timeFormatter.format(a.createdAt),
    a.isPinned ? 'épinglé pinned' : '',
    a.isImportant ? 'important urgent' : '',
    a.hasAttachment ? 'pièce jointe fichier attachment' : '',
  ];

  // Add payload fields if available
  a.payload.forEach((key, value) {
    if (value != null) fields.add(value.toString());
  });

  return fields.join(' ');
}

/// Smart search: token matching, accent-insensitive, multi-field
bool _smartMatch(AnnouncementModel a, String query) {
  if (query.isEmpty) return true;
  final tokens = _normalizeForSearch(query).split(RegExp(r'\s+'));
  final searchFields = _normalizeForSearch(_getSearchableFields(a));
  return tokens.every((token) => searchFields.contains(token));
}

/// Highlight matching text in a string
Widget _highlightText(String text, String query, TextStyle? baseStyle) {
  if (query.isEmpty)
    return Text(
      text,
      style: baseStyle,
      maxLines: 2,
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
      maxLines: 2,
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
      maxLines: 2,
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
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );
}

class _MatchRange {
  int start;
  int end;
  _MatchRange(this.start, this.end);
}

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  // Filter state
  String? _filterType; // null = all types
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  bool _showFilters = false;

  // Multi-select state
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<AnnouncementModel> list) {
    setState(() {
      if (_selectedIds.length == list.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(list.map((a) => a.id));
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/announcements'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, announcementsAsync),
                if (_showFilters && !_selectionMode) _buildFilterRow(),
                if (!_selectionMode) _buildTabBar(),
                Expanded(
                  child: announcementsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text('Erreur: $e', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref
                                .read(announcementsProvider.notifier)
                                .refresh(),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                    data: (state) => _buildTabContent(context, state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18, color: Colors.blue),
          const SizedBox(width: 12),
          // Type filter dropdown
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String?>(
              value: _filterType,
              decoration: InputDecoration(
                labelText: 'Type',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tous les types'),
                ),
                const DropdownMenuItem(
                  value: 'general',
                  child: Text('Général'),
                ),
                const DropdownMenuItem(
                  value: 'teacher_absent',
                  child: Text('Absence prof'),
                ),
                const DropdownMenuItem(
                  value: 'room_change',
                  child: Text('Changement salle'),
                ),
                const DropdownMenuItem(value: 'exam', child: Text('Examen')),
                const DropdownMenuItem(
                  value: 'reminder',
                  child: Text('Rappel'),
                ),
                const DropdownMenuItem(
                  value: 'closure',
                  child: Text('Fermeture'),
                ),
                const DropdownMenuItem(
                  value: 'trip',
                  child: Text('Sortie/Voyage'),
                ),
                const DropdownMenuItem(
                  value: 'party',
                  child: Text('Événement'),
                ),
                const DropdownMenuItem(
                  value: 'payment',
                  child: Text('Paiement'),
                ),
              ],
              onChanged: (v) => setState(() => _filterType = v),
            ),
          ),
          const SizedBox(width: 16),
          // Date from
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _filterDateFrom ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _filterDateFrom = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _filterDateFrom != null
                        ? dateFormat.format(_filterDateFrom!)
                        : 'Du...',
                    style: TextStyle(
                      color: _filterDateFrom != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                  if (_filterDateFrom != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _filterDateFrom = null),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('→'),
          ),
          // Date to
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _filterDateTo ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _filterDateTo = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _filterDateTo != null
                        ? dateFormat.format(_filterDateTo!)
                        : 'Au...',
                    style: TextStyle(
                      color: _filterDateTo != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                  if (_filterDateTo != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _filterDateTo = null),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Clear all filters
          if (_filterType != null ||
              _filterDateFrom != null ||
              _filterDateTo != null)
            TextButton.icon(
              onPressed: () => setState(() {
                _filterType = null;
                _filterDateFrom = null;
                _filterDateTo = null;
              }),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Effacer'),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AsyncValue<AnnouncementsState> announcementsAsync,
  ) {
    if (_selectionMode) {
      return _buildSelectionBar(context, announcementsAsync);
    }

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
            'Annonces',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 350,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
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
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),
          // Filter toggle button
          Badge(
            isLabelVisible:
                _filterType != null ||
                _filterDateFrom != null ||
                _filterDateTo != null,
            child: IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              tooltip: 'Filtres',
              color: _showFilters ? Colors.blue : null,
            ),
          ),
          const Spacer(),
          // Selection mode button
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () => setState(() => _selectionMode = true),
            tooltip: 'Mode sélection',
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(announcementsProvider.notifier).refresh(),
            tooltip: 'Actualiser',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showComposerDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle annonce'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(
    BuildContext context,
    AsyncValue<AnnouncementsState> announcementsAsync,
  ) {
    final count = _selectedIds.length;
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
            onPressed: _exitSelectionMode,
            tooltip: 'Annuler',
          ),
          const SizedBox(width: 12),
          Text(
            '$count sélectionné(s)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          // Bulk actions
          OutlinedButton.icon(
            onPressed: count == 0 ? null : () => _bulkPin(true),
            icon: const Icon(Icons.push_pin, size: 18),
            label: const Text('Épingler'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: count == 0 ? null : () => _bulkPin(false),
            icon: const Icon(Icons.push_pin_outlined, size: 18),
            label: const Text('Désépingler'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: count == 0 ? null : () => _bulkImportant(true),
            icon: const Icon(Icons.priority_high, size: 18),
            label: const Text('Important'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: count == 0 ? null : _bulkDeleteConfirm,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _bulkPin(bool pinned) async {
    final state = ref.read(announcementsProvider).value;
    if (state == null) return;
    final selected = state.announcements
        .where((a) => _selectedIds.contains(a.id))
        .toList();
    await ref
        .read(announcementsProvider.notifier)
        .bulkTogglePin(selected, pinned);
    _exitSelectionMode();
  }

  void _bulkImportant(bool important) async {
    final state = ref.read(announcementsProvider).value;
    if (state == null) return;
    final selected = state.announcements
        .where((a) => _selectedIds.contains(a.id))
        .toList();
    await ref
        .read(announcementsProvider.notifier)
        .bulkToggleImportant(selected, important);
    _exitSelectionMode();
  }

  void _bulkDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer les annonces ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_selectedIds.length} annonce(s) ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final state = ref.read(announcementsProvider).value;
              if (state == null) return;
              final selected = state.announcements
                  .where((a) => _selectedIds.contains(a.id))
                  .toList();
              await ref
                  .read(announcementsProvider.notifier)
                  .bulkDelete(selected);
              _exitSelectionMode();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue,
        tabs: const [
          Tab(text: 'Toutes', icon: Icon(Icons.list, size: 18)),
          Tab(text: 'Notifications', icon: Icon(Icons.notifications, size: 18)),
          Tab(text: 'Messages', icon: Icon(Icons.group, size: 18)),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, AnnouncementsState state) {
    // Smart search filtering
    var filtered = state.announcements
        .where((a) => _smartMatch(a, _searchQuery))
        .toList();

    // Apply type filter
    if (_filterType != null) {
      filtered = filtered
          .where((a) => a.announcementType == _filterType)
          .toList();
    }

    // Apply date filters
    if (_filterDateFrom != null) {
      filtered = filtered
          .where(
            (a) => a.createdAt.isAfter(
              _filterDateFrom!.subtract(const Duration(days: 1)),
            ),
          )
          .toList();
    }
    if (_filterDateTo != null) {
      filtered = filtered
          .where(
            (a) => a.createdAt.isBefore(
              _filterDateTo!.add(const Duration(days: 1)),
            ),
          )
          .toList();
    }

    if (_selectionMode) {
      return _buildAnnouncementsList(filtered);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAnnouncementsList(filtered),
        _buildAnnouncementsList(
          filtered.where((a) => a.scope == 'global').toList(),
        ),
        _buildAnnouncementsList(
          filtered.where((a) => a.scope == 'class').toList(),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList(List<AnnouncementModel> list) {
    final hasFilters =
        _searchQuery.isNotEmpty ||
        _filterType != null ||
        _filterDateFrom != null ||
        _filterDateTo != null;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Aucun résultat avec ces filtres' : 'Aucune annonce',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterType = null;
                  _filterDateFrom = null;
                  _filterDateTo = null;
                }),
                child: const Text('Effacer les filtres'),
              ),
            ],
          ],
        ),
      );
    }

    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Column(
      children: [
        if (_selectionMode) _buildSelectAllBar(list),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: list.length,
            itemBuilder: (ctx, i) => _buildAnnouncementCard(list[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectAllBar(List<AnnouncementModel> list) {
    final allSelected = _selectedIds.length == list.length && list.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            tristate: _selectedIds.isNotEmpty && !allSelected,
            onChanged: (_) => _selectAll(list),
          ),
          Text(
            allSelected ? 'Tout désélectionner' : 'Tout sélectionner',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const Spacer(),
          Text(
            '${list.length} annonce(s)',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel a) {
    final typeInfo = _getTypeInfo(a.announcementType);
    final isSelected = _selectedIds.contains(a.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: a.isPinned ? 3 : 1,
      color: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Colors.blue, width: 2)
            : (a.isPinned
                  ? BorderSide(color: Colors.orange.shade300, width: 2)
                  : BorderSide.none),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _selectionMode
            ? () => _toggleSelection(a.id)
            : () => _showComposerDialog(context, announcement: a),
        onLongPress: () {
          if (!_selectionMode) {
            setState(() => _selectionMode = true);
            _toggleSelection(a.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_selectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(a.id),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeInfo.icon, color: typeInfo.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _searchQuery.isNotEmpty
                        ? _highlightText(
                            a.title.isNotEmpty ? a.title : typeInfo.label,
                            _searchQuery,
                            const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : Text(
                            a.title.isNotEmpty ? a.title : typeInfo.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  if (a.isPinned)
                    _buildBadge('Épinglé', Colors.orange, Icons.push_pin),
                  if (a.isImportant)
                    _buildBadge('Important', Colors.red, Icons.priority_high),
                  if (a.hasAttachment)
                    _buildBadge(
                      'Pièce jointe',
                      Colors.purple,
                      Icons.attach_file,
                    ),
                  if (!_selectionMode)
                    PopupMenuButton<String>(
                      onSelected: (v) => _handleAction(v, a),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(
                                a.isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(a.isPinned ? 'Désépingler' : 'Épingler'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _searchQuery.isNotEmpty
                  ? _highlightText(
                      a.content,
                      _searchQuery,
                      TextStyle(color: Colors.grey[700], height: 1.4),
                    )
                  : Text(
                      a.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], height: 1.4),
                    ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: a.scope == 'global'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          a.scope == 'global' ? Icons.public : Icons.group,
                          size: 12,
                          color: a.scope == 'global'
                              ? Colors.blue
                              : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a.scope == 'global'
                              ? 'Notification'
                              : (a.className ?? 'Message'),
                          style: TextStyle(
                            fontSize: 11,
                            color: a.scope == 'global'
                                ? Colors.blue
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeInfo.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: typeInfo.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (a.senderLabel != null) ...[
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      a.senderLabel!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(a.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _TypeInfo _getTypeInfo(String type) {
    switch (type) {
      case 'teacher_absent':
        return _TypeInfo('Absence prof', Icons.person_off, Colors.orange);
      case 'room_change':
        return _TypeInfo('Changement salle', Icons.meeting_room, Colors.purple);
      case 'reminder':
        return _TypeInfo('Rappel', Icons.alarm, Colors.blue);
      case 'exam':
        return _TypeInfo('Examen', Icons.assignment, Colors.red);
      case 'closure':
        return _TypeInfo('Fermeture', Icons.lock, Colors.grey);
      case 'trip':
        return _TypeInfo('Sortie/Voyage', Icons.directions_bus, Colors.green);
      case 'party':
        return _TypeInfo('Événement', Icons.celebration, Colors.pink);
      case 'payment':
        return _TypeInfo('Paiement', Icons.payment, Colors.indigo);
      default:
        return _TypeInfo('Général', Icons.campaign, Colors.teal);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _handleAction(String action, AnnouncementModel a) {
    switch (action) {
      case 'pin':
        ref
            .read(announcementsProvider.notifier)
            .togglePin(a.id, a.isPinned, scope: a.scope);
        break;
      case 'edit':
        _showComposerDialog(context, announcement: a);
        break;
      case 'delete':
        _confirmDelete(context, a);
        break;
    }
  }

  void _confirmDelete(BuildContext context, AnnouncementModel a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'annonce ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${a.title}" ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(announcementsProvider.notifier)
                  .delete(a.id, scope: a.scope);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showComposerDialog(
    BuildContext context, {
    AnnouncementModel? announcement,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AnnouncementComposerDialog(
        announcement: announcement,
        onSave: () {
          ref.invalidate(announcementsProvider);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _TypeInfo {
  final String label;
  final IconData icon;
  final Color color;
  _TypeInfo(this.label, this.icon, this.color);
}

// =============================================================================
// COMPOSER DIALOG
// =============================================================================

class _AnnouncementComposerDialog extends ConsumerStatefulWidget {
  final AnnouncementModel? announcement;
  final VoidCallback onSave;
  const _AnnouncementComposerDialog({this.announcement, required this.onSave});
  @override
  ConsumerState<_AnnouncementComposerDialog> createState() =>
      _AnnouncementComposerDialogState();
}

class _AnnouncementComposerDialogState
    extends ConsumerState<_AnnouncementComposerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _senderLabelCtrl;

  // Payload controllers for type-specific fields
  late TextEditingController _teacherNameCtrl;
  late TextEditingController _startDateCtrl;
  late TextEditingController _startTimeCtrl; // Separate time controller
  late TextEditingController _endDateCtrl;
  late TextEditingController _endTimeCtrl; // Separate time controller
  late TextEditingController _replacementNoteCtrl;
  late TextEditingController _subjectCtrl;
  late TextEditingController _oldRoomCtrl;
  late TextEditingController _newRoomCtrl;
  late TextEditingController _examDateCtrl; // Separate date for exam
  late TextEditingController _examTimeCtrl; // Separate time for exam
  late TextEditingController _changeDateCtrl; // Separate date for room change
  late TextEditingController _changeTimeCtrl; // Separate time for room change
  late TextEditingController _roomCtrl;
  late TextEditingController _instructionsCtrl;
  late TextEditingController _reasonCtrl;
  late TextEditingController _closedFromCtrl;
  late TextEditingController _closedToCtrl;
  late TextEditingController _reopenDateCtrl;
  late TextEditingController _dueDateCtrl;
  late TextEditingController _actionRequiredCtrl;
  // Trip controllers
  late TextEditingController _destinationCtrl;
  late TextEditingController _departureDateCtrl;
  late TextEditingController _departureTimeCtrl;
  late TextEditingController _returnDateCtrl;
  late TextEditingController _returnTimeCtrl;
  late TextEditingController _meetingPointCtrl;
  late TextEditingController _tripCostCtrl;
  late TextEditingController _tripNotesCtrl;
  // Party/Event controllers
  late TextEditingController _eventNameCtrl;
  late TextEditingController _eventDateCtrl;
  late TextEditingController _eventTimeCtrl;
  late TextEditingController _eventLocationCtrl;
  late TextEditingController _dressCodeCtrl;
  late TextEditingController _eventNotesCtrl;
  // Payment controllers
  late TextEditingController _paymentTypeCtrl;
  late TextEditingController _paymentAmountCtrl;
  late TextEditingController _paymentDueDateCtrl;
  late TextEditingController _paymentMethodCtrl;
  late TextEditingController _paymentNotesCtrl;

  String _scope = 'global';
  String? _selectedClassId;
  String _announcementType = 'general';
  String _senderType = 'administration';
  bool _isPinned = false;
  bool _isImportant = false;
  bool _isLoading = false;

  List<_PendingFile> _pendingFiles = [];
  List<Map<String, dynamic>> _existingAttachments =
      []; // Existing attachments from DB
  List<String> _attachmentsToDelete = []; // IDs to delete on save
  List<Map<String, dynamic>> _classes = [];
  bool _classesLoading = true;

  @override
  void initState() {
    super.initState();
    final a = widget.announcement;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _contentCtrl = TextEditingController(text: a?.content ?? '');
    _senderLabelCtrl = TextEditingController(text: a?.senderLabel ?? '');

    // Initialize payload controllers
    final payload = a?.payload ?? {};
    _teacherNameCtrl = TextEditingController(
      text: payload['teacher_name'] ?? '',
    );
    _startDateCtrl = TextEditingController(text: payload['start_date'] ?? '');
    _startTimeCtrl = TextEditingController(text: payload['start_time'] ?? '');
    _endDateCtrl = TextEditingController(text: payload['end_date'] ?? '');
    _endTimeCtrl = TextEditingController(text: payload['end_time'] ?? '');
    _replacementNoteCtrl = TextEditingController(
      text: payload['replacement_note'] ?? '',
    );
    _subjectCtrl = TextEditingController(text: payload['subject'] ?? '');
    _oldRoomCtrl = TextEditingController(text: payload['old_room'] ?? '');
    _newRoomCtrl = TextEditingController(text: payload['new_room'] ?? '');
    _examDateCtrl = TextEditingController(text: payload['exam_date'] ?? '');
    _examTimeCtrl = TextEditingController(text: payload['exam_time'] ?? '');
    _changeDateCtrl = TextEditingController(text: payload['change_date'] ?? '');
    _changeTimeCtrl = TextEditingController(text: payload['change_time'] ?? '');
    _roomCtrl = TextEditingController(text: payload['room'] ?? '');
    _instructionsCtrl = TextEditingController(
      text: payload['instructions'] ?? '',
    );
    _reasonCtrl = TextEditingController(text: payload['reason'] ?? '');
    _closedFromCtrl = TextEditingController(text: payload['closed_from'] ?? '');
    _closedToCtrl = TextEditingController(text: payload['closed_to'] ?? '');
    _reopenDateCtrl = TextEditingController(text: payload['reopen_date'] ?? '');
    _dueDateCtrl = TextEditingController(text: payload['due_date'] ?? '');
    _actionRequiredCtrl = TextEditingController(
      text: payload['action_required'] ?? '',
    );
    // Trip controllers
    _destinationCtrl = TextEditingController(
      text: payload['destination'] ?? '',
    );
    _departureDateCtrl = TextEditingController(
      text: payload['departure_date'] ?? '',
    );
    _departureTimeCtrl = TextEditingController(
      text: payload['departure_time'] ?? '',
    );
    _returnDateCtrl = TextEditingController(text: payload['return_date'] ?? '');
    _returnTimeCtrl = TextEditingController(text: payload['return_time'] ?? '');
    _meetingPointCtrl = TextEditingController(
      text: payload['meeting_point'] ?? '',
    );
    _tripCostCtrl = TextEditingController(text: payload['cost'] ?? '');
    _tripNotesCtrl = TextEditingController(text: payload['notes'] ?? '');
    // Party controllers
    _eventNameCtrl = TextEditingController(text: payload['event_name'] ?? '');
    _eventDateCtrl = TextEditingController(text: payload['event_date'] ?? '');
    _eventTimeCtrl = TextEditingController(text: payload['event_time'] ?? '');
    _eventLocationCtrl = TextEditingController(text: payload['location'] ?? '');
    _dressCodeCtrl = TextEditingController(text: payload['dress_code'] ?? '');
    _eventNotesCtrl = TextEditingController(text: payload['notes'] ?? '');
    // Payment controllers
    _paymentTypeCtrl = TextEditingController(
      text: payload['payment_type'] ?? '',
    );
    _paymentAmountCtrl = TextEditingController(text: payload['amount'] ?? '');
    _paymentDueDateCtrl = TextEditingController(
      text: payload['due_date'] ?? '',
    );
    _paymentMethodCtrl = TextEditingController(
      text: payload['payment_method'] ?? '',
    );
    _paymentNotesCtrl = TextEditingController(text: payload['notes'] ?? '');

    // Add listeners for real-time preview updates
    _titleCtrl.addListener(_onTextChanged);
    _contentCtrl.addListener(_onTextChanged);
    _senderLabelCtrl.addListener(_onTextChanged);

    if (a != null) {
      _scope = a.scope;
      _selectedClassId = a.targetClassId;
      _announcementType = a.announcementType;
      _senderType = a.senderType;
      _isPinned = a.isPinned;
      _isImportant = a.isImportant;
      // Load existing attachments
      if (a.hasAttachment) {
        _loadExistingAttachments(a.id, a.scope);
      }
    }
    _loadClasses();
  }

  Future<void> _loadExistingAttachments(
    String announcementId,
    String scope,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('announcement_attachments')
          .select()
          .eq('announcement_id', announcementId)
          .eq('scope', scope);
      if (mounted) {
        setState(() {
          _existingAttachments = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error loading attachments: $e');
    }
  }

  void _onTextChanged() {
    setState(() {}); // Trigger rebuild to update preview
  }

  /// Generate human-readable content from type-specific fields
  String _generateContent() {
    final extra = _contentCtrl.text.trim();
    String generated = '';

    switch (_announcementType) {
      case 'teacher_absent':
        final teacher = _teacherNameCtrl.text.trim();
        final startDate = _startDateCtrl.text.trim();
        final startTime = _startTimeCtrl.text.trim();
        final endDate = _endDateCtrl.text.trim();
        final endTime = _endTimeCtrl.text.trim();
        final replacement = _replacementNoteCtrl.text.trim();

        if (teacher.isNotEmpty) {
          generated = '$teacher sera absent';
          if (startDate.isNotEmpty) {
            if (endDate.isNotEmpty && startDate != endDate) {
              generated += ' du $startDate';
              if (startTime.isNotEmpty) generated += ' à $startTime';
              generated += ' au $endDate';
              if (endTime.isNotEmpty) generated += ' à $endTime';
            } else {
              generated += ' le $startDate';
              if (startTime.isNotEmpty && endTime.isNotEmpty) {
                generated += ' de $startTime à $endTime';
              } else if (startTime.isNotEmpty) {
                generated += ' à partir de $startTime';
              }
            }
          }
          generated += '.';
          if (replacement.isNotEmpty) generated += ' $replacement.';
        }
        break;

      case 'room_change':
        final subject = _subjectCtrl.text.trim();
        final oldRoom = _oldRoomCtrl.text.trim();
        final newRoom = _newRoomCtrl.text.trim();
        final date = _changeDateCtrl.text.trim();
        final time = _changeTimeCtrl.text.trim();

        if (oldRoom.isNotEmpty && newRoom.isNotEmpty) {
          generated = 'Le cours';
          if (subject.isNotEmpty) generated += ' de $subject';
          generated +=
              ' est déplacé de la salle $oldRoom vers la salle $newRoom';
          if (date.isNotEmpty) {
            generated += ' le $date';
            if (time.isNotEmpty) generated += ' à $time';
          }
          generated += '.';
        }
        break;

      case 'exam':
        final subject = _subjectCtrl.text.trim();
        final date = _examDateCtrl.text.trim();
        final time = _examTimeCtrl.text.trim();
        final room = _roomCtrl.text.trim();
        final instructions = _instructionsCtrl.text.trim();

        if (subject.isNotEmpty) {
          generated = 'Un examen de $subject';
          if (date.isNotEmpty) {
            generated += ' aura lieu le $date';
            if (time.isNotEmpty) generated += ' à $time';
          }
          if (room.isNotEmpty) generated += ' en salle $room';
          generated += '.';
          if (instructions.isNotEmpty) generated += ' $instructions.';
        }
        break;

      case 'closure':
        final reason = _reasonCtrl.text.trim();
        final from = _closedFromCtrl.text.trim();
        final to = _closedToCtrl.text.trim();
        final reopen = _reopenDateCtrl.text.trim();

        generated = 'L\'établissement sera fermé';
        if (reason.isNotEmpty) generated += ' pour $reason';
        if (from.isNotEmpty) {
          if (to.isNotEmpty) {
            generated += ' du $from au $to';
          } else {
            generated += ' le $from';
          }
        }
        generated += '.';
        if (reopen.isNotEmpty) generated += ' Réouverture prévue le $reopen.';
        break;

      case 'reminder':
        final dueDate = _dueDateCtrl.text.trim();
        final action = _actionRequiredCtrl.text.trim();

        if (action.isNotEmpty) {
          generated = 'Rappel: $action';
          if (dueDate.isNotEmpty) generated += '. Date limite: $dueDate';
          generated += '.';
        } else if (dueDate.isNotEmpty) {
          generated = 'Date limite: $dueDate.';
        }
        break;

      case 'trip':
        final destination = _destinationCtrl.text.trim();
        final departDate = _departureDateCtrl.text.trim();
        final departTime = _departureTimeCtrl.text.trim();
        final returnDate = _returnDateCtrl.text.trim();
        final returnTime = _returnTimeCtrl.text.trim();
        final meetingPoint = _meetingPointCtrl.text.trim();
        final cost = _tripCostCtrl.text.trim();
        final notes = _tripNotesCtrl.text.trim();

        if (destination.isNotEmpty) {
          generated = 'Une sortie à $destination est organisée';
          if (departDate.isNotEmpty) {
            generated += ' le $departDate';
            if (departTime.isNotEmpty) generated += ' à $departTime';
          }
          generated += '.';
          if (returnDate.isNotEmpty) {
            generated += ' Retour prévu le $returnDate';
            if (returnTime.isNotEmpty) generated += ' à $returnTime';
            generated += '.';
          }
          if (meetingPoint.isNotEmpty)
            generated += ' Rendez-vous: $meetingPoint.';
          if (cost.isNotEmpty) generated += ' Coût: $cost.';
          if (notes.isNotEmpty) generated += ' $notes';
        }
        break;

      case 'party':
        final eventName = _eventNameCtrl.text.trim();
        final eventDate = _eventDateCtrl.text.trim();
        final eventTime = _eventTimeCtrl.text.trim();
        final location = _eventLocationCtrl.text.trim();
        final dressCode = _dressCodeCtrl.text.trim();
        final notes = _eventNotesCtrl.text.trim();

        if (eventName.isNotEmpty) {
          generated = '$eventName';
          if (eventDate.isNotEmpty) {
            generated += ' aura lieu le $eventDate';
            if (eventTime.isNotEmpty) generated += ' à $eventTime';
          }
          generated += '.';
          if (location.isNotEmpty) generated += ' Lieu: $location.';
          if (dressCode.isNotEmpty) generated += ' Tenue: $dressCode.';
          if (notes.isNotEmpty) generated += ' $notes';
        }
        break;

      case 'payment':
        final paymentType = _paymentTypeCtrl.text.trim();
        final amount = _paymentAmountCtrl.text.trim();
        final dueDate = _paymentDueDateCtrl.text.trim();
        final method = _paymentMethodCtrl.text.trim();
        final notes = _paymentNotesCtrl.text.trim();

        final typeLabels = {
          'frais_scolarite': 'Frais de scolarité',
          'frais_inscription': 'Frais d\'inscription',
          'frais_sortie': 'Frais de sortie',
          'frais_materiel': 'Frais de matériel',
          'cotisation': 'Cotisation',
          'autre': 'Paiement',
        };
        final typeLabel = typeLabels[paymentType] ?? 'Paiement';

        generated = '$typeLabel';
        if (amount.isNotEmpty) generated += ' de $amount';
        generated += ' à régler';
        if (dueDate.isNotEmpty) generated += ' avant le $dueDate';
        generated += '.';
        if (method.isNotEmpty) generated += ' Mode de paiement: $method.';
        if (notes.isNotEmpty) generated += ' $notes';
        break;
    }

    // Add extra remarks if provided
    if (extra.isNotEmpty) {
      generated = generated.isNotEmpty ? '$generated $extra' : extra;
    }

    return generated;
  }

  // Date picker helper
  Future<void> _pickDate(
    TextEditingController ctrl, {
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionner une date',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );
    if (picked != null) {
      ctrl.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {});
    }
  }

  // Time picker helper
  Future<void> _pickTime(
    TextEditingController ctrl, {
    TimeOfDay? initialTime,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      helpText: 'Sélectionner une heure',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );
    if (picked != null) {
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  // Build a date field with picker
  Widget _buildDateField(
    TextEditingController ctrl,
    String label, {
    Color? iconColor,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
        isDense: true,
        prefixIcon: Icon(Icons.calendar_today, color: iconColor),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(() => ctrl.clear()),
              )
            : null,
        hintText: 'Cliquez pour sélectionner',
      ),
      onTap: () => _pickDate(ctrl),
    );
  }

  // Build a time field with picker
  Widget _buildTimeField(
    TextEditingController ctrl,
    String label, {
    Color? iconColor,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        prefixIcon: Icon(Icons.access_time, color: iconColor),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(() => ctrl.clear()),
              )
            : null,
        hintText: 'Cliquez pour sélectionner',
      ),
      onTap: () => _pickTime(ctrl),
    );
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTextChanged);
    _contentCtrl.removeListener(_onTextChanged);
    _senderLabelCtrl.removeListener(_onTextChanged);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _senderLabelCtrl.dispose();
    // Dispose payload controllers
    _teacherNameCtrl.dispose();
    _startDateCtrl.dispose();
    _startTimeCtrl.dispose();
    _endDateCtrl.dispose();
    _endTimeCtrl.dispose();
    _replacementNoteCtrl.dispose();
    _subjectCtrl.dispose();
    _oldRoomCtrl.dispose();
    _newRoomCtrl.dispose();
    _examDateCtrl.dispose();
    _examTimeCtrl.dispose();
    _changeDateCtrl.dispose();
    _changeTimeCtrl.dispose();
    _roomCtrl.dispose();
    _instructionsCtrl.dispose();
    _reasonCtrl.dispose();
    _closedFromCtrl.dispose();
    _closedToCtrl.dispose();
    _reopenDateCtrl.dispose();
    _dueDateCtrl.dispose();
    _actionRequiredCtrl.dispose();
    // Dispose new controllers
    _destinationCtrl.dispose();
    _departureDateCtrl.dispose();
    _departureTimeCtrl.dispose();
    _returnDateCtrl.dispose();
    _returnTimeCtrl.dispose();
    _meetingPointCtrl.dispose();
    _tripCostCtrl.dispose();
    _tripNotesCtrl.dispose();
    _eventNameCtrl.dispose();
    _eventDateCtrl.dispose();
    _eventTimeCtrl.dispose();
    _eventLocationCtrl.dispose();
    _dressCodeCtrl.dispose();
    _eventNotesCtrl.dispose();
    _paymentTypeCtrl.dispose();
    _paymentAmountCtrl.dispose();
    _paymentDueDateCtrl.dispose();
    _paymentMethodCtrl.dispose();
    _paymentNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final notifier = ref.read(announcementsProvider.notifier);
      final data = await notifier.fetchClasses();
      setState(() {
        _classes = data;
        _classesLoading = false;
      });
    } catch (e) {
      setState(() => _classesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.announcement != null;
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 850),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isEditing),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isEditing)
                        _buildScopeSelector()
                      else
                        _buildScopeBadge(),
                      const SizedBox(height: 20),
                      if (_scope == 'class' && !isEditing)
                        _buildClassSelector(),
                      _buildTypeSelector(),
                      const SizedBox(height: 8),
                      _buildTypeSpecificFields(), // Type-specific form fields
                      const SizedBox(height: 20),
                      if (_scope == 'class') _buildSenderSelector(),
                      // Title field only for general announcements
                      if (_announcementType == 'general') ...[
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Titre *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          inputFormatters: [CapitalizeWordsFormatter()],
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Le titre est requis'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Contenu *',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Le contenu est requis'
                              : null,
                        ),
                      ],
                      // For typed announcements, content is auto-generated
                      if (_announcementType != 'general') ...[
                        TextFormField(
                          controller: _contentCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Remarques supplémentaires (optionnel)',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                            hintText: 'Ajouter des détails si nécessaire...',
                          ),
                          maxLines: 3,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildOptions(),
                      const SizedBox(height: 20),
                      _buildAttachmentsSection(),
                      const SizedBox(height: 20),
                      _buildPreview(),
                    ],
                  ),
                ),
              ),
              _buildActions(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(isEditing ? Icons.edit : Icons.add_circle, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Modifier l\'annonce' : 'Nouvelle annonce',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de publication',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'global',
              label: Text('Notification'),
              icon: Icon(Icons.notifications),
            ),
            ButtonSegment(
              value: 'class',
              label: Text('Message classe'),
              icon: Icon(Icons.group),
            ),
          ],
          selected: {_scope},
          onSelectionChanged: (s) => setState(() {
            _scope = s.first;
            _selectedClassId = null;
            if (_scope == 'global') _senderType = 'administration';
          }),
        ),
      ],
    );
  }

  Widget _buildScopeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _scope == 'global'
            ? Colors.blue.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _scope == 'global'
              ? Colors.blue.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _scope == 'global' ? Icons.public : Icons.group,
            color: _scope == 'global' ? Colors.blue : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            _scope == 'global' ? 'Notification' : 'Message de classe',
            style: TextStyle(
              color: _scope == 'global' ? Colors.blue : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.announcement?.className != null) ...[
            const SizedBox(width: 8),
            Text(
              '- ${widget.announcement!.className}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classe destinataire *',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _classesLoading
            ? const LinearProgressIndicator()
            : _classes.isEmpty
            ? Text(
                'Aucune classe disponible',
                style: TextStyle(color: Colors.grey[600]),
              )
            : DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                  hintText: 'Sélectionner une classe',
                ),
                items: _classes
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text('${c['level'] ?? ''} ${c['name']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedClassId = v),
                validator: (v) => _scope == 'class' && v == null
                    ? 'Sélectionnez une classe'
                    : null,
              ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type d\'annonce',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTypeChip('general', 'Général', Icons.campaign, Colors.teal),
            _buildTypeChip(
              'teacher_absent',
              'Absence prof',
              Icons.person_off,
              Colors.orange,
            ),
            _buildTypeChip(
              'room_change',
              'Changement salle',
              Icons.meeting_room,
              Colors.purple,
            ),
            _buildTypeChip('exam', 'Examen', Icons.assignment, Colors.red),
            _buildTypeChip('reminder', 'Rappel', Icons.alarm, Colors.blue),
            _buildTypeChip(
              'trip',
              'Sortie/Voyage',
              Icons.directions_bus,
              Colors.green,
            ),
            _buildTypeChip(
              'party',
              'Événement',
              Icons.celebration,
              Colors.pink,
            ),
            _buildTypeChip('payment', 'Paiement', Icons.payment, Colors.indigo),
            _buildTypeChip('closure', 'Fermeture', Icons.lock, Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final selected = _announcementType == value;
    return FilterChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (_) {
        setState(() => _announcementType = value);
      },
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
    );
  }

  /// Type-specific form fields based on announcement type
  Widget _buildTypeSpecificFields() {
    switch (_announcementType) {
      case 'teacher_absent':
        return _buildTeacherAbsentForm();
      case 'room_change':
        return _buildRoomChangeForm();
      case 'exam':
        return _buildExamForm();
      case 'closure':
        return _buildClosureForm();
      case 'reminder':
        return _buildReminderForm();
      case 'trip':
        return _buildTripForm();
      case 'party':
        return _buildPartyForm();
      case 'payment':
        return _buildPaymentForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTeacherAbsentForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_off, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Détails de l\'absence',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _teacherNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'enseignant *',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.person),
            ),
            inputFormatters: [CapitalizeWordsFormatter()],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  _startDateCtrl,
                  'Date début',
                  iconColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  _startTimeCtrl,
                  'Heure début',
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  _endDateCtrl,
                  'Date fin',
                  iconColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  _endTimeCtrl,
                  'Heure fin',
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _replacementNoteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note de remplacement (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Ex: M. Alami assurera les cours',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomChangeForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.meeting_room, color: Colors.purple, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Détails du changement',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Matière (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.book),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _oldRoomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ancienne salle',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.door_back_door),
                  ),
                  inputFormatters: [CapitalizeWordsFormatter()],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.purple),
              ),
              Expanded(
                child: TextFormField(
                  controller: _newRoomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nouvelle salle',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.door_front_door),
                  ),
                  inputFormatters: [CapitalizeWordsFormatter()],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  _changeDateCtrl,
                  'Date',
                  iconColor: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  _changeTimeCtrl,
                  'Heure',
                  iconColor: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Détails de l\'examen',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Matière *',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.book),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  _examDateCtrl,
                  'Date',
                  iconColor: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  _examTimeCtrl,
                  'Heure',
                  iconColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _roomCtrl,
            decoration: const InputDecoration(
              labelText: 'Salle',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.meeting_room),
            ),
            inputFormatters: [CapitalizeWordsFormatter()],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _instructionsCtrl,
            decoration: const InputDecoration(
              labelText: 'Instructions (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Ex: Apporter calculatrice',
              prefixIcon: Icon(Icons.info_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildClosureForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.grey[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Détails de la fermeture',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Raison de la fermeture',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Ex: Travaux, Journée pédagogique',
              prefixIcon: Icon(Icons.help_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  _closedFromCtrl,
                  'Fermé du',
                  iconColor: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  _closedToCtrl,
                  'Au',
                  iconColor: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDateField(
            _reopenDateCtrl,
            'Date de réouverture',
            iconColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alarm, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Détails du rappel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDateField(
            _dueDateCtrl,
            'Date limite',
            iconColor: Colors.blue,
            required: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _actionRequiredCtrl,
            decoration: const InputDecoration(
              labelText: 'Action requise',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Ex: Inscription aux examens',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildTripForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Détails de la sortie/voyage',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _destinationCtrl,
            decoration: const InputDecoration(
              labelText: 'Destination *',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.place),
            ),
            inputFormatters: [CapitalizeWordsFormatter()],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  _departureDateCtrl,
                  'Date départ',
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  _departureTimeCtrl,
                  'Heure départ',
                  iconColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  _returnDateCtrl,
                  'Date retour',
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  _returnTimeCtrl,
                  'Heure retour',
                  iconColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _meetingPointCtrl,
            decoration: const InputDecoration(
              labelText: 'Point de rendez-vous',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.location_on),
              hintText: 'Ex: Devant l\'entrée principale',
            ),
            inputFormatters: [CapitalizeWordsFormatter()],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tripCostCtrl,
            decoration: const InputDecoration(
              labelText: 'Coût (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.attach_money),
              hintText: 'Ex: 150 DH',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tripNotesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Informations supplémentaires...',
            ),
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.pink.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration, color: Colors.pink, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Détails de l\'événement',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _eventNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'événement *',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.event),
              hintText: 'Ex: Fête de fin d\'année',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  _eventDateCtrl,
                  'Date',
                  iconColor: Colors.pink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  _eventTimeCtrl,
                  'Heure',
                  iconColor: Colors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _eventLocationCtrl,
            decoration: const InputDecoration(
              labelText: 'Lieu',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.location_on),
              hintText: 'Ex: Salle des fêtes',
            ),
            inputFormatters: [CapitalizeWordsFormatter()],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dressCodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Code vestimentaire (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.checkroom),
              hintText: 'Ex: Tenue de soirée',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _eventNotesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Informations supplémentaires...',
            ),
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.indigo, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Détails du paiement',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _paymentTypeCtrl.text.isEmpty ? null : _paymentTypeCtrl.text,
            decoration: const InputDecoration(
              labelText: 'Type de paiement *',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(
                value: 'frais_scolarite',
                child: Text('Frais de scolarité'),
              ),
              DropdownMenuItem(
                value: 'frais_inscription',
                child: Text('Frais d\'inscription'),
              ),
              DropdownMenuItem(
                value: 'frais_sortie',
                child: Text('Frais de sortie/voyage'),
              ),
              DropdownMenuItem(
                value: 'frais_materiel',
                child: Text('Frais de matériel'),
              ),
              DropdownMenuItem(value: 'cotisation', child: Text('Cotisation')),
              DropdownMenuItem(value: 'autre', child: Text('Autre')),
            ],
            onChanged: (v) => setState(() => _paymentTypeCtrl.text = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _paymentAmountCtrl,
            decoration: const InputDecoration(
              labelText: 'Montant *',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.attach_money),
              hintText: 'Ex: 500 DH',
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildDateField(
            _paymentDueDateCtrl,
            'Date limite de paiement',
            iconColor: Colors.indigo,
            required: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _paymentMethodCtrl,
            decoration: const InputDecoration(
              labelText: 'Mode de paiement (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.credit_card),
              hintText: 'Ex: Espèces, virement, chèque',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _paymentNotesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Informations supplémentaires...',
            ),
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  /// Build payload JSON from type-specific fields
  Map<String, dynamic> _buildPayload() {
    switch (_announcementType) {
      case 'teacher_absent':
        return {
          'teacher_name': _teacherNameCtrl.text.trim(),
          'start_date': _startDateCtrl.text.trim(),
          'start_time': _startTimeCtrl.text.trim(),
          'end_date': _endDateCtrl.text.trim(),
          'end_time': _endTimeCtrl.text.trim(),
          'replacement_note': _replacementNoteCtrl.text.trim(),
        };
      case 'room_change':
        return {
          'subject': _subjectCtrl.text.trim(),
          'old_room': _oldRoomCtrl.text.trim(),
          'new_room': _newRoomCtrl.text.trim(),
          'change_date': _changeDateCtrl.text.trim(),
          'change_time': _changeTimeCtrl.text.trim(),
        };
      case 'exam':
        return {
          'subject': _subjectCtrl.text.trim(),
          'exam_date': _examDateCtrl.text.trim(),
          'exam_time': _examTimeCtrl.text.trim(),
          'room': _roomCtrl.text.trim(),
          'instructions': _instructionsCtrl.text.trim(),
        };
      case 'closure':
        return {
          'reason': _reasonCtrl.text.trim(),
          'closed_from': _closedFromCtrl.text.trim(),
          'closed_to': _closedToCtrl.text.trim(),
          'reopen_date': _reopenDateCtrl.text.trim(),
        };
      case 'reminder':
        return {
          'due_date': _dueDateCtrl.text.trim(),
          'action_required': _actionRequiredCtrl.text.trim(),
        };
      case 'trip':
        return {
          'destination': _destinationCtrl.text.trim(),
          'departure_date': _departureDateCtrl.text.trim(),
          'departure_time': _departureTimeCtrl.text.trim(),
          'return_date': _returnDateCtrl.text.trim(),
          'return_time': _returnTimeCtrl.text.trim(),
          'meeting_point': _meetingPointCtrl.text.trim(),
          'cost': _tripCostCtrl.text.trim(),
          'notes': _tripNotesCtrl.text.trim(),
        };
      case 'party':
        return {
          'event_name': _eventNameCtrl.text.trim(),
          'event_date': _eventDateCtrl.text.trim(),
          'event_time': _eventTimeCtrl.text.trim(),
          'location': _eventLocationCtrl.text.trim(),
          'dress_code': _dressCodeCtrl.text.trim(),
          'notes': _eventNotesCtrl.text.trim(),
        };
      case 'payment':
        return {
          'payment_type': _paymentTypeCtrl.text.trim(),
          'amount': _paymentAmountCtrl.text.trim(),
          'due_date': _paymentDueDateCtrl.text.trim(),
          'payment_method': _paymentMethodCtrl.text.trim(),
          'notes': _paymentNotesCtrl.text.trim(),
        };
      default:
        return {};
    }
  }

  Widget _buildSenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Expéditeur', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                value: 'administration',
                groupValue: _senderType,
                title: const Text('Administration'),
                onChanged: (v) => setState(() => _senderType = v!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                value: 'teacher',
                groupValue: _senderType,
                title: const Text('Professeur'),
                onChanged: (v) => setState(() => _senderType = v!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_senderType == 'teacher') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _senderLabelCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom du professeur',
              hintText: 'Ex: Prof. Benali',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            inputFormatters: [CapitalizeWordsFormatter()],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOptions() {
    return Row(
      children: [
        Expanded(
          child: CheckboxListTile(
            value: _isPinned,
            onChanged: (v) => setState(() => _isPinned = v ?? false),
            title: Text(_isPinned ? 'Désépingler' : 'Épingler'),
            subtitle: Text(_isPinned ? 'Retirer du haut' : 'Afficher en haut'),
            secondary: Icon(
              _isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              color: _isPinned ? Colors.orange : Colors.grey,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        Expanded(
          child: CheckboxListTile(
            value: _isImportant,
            onChanged: (v) => setState(() => _isImportant = v ?? false),
            title: const Text('Important'),
            subtitle: const Text('Badge rouge'),
            secondary: Icon(
              Icons.priority_high,
              color: _isImportant ? Colors.red : Colors.grey,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    final imageFiles = _pendingFiles
        .where((f) => f.mimeType.startsWith('image/'))
        .toList();
    final otherFiles = _pendingFiles
        .where((f) => !f.mimeType.startsWith('image/'))
        .toList();

    // Filter existing attachments (exclude those marked for deletion)
    final existingImages = _existingAttachments
        .where(
          (a) =>
              !_attachmentsToDelete.contains(a['id']) &&
              (a['file_type']?.toString().startsWith('image/') ?? false),
        )
        .toList();
    final existingFiles = _existingAttachments
        .where(
          (a) =>
              !_attachmentsToDelete.contains(a['id']) &&
              !(a['file_type']?.toString().startsWith('image/') ?? false),
        )
        .toList();

    final hasContent =
        _pendingFiles.isNotEmpty ||
        existingImages.isNotEmpty ||
        existingFiles.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pièces jointes',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasContent)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune pièce jointe',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Existing images from database
          if (existingImages.isNotEmpty) ...[
            const Text(
              'Images existantes',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: existingImages.map((att) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        att['file_url'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _attachmentsToDelete.add(att['id'])),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          // New images to upload
          if (imageFiles.isNotEmpty) ...[
            const Text(
              'Nouvelles images',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: imageFiles.map((f) {
                final index = _pendingFiles.indexOf(f);
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        f.bytes,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _pendingFiles.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          // Existing files from database
          if (existingFiles.isNotEmpty) ...[
            const Text(
              'Documents existants',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Column(
              children: existingFiles.map((att) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _getFileIcon(att['file_type'] ?? ''),
                    color: Colors.blue,
                  ),
                  title: Text(
                    att['display_name'] ?? att['file_name'] ?? 'Document',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_formatBytes(att['file_size'] ?? 0)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editExistingFileName(att),
                        tooltip: 'Modifier le nom',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            setState(() => _attachmentsToDelete.add(att['id'])),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          // New files to upload
          if (otherFiles.isNotEmpty) ...[
            const Text(
              'Nouveaux documents',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Column(
              children: otherFiles.map((f) {
                final index = _pendingFiles.indexOf(f);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_getFileIcon(f.mimeType), color: Colors.blue),
                  title: Text(
                    f.customDisplayName ?? f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_formatBytes(f.bytes.length)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editFileName(f),
                        tooltip: 'Modifier le nom',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            setState(() => _pendingFiles.removeAt(index)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPreview() {
    final typeInfo = _getPreviewTypeInfo(_announcementType);
    // For typed announcements, show type label as title and generate content preview
    final previewTitle = _announcementType == 'general'
        ? (_titleCtrl.text.isEmpty ? 'Titre de l\'annonce...' : _titleCtrl.text)
        : typeInfo.label;
    final previewContent = _announcementType == 'general'
        ? (_contentCtrl.text.isEmpty
              ? 'Le contenu de votre annonce apparaîtra ici...'
              : _contentCtrl.text)
        : (_generateContent().isEmpty
              ? 'Remplissez les champs ci-dessus...'
              : _generateContent());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Aperçu en temps réel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Icon(Icons.visibility, size: 16, color: Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: _isPinned
                ? BorderSide(color: Colors.orange.shade300, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with type icon and badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        typeInfo.icon,
                        color: typeInfo.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        previewTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isPinned)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.push_pin,
                              size: 12,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Épinglé',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isImportant)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.priority_high,
                              size: 12,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Important',
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Content
                Text(
                  previewContent,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                // Footer with scope, type and sender
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _scope == 'global'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _scope == 'global' ? Icons.public : Icons.group,
                            size: 12,
                            color: _scope == 'global'
                                ? Colors.blue
                                : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _scope == 'global' ? 'Notification' : 'Message',
                            style: TextStyle(
                              fontSize: 11,
                              color: _scope == 'global'
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeInfo.label,
                        style: TextStyle(fontSize: 11, color: typeInfo.color),
                      ),
                    ),
                    if (_senderType == 'teacher' &&
                        _senderLabelCtrl.text.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        child: Text(
                          _senderLabelCtrl.text[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _senderLabelCtrl.text,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                    const Spacer(),
                    Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'À l\'instant',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                if (_pendingFiles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPreviewImageGallery(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewImageGallery() {
    final imageFiles = _pendingFiles
        .where((f) => f.mimeType.startsWith('image/'))
        .toList();
    final otherFiles = _pendingFiles
        .where((f) => !f.mimeType.startsWith('image/'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show images in Facebook-style grid
        if (imageFiles.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 150,
              child: imageFiles.length == 1
                  ? Image.memory(
                      imageFiles[0].bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Image.memory(
                            imageFiles[0].bytes,
                            fit: BoxFit.cover,
                            height: 150,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Column(
                            children: [
                              if (imageFiles.length > 1)
                                Expanded(
                                  child: Image.memory(
                                    imageFiles[1].bytes,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              if (imageFiles.length > 2) ...[
                                const SizedBox(height: 2),
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(
                                        imageFiles[2].bytes,
                                        fit: BoxFit.cover,
                                      ),
                                      if (imageFiles.length > 3)
                                        Container(
                                          color: Colors.black45,
                                          child: Center(
                                            child: Text(
                                              '+${imageFiles.length - 3}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        // Show file attachments count
        if (otherFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.attach_file, size: 14, color: Colors.purple[300]),
              const SizedBox(width: 4),
              Text(
                '${otherFiles.length} document(s)',
                style: TextStyle(fontSize: 11, color: Colors.purple[400]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  _TypeInfo _getPreviewTypeInfo(String type) {
    switch (type) {
      case 'teacher_absent':
        return _TypeInfo('Absence prof', Icons.person_off, Colors.orange);
      case 'room_change':
        return _TypeInfo('Changement salle', Icons.meeting_room, Colors.purple);
      case 'reminder':
        return _TypeInfo('Rappel', Icons.alarm, Colors.blue);
      case 'exam':
        return _TypeInfo('Examen', Icons.assignment, Colors.red);
      case 'closure':
        return _TypeInfo('Fermeture', Icons.lock, Colors.grey);
      default:
        return _TypeInfo('Général', Icons.campaign, Colors.teal);
    }
  }

  Widget _buildActions(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isEditing ? Icons.save : Icons.send),
            label: Text(isEditing ? 'Enregistrer' : 'Publier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
        withData: true,
      );
      if (result != null) {
        for (final f in result.files) {
          if (f.bytes == null) continue;
          final mimeType = _getMimeType(f.extension ?? '');

          // For images, compress and resize if too large
          if (mimeType.startsWith('image/')) {
            final compressedResult = await _compressImage(
              f.bytes!,
              f.name,
              mimeType,
            );
            if (compressedResult != null) {
              setState(() {
                _pendingFiles.add(
                  _PendingFile(
                    name: compressedResult.name,
                    bytes: compressedResult.bytes,
                    mimeType: compressedResult.mimeType,
                  ),
                );
              });

              // Show compression info
              if (compressedResult.wasCompressed && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${f.name}: ${_formatBytes(f.bytes!.length)} → ${_formatBytes(compressedResult.bytes.length)}',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          } else {
            // Non-image files: add directly
            setState(() {
              _pendingFiles.add(
                _PendingFile(name: f.name, bytes: f.bytes!, mimeType: mimeType),
              );
            });
          }
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
    }
  }

  /// Compress and resize image if needed (max 1200px width, max 500KB)
  Future<_CompressedImage?> _compressImage(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        // Can't decode, return original
        return _CompressedImage(
          name: fileName,
          bytes: bytes,
          mimeType: mimeType,
          wasCompressed: false,
        );
      }

      // Max dimensions (good for announcements)
      const maxWidth = 1200;
      const maxHeight = 1200;
      const maxSizeBytes = 500 * 1024; // 500KB target

      var processedImage = image;
      var quality = 85;

      // Resize if too large
      if (image.width > maxWidth || image.height > maxHeight) {
        final ratio = (image.width > image.height)
            ? maxWidth / image.width
            : maxHeight / image.height;
        final newWidth = (image.width * ratio).round();
        final newHeight = (image.height * ratio).round();
        processedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode with compression
      Uint8List compressed;
      String outputMime = mimeType;
      String outputName = fileName;

      if (mimeType == 'image/png') {
        // Convert large PNGs to JPEG for better compression
        if (bytes.length > maxSizeBytes) {
          compressed = Uint8List.fromList(
            img.encodeJpg(processedImage, quality: quality),
          );
          outputMime = 'image/jpeg';
          outputName = fileName.replaceAll(
            RegExp(r'\.png$', caseSensitive: false),
            '.jpg',
          );
        } else {
          compressed = Uint8List.fromList(img.encodePng(processedImage));
        }
      } else {
        // JPEG - compress with quality reduction if needed
        compressed = Uint8List.fromList(
          img.encodeJpg(processedImage, quality: quality),
        );

        // Further reduce quality if still too large
        while (compressed.length > maxSizeBytes && quality > 50) {
          quality -= 10;
          compressed = Uint8List.fromList(
            img.encodeJpg(processedImage, quality: quality),
          );
        }
      }

      final wasCompressed = compressed.length < bytes.length;
      return _CompressedImage(
        name: outputName,
        bytes: wasCompressed ? compressed : bytes,
        mimeType: wasCompressed ? outputMime : mimeType,
        wasCompressed: wasCompressed,
      );
    } catch (e) {
      // If compression fails, return original
      debugPrint('Image compression failed: $e');
      return _CompressedImage(
        name: fileName,
        bytes: bytes,
        mimeType: mimeType,
        wasCompressed: false,
      );
    }
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document'))
      return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet'))
      return Icons.table_chart;
    return Icons.attach_file;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _editFileName(_PendingFile file) async {
    final controller = TextEditingController(text: file.customDisplayName ?? file.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom du fichier'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom du fichier',
            hintText: 'Ex: Document important',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        file.customDisplayName = result;
      });
    }
  }

  Future<void> _editExistingFileName(Map<String, dynamic> att) async {
    final controller = TextEditingController(text: att['display_name'] ?? att['file_name']);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom du fichier'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom du fichier',
            hintText: 'Ex: Document important',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        att['display_name'] = result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scope == 'class' &&
        _selectedClassId == null &&
        widget.announcement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une classe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(announcementsProvider.notifier);
      final payload = _buildPayload();

      // For typed announcements, generate content automatically
      // Title stays empty for typed announcements (type label will be shown)
      final title = _announcementType == 'general'
          ? _titleCtrl.text.trim()
          : '';
      final content = _announcementType == 'general'
          ? _contentCtrl.text.trim()
          : _generateContent();

      if (widget.announcement != null) {
        // Editing existing announcement
        await notifier.updateAnnouncement(
          id: widget.announcement!.id,
          title: title,
          content: content,
          targetClassId: widget.announcement!.targetClassId,
          isPinned: _isPinned,
          isImportant: _isImportant,
          scope: _scope,
          announcementType: _announcementType,
          senderType: _senderType,
          senderLabel: _senderType == 'teacher'
              ? _senderLabelCtrl.text.trim()
              : null,
          payload: payload,
        );

        // Delete marked attachments
        for (final attId in _attachmentsToDelete) {
          try {
            await notifier.deleteAttachment(attId);
            debugPrint('Deleted attachment: $attId');
          } catch (e) {
            debugPrint('Delete attachment error: $e');
          }
        }

        // Upload new attachments
        if (_pendingFiles.isNotEmpty) {
          for (final file in _pendingFiles) {
            try {
              await notifier.uploadAttachment(
                announcementId: widget.announcement!.id,
                scope: _scope,
                fileName: file.name,
                fileBytes: file.bytes,
                mimeType: file.mimeType,
                displayName: file.customDisplayName,
              );
              debugPrint('Upload success: ${file.name}');
            } catch (uploadError) {
              debugPrint('Upload error: $uploadError');
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur upload ${file.name}: $uploadError'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
            }
          }
        }
      } else {
        // Creating new announcement
        final announcementId = await notifier.create(
          title: title,
          content: content,
          targetClassId: _selectedClassId,
          isPinned: _isPinned,
          isImportant: _isImportant,
          scope: _scope,
          announcementType: _announcementType,
          senderType: _senderType,
          senderLabel: _senderType == 'teacher'
              ? _senderLabelCtrl.text.trim()
              : null,
          payload: payload,
        );
        debugPrint(
          'Created announcement: $announcementId, pending files: ${_pendingFiles.length}',
        );
        if (_pendingFiles.isNotEmpty && announcementId != null) {
          for (final file in _pendingFiles) {
            debugPrint('Uploading: ${file.name} (${file.bytes.length} bytes)');
            try {
              await notifier.uploadAttachment(
                announcementId: announcementId,
                scope: _scope,
                fileName: file.name,
                fileBytes: file.bytes,
                mimeType: file.mimeType,
                displayName: file.customDisplayName,
              );
              debugPrint('Upload success: ${file.name}');
            } catch (uploadError) {
              debugPrint('Upload error: $uploadError');
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur upload ${file.name}: $uploadError'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
            }
          }
        }
      }
      widget.onSave();
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _PendingFile {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  String? customDisplayName; // For custom file names (non-images)
  _PendingFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
}

class _CompressedImage {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  final bool wasCompressed;
  _CompressedImage({
    required this.name,
    required this.bytes,
    required this.mimeType,
    required this.wasCompressed,
  });
}
