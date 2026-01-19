import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_sidebar.dart';
import '../../providers/users_provider.dart';
import '../../../data/models/user_model.dart';

/// Provider for bulk photo upload state
class BulkPhotoUploadState {
  final bool isLoading;
  final List<PlatformFile> files;
  final Map<String, String> matchedFiles; // filename -> userId
  final Map<String, bool> uploadStatus; // userId -> success
  final String? error;

  const BulkPhotoUploadState({
    this.isLoading = false,
    this.files = const [],
    this.matchedFiles = const {},
    this.uploadStatus = const {},
    this.error,
  });

  BulkPhotoUploadState copyWith({
    bool? isLoading,
    List<PlatformFile>? files,
    Map<String, String>? matchedFiles,
    Map<String, bool>? uploadStatus,
    String? error,
  }) {
    return BulkPhotoUploadState(
      isLoading: isLoading ?? this.isLoading,
      files: files ?? this.files,
      matchedFiles: matchedFiles ?? this.matchedFiles,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      error: error,
    );
  }
}

class BulkPhotoUploadNotifier extends Notifier<BulkPhotoUploadState> {
  @override
  BulkPhotoUploadState build() => const BulkPhotoUploadState();

  void setFiles(List<PlatformFile> files) {
    state = state.copyWith(files: files, matchedFiles: {}, uploadStatus: {});
  }

  void matchFile(String filename, String userId) {
    final updated = Map<String, String>.from(state.matchedFiles);
    updated[filename] = userId;
    state = state.copyWith(matchedFiles: updated);
  }

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void setUploadStatus(String userId, bool success) {
    final updated = Map<String, bool>.from(state.uploadStatus);
    updated[userId] = success;
    state = state.copyWith(uploadStatus: updated);
  }

  void reset() {
    state = const BulkPhotoUploadState();
  }
}

final bulkPhotoUploadProvider = NotifierProvider<BulkPhotoUploadNotifier, BulkPhotoUploadState>(() {
  return BulkPhotoUploadNotifier();
});

class BulkPhotoUploadScreen extends ConsumerStatefulWidget {
  const BulkPhotoUploadScreen({super.key});

  @override
  ConsumerState<BulkPhotoUploadScreen> createState() => _BulkPhotoUploadScreenState();
}

class _BulkPhotoUploadScreenState extends ConsumerState<BulkPhotoUploadScreen> {
  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final uploadState = ref.watch(bulkPhotoUploadProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/users'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: usersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
                    data: (state) => _buildContent(context, state.users, uploadState),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.photo_library, color: Colors.purple.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Upload de photos en masse',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Importer plusieurs photos de profil',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<UserModel> users, BulkPhotoUploadState uploadState) {
    if (uploadState.files.isEmpty) {
      return _buildDropZone(context);
    }

    return _buildMatchingView(context, users, uploadState);
  }

