import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/document_model.dart';
import '../../providers/student_context_provider.dart';
import '../../widgets/semester_navigator.dart';

// Semester state provider for this screen
final docsSemesterProvider = StateProvider<int>((ref) => 1);

// Demo documents provider
final documentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  return [
    DocumentModel(
      id: '1',
      schoolId: 'school1',
      title: 'Attestation de scolarité',
      description: 'Attestation de scolarité pour l\'année 2024-2025',
      category: 'administrative',
      fileUrl: 'https://example.com/attestation.pdf',
      fileName: 'attestation_scolarite_2024.pdf',
      fileSize: 256000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 9, 15),
    ),
    DocumentModel(
      id: '2',
      schoolId: 'school1',
      title: 'Relevé de notes - S1',
      description: 'Relevé de notes du premier semestre',
      category: 'administrative',
      fileUrl: 'https://example.com/releve.pdf',
      fileName: 'releve_notes_s1_2024.pdf',
      fileSize: 180000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 1, 20),
    ),
    DocumentModel(
      id: '3',
      schoolId: 'school1',
      title: 'Carte étudiant',
      description: 'Carte d\'étudiant numérique',
      category: 'administrative',
      fileUrl: 'https://example.com/carte.pdf',
      fileName: 'carte_etudiant_2024.pdf',
      fileSize: 95000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 10, 1),
    ),
    DocumentModel(
      id: '4',
      schoolId: 'school1',
      title: 'Certificat d\'inscription',
      description: 'Certificat d\'inscription pour l\'année 2024-2025',
      category: 'administrative',
      fileUrl: 'https://example.com/certificat.pdf',
      fileName: 'certificat_inscription_2024.pdf',
      fileSize: 145000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 9, 5),
    ),
    DocumentModel(
      id: '5',
      schoolId: 'school1',
      title: 'Programme annuel',
      description: 'Programme des cours pour l\'année scolaire',
      category: 'courses',
      fileUrl: 'https://example.com/programme.pdf',
      fileName: 'programme_annuel_2024.pdf',
      fileSize: 320000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 9, 1),
    ),
    DocumentModel(
      id: '6',
      schoolId: 'school1',
      title: 'Calendrier des examens',
      description: 'Planning des examens du semestre',
      category: 'exams',
      fileUrl: 'https://example.com/calendrier.pdf',
      fileName: 'calendrier_examens_s1.pdf',
      fileSize: 128000,
      mimeType: 'application/pdf',
      createdAt: DateTime(2025, 11, 1),
    ),
  ];
});

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _selectedCategory;
  
  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // iOS 26 gradient colors
  static const _gradientColors = [
    Color(0xFFE8D5F2),
    Color(0xFFD4C4E8),
    Color(0xFFC9D6F0),
    Color(0xFFE0EAF5),
    Color(0xFFF0F5FA),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documentsAsync = ref.watch(documentsProvider);
    final selectedSemester = ref.watch(docsSemesterProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar - matching other screens
              _buildHeader(l10n),
              
              // Semester Navigator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DynamicSemesterNav(
                  selectedSemesterNumber: selectedSemester,
                  onChanged: (v) => ref.read(docsSemesterProvider.notifier).state = v,
                ),
              ),
              const SizedBox(height: 12),
              
              // Content
              Expanded(
                child: documentsAsync.when(
                  data: (documents) => _buildContent(documents, l10n),
                  loading: () => _buildLoadingState(),
                  error: (error, stack) => _buildErrorState(l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideValue = Curves.easeOutCubic.transform(_animationController.value);
        final fadeIn = _isSearching ? slideValue : 1.0 - slideValue;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: SizedBox(
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Normal header
                Transform.translate(
                  offset: Offset(
                    _isSearching ? -MediaQuery.of(context).size.width * slideValue : 0,
                    0,
                  ),
                  child: Opacity(
                    opacity: _isSearching ? (1.0 - fadeIn).clamp(0.0, 1.0) : 1.0,
                    child: Row(
                      children: [
                        // Icon with gradient - matching folder icon from home
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6B5CE7), Color(0xFF8B5CF6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B5CE7).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.folder_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.documents,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[900],
                                  letterSpacing: -0.6,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Accédez aux documents',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Search button
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
                if (_isSearching)
                  Transform.translate(
                    offset: Offset(
                      MediaQuery.of(context).size.width * (1 - slideValue),
                      0,
                    ),
                    child: Opacity(
                      opacity: fadeIn.clamp(0.0, 1.0),
                      child: Row(
                        children: [
                          // Cancel button
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
                              child: Icon(Icons.close_rounded, color: Colors.grey[700], size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Search field
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
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
                                  Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      onChanged: (value) => setState(() => _searchQuery = value),
                                      cursorColor: Colors.grey[600],
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                                      decoration: InputDecoration(
                                        hintText: 'Rechercher un document...',
                                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                                        filled: false,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Icon(Icons.cancel, color: Colors.grey[400], size: 20),
                                      ),
                                    )
                                  else
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
          ),
        );
      },
    );
  }

  Widget _buildContent(List<DocumentModel> documents, AppLocalizations l10n) {
    if (documents.isEmpty) {
      return _buildEmptyState(l10n);
    }

    // Filter out courses and apply search
    var filteredDocs = documents.where((doc) => doc.category != 'courses').toList();
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredDocs = filteredDocs.where((doc) {
        return doc.title.toLowerCase().contains(query) ||
            (doc.description?.toLowerCase().contains(query) ?? false) ||
            doc.fileName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filteredDocs = filteredDocs.where((doc) => doc.category == _selectedCategory).toList();
    }

    if (filteredDocs.isEmpty) {
      return _buildEmptyState(l10n);
    }

    // Get unique categories from filtered docs
    final allCategories = documents.where((d) => d.category != 'courses').map((d) => d.category).toSet().toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(documentsProvider);
        await ref.read(documentsProvider.future);
      },
      color: const Color(0xFF6B5CE7),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimal filter chips
            _buildCategoryFilter(allCategories, l10n),
            const SizedBox(height: 20),
            
            // Documents list - flat list instead of grouped
            ...filteredDocs.asMap().entries.map((entry) => _DocumentCard(
              document: entry.value,
              animationDelay: Duration(milliseconds: 50 * entry.key),
              parentAnimation: _animationController,
            )),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories, AppLocalizations l10n) {
    // Build list with "Tous" first
    final allCategories = [null, ...categories];
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 0.7),
        ),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / allCategories.length;
              final selectedIndex = allCategories.indexOf(_selectedCategory);
              
              return Stack(
                children: [
                  // Animated pill background
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * itemWidth + 3,
                    top: 3,
                    bottom: 3,
                    width: itemWidth - 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B5CE7),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B5CE7).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Category labels
                  Row(
                    children: allCategories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      final label = cat == null ? 'Tous' : _getCategoryLabel(cat, l10n);
                      
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                              child: Text(label),
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
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6B5CE7).withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: const Color(0xFF6B5CE7).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noData,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun document disponible',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5CE7)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.error,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref.refresh(documentsProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5CE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.retry,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category, AppLocalizations l10n) {
    switch (category) {
      case 'administrative':
        return l10n.documentAdministrative;
      case 'courses':
        return 'Cours';
      case 'exams':
        return l10n.documentExams;
      default:
        return l10n.documentOther;
    }
  }
}



// Document card widget - iOS 26 premium style
class _DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final Duration animationDelay;
  final AnimationController parentAnimation;

  const _DocumentCard({
    required this.document,
    required this.animationDelay,
    required this.parentAnimation,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'administrative':
        return const Color(0xFF6B5CE7);
      case 'courses':
        return const Color(0xFF4ECDC4);
      case 'exams':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final categoryColor = _getCategoryColor(document.category);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: parentAnimation,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: parentAnimation,
          curve: const Interval(0.3, 1.0),
        ),
        child: GestureDetector(
          onTap: () => _showDocumentDetails(context, document),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // File icon - matching home screen folder style
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [categoryColor, categoryColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    document.isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (document.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          document.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 11,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(document.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (document.fileSize != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              document.displayFileSize,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentDetails(BuildContext context, DocumentModel document) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final categoryColor = _getCategoryColor(document.category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [categoryColor, categoryColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    document.isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          document.isPdf ? 'PDF' : 'Document',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: categoryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (document.description != null) ...[
              const SizedBox(height: 20),
              Text(
                document.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Info rows
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: dateFormat.format(document.createdAt),
            ),
            if (document.fileSize != null)
              _DetailRow(
                icon: Icons.storage_outlined,
                label: 'Taille',
                value: document.displayFileSize,
              ),
            _DetailRow(
              icon: Icons.insert_drive_file_outlined,
              label: 'Fichier',
              value: document.fileName,
            ),
            
            const SizedBox(height: 24),
            
            // Download button
            GestureDetector(
              onTap: () {
                // TODO: Implement download
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Téléchargement en cours...'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: categoryColor,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [categoryColor, categoryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Télécharger',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
