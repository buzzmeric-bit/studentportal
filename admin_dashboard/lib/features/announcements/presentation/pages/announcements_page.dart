import 'package:flutter/material.dart';
import '../../../../models/announcement_model.dart';
import '../../../../repositories/announcement_repository.dart';
import '../widgets/announcement_card.dart';
import '../widgets/announcement_composer_dialog.dart';

class AnnouncementsPage extends StatefulWidget {
  final String schoolId;

  const AnnouncementsPage({super.key, required this.schoolId});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnnouncementRepository _repository;
  
  List<Announcement> _allAnnouncements = [];
  bool _isLoading = true;
  String? _error;
  AnnouncementScope? _filterScope;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _repository = AnnouncementRepository();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final announcements = await _repository.fetchAnnouncements(
        schoolId: widget.schoolId,
        scopeFilter: _filterScope,
      );
      setState(() {
        _allAnnouncements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Announcement> get _globalAnnouncements =>
      _allAnnouncements.where((a) => a.scope == AnnouncementScope.global).toList();

  List<Announcement> get _classAnnouncements =>
      _allAnnouncements.where((a) => a.scope == AnnouncementScope.classScope).toList();

  List<Announcement> get _pinnedAnnouncements =>
      _allAnnouncements.where((a) => a.isPinned).toList();

  void _openComposer({Announcement? existing}) {
    showDialog(
      context: context,
      builder: (context) => AnnouncementComposerDialog(
        schoolId: widget.schoolId,
        existing: existing,
        onSaved: (announcement) {
          _loadAnnouncements();
        },
      ),
    );
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette annonce ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteAnnouncement(announcement.id, announcement.scope);
        _loadAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce supprimée')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _togglePin(Announcement announcement) async {
    try {
      await _repository.togglePinned(
        announcement.id,
        announcement.scope,
        !announcement.isPinned,
      );
      _loadAnnouncements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Notes d\'info'),
            Tab(text: 'Messages'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnnouncements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erreur: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnnouncements,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnnouncementsList(_allAnnouncements),
                    _buildAnnouncementsList(_globalAnnouncements),
                    _buildAnnouncementsList(_classAnnouncements),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openComposer(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle annonce'),
      ),
    );
  }

  Widget _buildAnnouncementsList(List<Announcement> announcements) {
    if (announcements.isEmpty) {
      return const Center(
        child: Text('Aucune annonce'),
      );
    }

    // Sort: pinned first, then by date
    final sorted = List<Announcement>.from(announcements)
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return (b.publishedAt ?? b.createdAt)
            .compareTo(a.publishedAt ?? a.createdAt);
      });

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final announcement = sorted[index];
          return AnnouncementCard(
            announcement: announcement,
            onEdit: () => _openComposer(existing: announcement),
            onDelete: () => _deleteAnnouncement(announcement),
            onTogglePin: () => _togglePin(announcement),
          );
        },
      ),
    );
  }
}