  Widget _buildDropZone(BuildContext context) {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple.shade300, width: 2, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(16),
                color: Colors.purple.shade50,
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 72, color: Colors.purple.shade400),
                  const SizedBox(height: 24),
                  Text(
                    'Glissez-déposez les photos ici',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.purple.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ou cliquez pour sélectionner',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.folder_open, color: Colors.white),
                    label: const Text('Sélectionner des photos', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Nommage des fichiers',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pour un matching automatique, nommez les fichiers avec:',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  _buildNamingExample('STU-2024-0001.jpg', 'Code étudiant'),
                  _buildNamingExample('ahmed.benali@email.com.jpg', 'Email'),
                  _buildNamingExample('Ahmed Benali.jpg', 'Nom complet'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamingExample(String example, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              example,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text('→ $description', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMatchingView(BuildContext context, List<UserModel> users, BulkPhotoUploadState uploadState) {
    final students = users.where((u) => u.role == 'student').toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                '${uploadState.files.length} photos sélectionnées',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ref.read(bulkPhotoUploadProvider.notifier).reset(),
                icon: const Icon(Icons.close),
                label: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: uploadState.isLoading ? null : () => _uploadAll(uploadState, students),
                icon: uploadState.isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload, color: Colors.white),
                label: Text(
                  uploadState.isLoading ? 'Upload en cours...' : 'Uploader tout',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: uploadState.files.length,
            itemBuilder: (context, index) => _buildFileItem(context, uploadState.files[index], students, uploadState),
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(BuildContext context, PlatformFile file, List<UserModel> students, BulkPhotoUploadState uploadState) {
    final matchedUserId = uploadState.matchedFiles[file.name];
    final uploadSuccess = matchedUserId != null ? uploadState.uploadStatus[matchedUserId] : null;

    // Try auto-matching
    final autoMatch = _findAutoMatch(file.name, students);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Preview
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: file.bytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(file.bytes!, fit: BoxFit.cover),
                    )
                  : Icon(Icons.image, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 16),
            // Filename
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.arrow_forward, color: Colors.grey.shade400),
            const SizedBox(width: 16),
            // Student selector
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String>(
                value: matchedUserId ?? (autoMatch != null ? autoMatch.id : null),
                decoration: InputDecoration(
                  labelText: 'Étudiant',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: matchedUserId != null || autoMatch != null ? Colors.green.shade50 : Colors.grey.shade100,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('-- Non attribué --'),
                  ),
                  ...students.map((s) => DropdownMenuItem<String>(
                        value: s.id,
                        child: Text('${s.fullName} (${s.studentCode ?? 'N/A'})'),
                      )),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(bulkPhotoUploadProvider.notifier).matchFile(file.name, value);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            // Status
            if (uploadSuccess != null)
              Icon(
                uploadSuccess ? Icons.check_circle : Icons.error,
                color: uploadSuccess ? Colors.green : Colors.red,
              )
            else if (matchedUserId != null || autoMatch != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  autoMatch != null && matchedUserId == null ? 'Auto' : 'Prêt',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 11),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'À attribuer',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  UserModel? _findAutoMatch(String filename, List<UserModel> students) {
    final nameWithoutExt = filename.replaceAll(RegExp(r'\.[^.]+$'), '').toLowerCase();

    for (final student in students) {
      // Match by student code
      if (student.studentCode != null && nameWithoutExt.contains(student.studentCode!.toLowerCase())) {
        return student;
      }
      // Match by email
      if (nameWithoutExt.contains(student.email.toLowerCase().split('@').first)) {
        return student;
      }
      // Match by full name
      if (nameWithoutExt.contains(student.fullName.toLowerCase())) {
        return student;
      }
    }
    return null;
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      ref.read(bulkPhotoUploadProvider.notifier).setFiles(result.files);
    }
  }

  Future<void> _uploadAll(BulkPhotoUploadState state, List<UserModel> students) async {
    ref.read(bulkPhotoUploadProvider.notifier).setLoading(true);

    final supabase = Supabase.instance.client;
    int successCount = 0;
    int failCount = 0;

    for (final file in state.files) {
      String? userId = state.matchedFiles[file.name];

      // Use auto-match if no manual match
      if (userId == null) {
        final autoMatch = _findAutoMatch(file.name, students);
        if (autoMatch != null) userId = autoMatch.id;
      }

      if (userId == null || file.bytes == null) continue;

      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'profiles/$userId/${timestamp}_${file.name}';

        await supabase.storage.from('avatars').uploadBinary(path, file.bytes!);
        final url = supabase.storage.from('avatars').getPublicUrl(path);

        await supabase.from('users').update({'photo_url': url}).eq('id', userId);

        ref.read(bulkPhotoUploadProvider.notifier).setUploadStatus(userId, true);
        successCount++;
      } catch (e) {
        ref.read(bulkPhotoUploadProvider.notifier).setUploadStatus(userId, false);
        failCount++;
      }
    }

    ref.read(bulkPhotoUploadProvider.notifier).setLoading(false);
    ref.invalidate(usersProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload terminé: $successCount réussis, $failCount échecs'),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
