// ignore_for_file: unused_element, unused_field, unused_local_variable

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/announcements_provider.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _searchWidthAnimation;
  late Animation<double> _iconSizeAnimation;

  static const Color _accentColor = Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchWidthAnimation = Tween<double>(begin: 44, end: 200).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _iconSizeAnimation = Tween<double>(begin: 22, end: 18).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _animationController.forward();
        Future.delayed(const Duration(milliseconds: 150), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _animationController.reverse();
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
  }

  // Build the animated header
  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideValue = _animationController.value;
        final fadeOut = 1.0 - slideValue;
        final fadeIn = slideValue;

        return SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Normal header - slides out to left and fades
              Transform.translate(
                offset: Offset(-80 * slideValue, 0),
                child: Opacity(
                  opacity: fadeOut.clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      // Icon with scale animation
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
                              colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[900],
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Restez informé',
                              style: TextStyle(
                                fontSize: 14,
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
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 18),
                              Icon(
                                Icons.search_rounded,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  cursorColor: Colors.grey[600],
                                  onChanged: (value) =>
                                      setState(() => _searchQuery = value),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.grey[600],
                                      size: 14,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 18),
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

  // Normal header with icon, title and search button
  Widget _buildNormalHeader() {
    return Row(
      children: [
        // Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[900],
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Restez informé',
                style: TextStyle(
                  fontSize: 15,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.search_rounded,
              color: Colors.grey[700],
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // Search header with full-width search bar
  Widget _buildSearchHeader() {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: _toggleSearch,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: _accentColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Search field
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accentColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search_rounded, color: _accentColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    cursorColor: Colors.grey[600],
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une notification...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                      child: Icon(
                        Icons.cancel_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final announcementsAsync = ref.watch(globalAnnouncementsProvider);

    // Show loading if auth is still loading
    final isAuthLoading = authState.isLoading;

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
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(globalAnnouncementsProvider);
            await ref.read(globalAnnouncementsProvider.future);
          },
          color: _accentColor,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: _buildAnimatedHeader(),
                ),
              ),

            // Notifications List
            // Show loading if auth is still loading
            if (isAuthLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else
            announcementsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: $e',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (announcements) {
                // Filter announcements by search
                var filtered = announcements;
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filtered = announcements.where((a) {
                    return a.title.toLowerCase().contains(query) ||
                        a.body.toLowerCase().contains(query) ||
                        (a.senderLabel?.toLowerCase().contains(query) ??
                            false) ||
                        (a.announcementType?.toLowerCase().contains(query) ??
                            false);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune notification',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildNotificationCard(filtered[index]),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic announcement) {
    final isImportant = announcement.isImportant;
    final isPinned = announcement.isPinned;
    final color = _getTypeColor(announcement.announcementType);
    final icon = _getTypeIcon(announcement.announcementType);
    final typeLabel = _getTypeLabel(announcement.announcementType);
    
    // Check for non-image attachments (documents)
    final hasDocumentAttachment = announcement.attachments.any(
      (att) => !_isImageFile(att.fileUrl),
    );
    // Count images and documents separately
    final imageCount = announcement.attachments.where(
      (att) => _isImageFile(att.fileUrl),
    ).length;
    final documentCount = announcement.attachments.where(
      (att) => !_isImageFile(att.fileUrl),
    ).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showAnnouncementDetail(announcement),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with icon, title, and badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      // Type label and Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            if (announcement.announcementType == 'general')
                              const SizedBox(height: 4),
                            Text(
                              announcement.title,
                              style: TextStyle(
                                fontSize: announcement.announcementType == 'general' ? 12 : 16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1F2937),
                                letterSpacing: -0.3,
                                height: 1.0,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Key info subtitle - only show if not empty
                            if (_extractKeyInfo(announcement.announcementType, announcement.payload, announcement.body).isNotEmpty)
                              Transform.translate(
                                offset: const Offset(0, -10),
                                child: Text(
                                  _extractKeyInfo(announcement.announcementType, announcement.payload, announcement.body),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Badges row
                  if (isPinned || isImportant || hasDocumentAttachment) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (isPinned)
                          _buildBadge('Épinglé', Colors.orange, Icons.push_pin),
                        if (isImportant)
                          _buildBadge(
                            'Important',
                            Colors.red,
                            Icons.priority_high,
                          ),
                        if (hasDocumentAttachment)
                          _buildBadge(
                            'Pièce jointe',
                            Colors.purple,
                            Icons.attach_file,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Body content with small image thumbnail at end
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          announcement.body,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Small image thumbnail at end of body
                      if (imageCount > 0) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showImageViewer(
                            announcement.attachments
                                .where((att) => _isImageFile(att.fileUrl))
                                .map((att) => att.fileUrl)
                                .toList(),
                            0,
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    announcement.attachments
                                        .firstWhere((att) => _isImageFile(att.fileUrl))
                                        .fileUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 18,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Show image count badge if multiple
                                  if (imageCount > 1)
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '+${imageCount - 1}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Footer with sender and time
                  Row(
                    children: [
                      // Sender info
                      if (announcement.senderLabel != null) ...[
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            announcement.senderLabel!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      // Timestamp
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(announcement.publishedAt),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
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
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(String url, String? name) {
    final isImage = _isImageFile(url);

    return GestureDetector(
      onTap: () => _openAttachment(url),
      child: isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 80,
                          color: Colors.grey[100],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 60,
                        color: Colors.grey[100],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            Text(
                              'Image non disponible',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.image_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Ouvrir',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAttachmentIcon(url),
                    size: 18,
                    color: Colors.purple[600],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _getCleanFileName(name, url),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.download_rounded,
                    size: 16,
                    color: Colors.purple[600],
                  ),
                ],
              ),
            ),
    );
  }

  bool _isImageFile(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  Widget _buildDetailAttachment(String url, String? name) {
    final isImage = _isImageFile(url);

    return GestureDetector(
      onTap: () => _openAttachment(url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text(
                        'Image non disponible',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAttachmentIcon(url),
                      size: 24,
                      color: Colors.purple[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCleanFileName(name, url),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.purple[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Appuyez pour télécharger',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.download_rounded,
                    size: 24,
                    color: Colors.purple[700],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnnouncementDetail(dynamic announcement) {
    final color = _getTypeColor(announcement.announcementType);
    final icon = _getTypeIcon(announcement.announcementType);
    final typeLabel = _getTypeLabel(announcement.announcementType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.3,
            maxChildSize: 1.0,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar - draggable area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with icon
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [color, color.withOpacity(0.7)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(icon, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        typeLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormat(
                                        'd MMMM yyyy à HH:mm',
                                        'fr_FR',
                                      ).format(announcement.publishedAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Badges
                          if (announcement.isPinned || announcement.isImportant || announcement.attachments.any((att) => !_isImageFile(att.fileUrl)))
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (announcement.isPinned)
                                  _buildBadge('Épinglé', Colors.orange, Icons.push_pin),
                                if (announcement.isImportant)
                                  _buildBadge(
                                    'Important',
                                    Colors.red,
                                    Icons.priority_high,
                                  ),
                                if (announcement.attachments.any((att) => !_isImageFile(att.fileUrl)))
                                  _buildBadge(
                                    'Pièce jointe',
                                    Colors.purple,
                                    Icons.attach_file,
                                  ),
                              ],
                            ),
                          const SizedBox(height: 24),
                          // Body content
                          Text(
                            announcement.body,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                          // Attachments - show all from attachments list
                          if (announcement.attachments.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...announcement.attachments.map(
                              (att) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildDetailAttachment(
                                  att.fileUrl,
                                  att.effectiveName,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            announcement.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                              letterSpacing: -0.5,
                            ),
                          ),
                          // Sender info in styled container
                          if (announcement.senderLabel != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Envoyé par',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          announcement.senderLabel!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    ),
  ),
    );
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le fichier'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageViewer(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrls[initialIndex],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white54, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Image non disponible',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Image counter if multiple
              if (imageUrls.length > 1)
                Positioned(
                  top: 50,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${initialIndex + 1} / ${imageUrls.length}',
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
      ),
    );
  }

  IconData _getAttachmentIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif')) {
      return Icons.image_rounded;
    }
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_rounded;
    }
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) {
      return Icons.table_chart_rounded;
    }
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return Icons.slideshow_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  String _getAttachmentName(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.pathSegments.last;
      return Uri.decodeComponent(path);
    } catch (e) {
      return 'Fichier joint';
    }
  }

  /// Get clean display name for file attachments
  /// Uses custom name if provided, otherwise generates a friendly name based on file type
  String _getCleanFileName(String? customName, String url) {
    // If admin provided a custom name and it's not a raw WhatsApp/auto-generated name
    if (customName != null &&
        customName.isNotEmpty &&
        !customName.toLowerCase().contains('whatsapp') &&
        !RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(customName) &&
        !RegExp(
          r'IMG_\d+|DSC_\d+|Screenshot',
          caseSensitive: false,
        ).hasMatch(customName)) {
      return customName;
    }

    // Generate friendly name based on file type
    final lower = url.toLowerCase();
    if (lower.endsWith('.pdf')) return 'Document PDF';
    if (lower.endsWith('.doc') || lower.endsWith('.docx'))
      return 'Document Word';
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx'))
      return 'Fichier Excel';
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx'))
      return 'Présentation';
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp'))
      return 'Image';
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi'))
      return 'Vidéo';
    if (lower.endsWith('.mp3') || lower.endsWith('.wav')) return 'Audio';
    if (lower.endsWith('.zip') || lower.endsWith('.rar')) return 'Archive';

    return 'Fichier joint';
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'teacher_absent':
        return 'Absence prof';
      case 'room_change':
        return 'Changement salle';
      case 'exam':
        return 'Examen';
      case 'reminder':
        return 'Rappel';
      case 'closure':
        return 'Fermeture';
      case 'trip':
        return 'Sortie/Voyage';
      case 'party':
        return 'Événement';
      case 'payment':
        return 'Paiement';
      default:
        return 'Général';
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'teacher_absent':
        return const Color(0xFFEF4444);
      case 'room_change':
        return const Color(0xFF3B82F6);
      case 'exam':
        return const Color(0xFFF59E0B);
      case 'reminder':
        return const Color(0xFF8B5CF6);
      case 'closure':
        return const Color(0xFFEC4899);
      case 'trip':
        return const Color(0xFF10B981);
      case 'party':
        return const Color(0xFFF97316);
      case 'payment':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'teacher_absent':
        return Icons.person_off_rounded;
      case 'room_change':
        return Icons.meeting_room_rounded;
      case 'exam':
        return Icons.quiz_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      case 'closure':
        return Icons.lock_rounded;
      case 'trip':
        return Icons.directions_bus_rounded;
      case 'party':
        return Icons.celebration_rounded;
      case 'payment':
        return Icons.payment_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  /// Extracts key information from announcement based on type and payload
  String _extractKeyInfo(String? type, Map<String, dynamic> payload, String body) {
    switch (type) {
      case 'room_change':
        // Use payload fields: old_room, new_room, subject, date_time
        final oldRoom = payload['old_room'] as String?;
        final newRoom = payload['new_room'] as String?;
        final subject = payload['subject'] as String?;
        final dateTime = payload['date_time'] as String?;
        
        if (oldRoom != null && oldRoom.isNotEmpty && newRoom != null && newRoom.isNotEmpty) {
          String info = 'Salle $oldRoom → Salle $newRoom';
          if (subject != null && subject.isNotEmpty) {
            info = '$subject: $info';
          }
          return info;
        }
        break;
        
      case 'teacher_absent':
        // Use payload fields: teacher_name, start_date, end_date, replacement_note
        final teacherName = payload['teacher_name'] as String?;
        final startDate = payload['start_date'] as String?;
        final endDate = payload['end_date'] as String?;
        
        if (teacherName != null && teacherName.isNotEmpty) {
          String info = 'Prof. $teacherName';
          if (startDate != null && startDate.isNotEmpty) {
            if (endDate != null && endDate.isNotEmpty && startDate != endDate) {
              info += ' • $startDate → $endDate';
            } else {
              info += ' • $startDate';
            }
          }
          return info;
        }
        break;
        
      case 'exam':
        // Use payload fields: subject, date_time, room, instructions
        final subject = payload['subject'] as String?;
        final dateTime = payload['date_time'] as String?;
        final room = payload['room'] as String?;
        
        List<String> parts = [];
        if (subject != null && subject.isNotEmpty) parts.add(subject);
        if (dateTime != null && dateTime.isNotEmpty) parts.add(dateTime);
        if (room != null && room.isNotEmpty) parts.add('Salle $room');
        
        if (parts.isNotEmpty) {
          return parts.join(' • ');
        }
        break;
        
      case 'closure':
        // Use payload fields: reason, closed_from, closed_to, reopen_date
        final reason = payload['reason'] as String?;
        final closedFrom = payload['closed_from'] as String?;
        final closedTo = payload['closed_to'] as String?;
        
        List<String> parts = [];
        if (closedFrom != null && closedFrom.isNotEmpty) {
          if (closedTo != null && closedTo.isNotEmpty) {
            parts.add('$closedFrom → $closedTo');
          } else {
            parts.add('À partir du $closedFrom');
          }
        }
        if (reason != null && reason.isNotEmpty) {
          parts.insert(0, reason);
        }
        
        if (parts.isNotEmpty) {
          return parts.join(' • ');
        }
        break;
        
      case 'reminder':
        // Use payload fields: due_date, action_required
        final dueDate = payload['due_date'] as String?;
        final actionRequired = payload['action_required'] as String?;
        
        List<String> parts = [];
        if (dueDate != null && dueDate.isNotEmpty) parts.add('Avant le $dueDate');
        if (actionRequired != null && actionRequired.isNotEmpty) parts.add(actionRequired);
        
        if (parts.isNotEmpty) {
          return parts.join(' • ');
        }
        break;
        
      case 'general':
        // For general type, don't show subtitle - body is already displayed below
        return '';
        
      case 'trip':
        // Extract destination and date from body
        final destPattern = RegExp(r'(?:sortie|à|vers|destination)\s+([A-Za-zÀ-ÿ\s]+?)(?:\s+(?:le|est|organis))', caseSensitive: false);
        final datePattern = RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})');
        final destMatch = destPattern.firstMatch(body);
        final dateMatch = datePattern.firstMatch(body);
        
        List<String> tripParts = [];
        if (destMatch != null) tripParts.add(destMatch.group(1)?.trim() ?? '');
        if (dateMatch != null) tripParts.add('Le ${dateMatch.group(1)}');
        if (tripParts.isNotEmpty) return tripParts.join(' • ');
        break;
        
      case 'party':
        // Extract event date and location from body
        final eventDatePattern = RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})');
        final locationPattern = RegExp(r'[Ll]ieu[:\s]+([A-Za-zÀ-ÿ0-9\s]+?)(?:\.|,|$)');
        final eventDateMatch = eventDatePattern.firstMatch(body);
        final locationMatch = locationPattern.firstMatch(body);
        
        List<String> eventParts = [];
        if (eventDateMatch != null) eventParts.add('Le ${eventDateMatch.group(1)}');
        if (locationMatch != null) eventParts.add(locationMatch.group(1)?.trim() ?? '');
        if (eventParts.isNotEmpty) return eventParts.join(' • ');
        break;
        
      case 'payment':
        // Extract amount and due date from body
        final amountPattern = RegExp(r'(\d+(?:[.,]\d+)?\s*(?:€|DA|DZD|dinars?)?)', caseSensitive: false);
        final dueDatePattern = RegExp(r'avant\s+le\s+(\d{1,2}/\d{1,2}/\d{2,4})', caseSensitive: false);
        final modePattern = RegExp(r'[Mm]ode\s+de\s+paiement[:\s]+([A-Za-zÀ-ÿ0-9\s]+?)(?:\.|,|$)');
        final dueDateMatch = dueDatePattern.firstMatch(body);
        final modeMatch = modePattern.firstMatch(body);
        
        List<String> paymentParts = [];
        if (dueDateMatch != null) paymentParts.add('Avant le ${dueDateMatch.group(1)}');
        if (modeMatch != null) paymentParts.add(modeMatch.group(1)?.trim() ?? '');
        if (paymentParts.isNotEmpty) return paymentParts.join(' • ');
        break;
        
      default:
        break;
    }
    
    // Return empty for types without specific key info
    return '';
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
