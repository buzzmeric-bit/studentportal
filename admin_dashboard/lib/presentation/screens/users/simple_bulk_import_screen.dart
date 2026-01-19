import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

/// Simple bulk import screen - bypasses DataTable2 issues
class SimpleBulkImportScreen extends ConsumerStatefulWidget {
  const SimpleBulkImportScreen({super.key});

  @override
  ConsumerState<SimpleBulkImportScreen> createState() =>
      _SimpleBulkImportScreenState();
}

class _SimpleBulkImportScreenState
    extends ConsumerState<SimpleBulkImportScreen> {
  List<Map<String, String>> _parsedUsers = [];
  List<Map<String, String>> _createdUsers = [];
  List<String> _errors = [];
  bool _isLoading = false;
  bool _isImporting = false;
  String _status = '';
  int _successCount = 0;
  int _failCount = 0;

  // Available classes for enrollment
  List<Map<String, dynamic>> _availableClasses = [];
  Map<String, String> _classIdByName = {}; // Map class name to ID

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  // Map niveau code to list of class IDs for auto-assignment
  Map<String, List<String>> _classesByNiveau = {};
  // Available niveaux for selection
  List<Map<String, dynamic>> _availableNiveaux = [];

  Future<void> _loadClasses() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        debugPrint('BulkImport: No current user');
        return;
      }

      final userResp = await Supabase.instance.client
          .from('users')
          .select('school_id')
          .eq('id', currentUserId)
          .single();
      final schoolId = userResp['school_id'];
      debugPrint('BulkImport: School ID = $schoolId');

      if (schoolId == null) {
        debugPrint('BulkImport: No school ID for user');
        return;
      }

      // Load classes - try with join first, fallback to simple query
      List<dynamic> classesResp;
      try {
        classesResp = await Supabase.instance.client
            .from('classes')
            .select('id, name, niveau_id, niveaux(id, code, name)')
            .eq('school_id', schoolId)
            .order('name');
      } catch (e) {
        debugPrint('BulkImport: Join query failed, trying simple query: $e');
        classesResp = await Supabase.instance.client
            .from('classes')
            .select('id, name, niveau_id')
            .eq('school_id', schoolId)
            .order('name');
      }

      debugPrint('BulkImport: Raw classes response: $classesResp');

      // Load niveaux separately
      final niveauxResp = await Supabase.instance.client
          .from('niveaux')
          .select('id, code, name, display_order')
          .order('display_order');

      final classes = List<Map<String, dynamic>>.from(classesResp);
      final niveaux = List<Map<String, dynamic>>.from(niveauxResp);

      debugPrint('BulkImport: Loaded ${classes.length} classes, ${niveaux.length} niveaux');

      // Build niveau lookup by ID
      final niveauById = <String, Map<String, dynamic>>{};
      for (final n in niveaux) {
        niveauById[n['id'] as String] = n;
      }

      // Build class lookup maps
      final classIdByName = <String, String>{};
      final classesByNiveau = <String, List<String>>{};

      for (final c in classes) {
        final name = (c['name'] as String).toLowerCase();
        final id = c['id'] as String;
        classIdByName[name] = id;

        // Get niveau info - either from join or from lookup
        Map<String, dynamic>? niveauInfo = c['niveaux'] as Map<String, dynamic>?;
        if (niveauInfo == null && c['niveau_id'] != null) {
          niveauInfo = niveauById[c['niveau_id'] as String];
        }
        
        if (niveauInfo != null) {
          final niveauCode = niveauInfo['code'] as String? ?? '';
          classesByNiveau
              .putIfAbsent(niveauCode.toLowerCase(), () => [])
              .add(id);
        }
      }

      setState(() {
        _availableClasses = classes;
        _classIdByName = classIdByName;
        _classesByNiveau = classesByNiveau;
        _availableNiveaux = niveaux;
      });

      debugPrint('BulkImport: CLASS NAMES AVAILABLE:');
      for (final entry in classIdByName.entries) {
        debugPrint('  - "${entry.key}" -> ${entry.value}');
      }
    } catch (e, stack) {
      debugPrint('Error loading classes: $e');
      debugPrint('Stack: $stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Import Utilisateurs en Masse'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          if (_createdUsers.isNotEmpty)
            TextButton.icon(
              onPressed: _exportCredentials,
              icon: const Icon(Icons.download),
              label: const Text('Exporter identifiants'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions card
            _buildInstructionsCard(),
            const SizedBox(height: 24),

            // File picker section
            _buildFilePickerSection(),
            const SizedBox(height: 24),

            // Status display
            if (_status.isNotEmpty) _buildStatusCard(),
            const SizedBox(height: 24),

            // Parsed users preview
            if (_parsedUsers.isNotEmpty) _buildParsedUsersPreview(),

            // Created users results
            if (_createdUsers.isNotEmpty) _buildCreatedUsersSection(),

            // Errors
            if (_errors.isNotEmpty) _buildErrorsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              const Text(
                'Format du fichier requis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormatTable(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_fix_high, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Le mot de passe et le code étudiant sont générés automatiquement !',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTable() {
    final rows = [
      ['Colonne A', 'Nom complet *', 'Ahmed Ben Ali'],
      ['Colonne B', 'Email *', 'ahmed@example.com'],
      ['Colonne C', 'Téléphone', '+216 55 123 456'],
      ['Colonne D', 'Rôle', 'student / staff'],
      ['Colonne E', 'Date naissance', '15/03/2008'],
      ['Colonne F', 'Adresse', 'Tunis, Tunisie'],
      ['Colonne G', 'Genre', 'M / F'],
      ['Colonne H', 'Nationalité', 'Tunisien'],
      [
        'Colonne I',
        'Niveau *',
        '7eme / 8eme / 9eme / 1ere_sec / 2eme_sec / 3eme_sec / bac',
      ],
      ['Colonne J', 'Classe', '8B-1 (optionnel, auto-assigné si vide)'],
    ];

    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FixedColumnWidth(100),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Colonne',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Champ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Exemple',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ...rows.map(
          (r) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  r[0],
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.all(10), child: Text(r[1])),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  r[2],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilePickerSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 64,
            color: Colors.blue.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Glissez un fichier ou cliquez pour sélectionner',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Formats acceptés: .xlsx, .xls, .csv',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickFile,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_upload),
                label: Text(
                  _isLoading ? 'Chargement...' : 'Choisir un fichier',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download),
                label: const Text('Télécharger modèle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color bgColor = Colors.blue.shade50;
    Color textColor = Colors.blue.shade700;
    IconData icon = Icons.info;

    if (_status.contains('Erreur') || _status.contains('échec')) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.error;
    } else if (_status.contains('succès') || _status.contains('terminé')) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedUsersPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_parsedUsers.length} utilisateur(s) trouvé(s)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cliquez sur × pour supprimer un utilisateur avant l\'import',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_parsedUsers.length > 1)
                    TextButton.icon(
                      onPressed: _isImporting
                          ? null
                          : () {
                              setState(() {
                                _parsedUsers.clear();
                                _status = 'Liste vidée';
                              });
                            },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Tout supprimer'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isImporting || _parsedUsers.isEmpty
                        ? null
                        : _importUsers,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload),
                    label: Text(
                      _isImporting
                          ? 'Import en cours...'
                          : 'Importer maintenant',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _parsedUsers.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final user = _parsedUsers[index];
                final hasNiveau = user['niveau']?.isNotEmpty == true;
                final hasClass = user['className']?.isNotEmpty == true;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user['role'] == 'student'
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      user['gender'] == 'F' ? Icons.female : Icons.male,
                      color: user['role'] == 'student'
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                  title: Text(
                    user['fullName'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email'] ?? ''),
                      if (hasNiveau || hasClass)
                        Text(
                          '${hasNiveau ? 'Niveau: ${user['niveau']}' : ''}${hasNiveau && hasClass ? ' • ' : ''}${hasClass ? 'Classe: ${user['className']}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: hasNiveau || hasClass,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: user['role'] == 'student'
                              ? Colors.orange.shade100
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['role'] == 'student' ? 'Étudiant' : 'Staff',
                          style: TextStyle(
                            fontSize: 12,
                            color: user['role'] == 'student'
                                ? Colors.orange.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        tooltip: 'Supprimer de la liste',
                        onPressed: _isImporting
                            ? null
                            : () {
                                setState(() {
                                  _parsedUsers.removeAt(index);
                                  _status =
                                      '${_parsedUsers.length} utilisateur(s) restant(s)';
                                });
                              },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedUsersSection() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 12),
              Text(
                '$_successCount utilisateur(s) créé(s) avec succès',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'IMPORTANT: Copiez ou téléchargez les identifiants ci-dessous. Les mots de passe ne seront plus accessibles après fermeture.',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _createdUsers.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final user = _createdUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.check, color: Colors.green),
                  ),
                  title: Text(
                    user['fullName'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SelectableText(
                          user['password'] ?? '',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copier mot de passe',
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: user['password'] ?? ''),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mot de passe copié!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _exportCredentials,
              icon: const Icon(Icons.download),
              label: const Text('Télécharger tous les identifiants (Excel)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Text(
                '$_failCount erreur(s)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _errors.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '• ${_errors[index]}',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Lecture du fichier...';
        _parsedUsers = [];
        _createdUsers = [];
        _errors = [];
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name.toLowerCase();
        final users = <Map<String, String>>[];

        if (fileName.endsWith('.csv')) {
          final content = String.fromCharCodes(bytes);
          final lines = content.split('\n');

          for (var i = 1; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;

            final parts = line.split(',');
            if (parts.length < 2) continue;

            final fullName = parts[0].trim();
            final email = parts[1].trim();
            final phone = parts.length > 2 ? parts[2].trim() : '';
            final role = parts.length > 3
                ? parts[3].trim().toLowerCase()
                : 'student';
            final dateOfBirth = parts.length > 4 ? parts[4].trim() : '';
            final address = parts.length > 5 ? parts[5].trim() : '';
            final gender = parts.length > 6
                ? parts[6].trim().toUpperCase()
                : '';
            final nationality = parts.length > 7 ? parts[7].trim() : '';
            final niveau = parts.length > 8 ? parts[8].trim() : '';
            final className = parts.length > 9 ? parts[9].trim() : '';

            if (fullName.isNotEmpty && email.isNotEmpty) {
              users.add({
                'fullName': fullName,
                'email': email,
                'phone': phone,
                'role': role.isEmpty ? 'student' : role,
                'dateOfBirth': dateOfBirth,
                'address': address,
                'gender': gender,
                'nationality': nationality,
                'niveau': niveau,
                'className': className,
              });
            }
          }
        } else {
          final excel = Excel.decodeBytes(bytes);

          for (final table in excel.tables.keys) {
            final sheet = excel.tables[table]!;

            for (var i = 1; i < sheet.maxRows; i++) {
              final row = sheet.rows[i];
              if (row.isEmpty || row[0]?.value == null) continue;

              final fullName = row[0]?.value?.toString() ?? '';
              final email = row[1]?.value?.toString() ?? '';
              final phone = row.length > 2 ? row[2]?.value?.toString() : null;
              final role = row.length > 3
                  ? row[3]?.value?.toString() ?? 'student'
                  : 'student';
              final dateOfBirth = row.length > 4
                  ? row[4]?.value?.toString()
                  : null;
              final address = row.length > 5 ? row[5]?.value?.toString() : null;
              final gender = row.length > 6
                  ? row[6]?.value?.toString().toUpperCase()
                  : null;
              final nationality = row.length > 7
                  ? row[7]?.value?.toString()
                  : null;
              final niveau = row.length > 8 ? row[8]?.value?.toString() : null;
              final className = row.length > 9
                  ? row[9]?.value?.toString()
                  : null;

              if (fullName.isNotEmpty && email.isNotEmpty) {
                users.add({
                  'fullName': fullName,
                  'email': email,
                  'phone': phone ?? '',
                  'role': role.toLowerCase().isEmpty
                      ? 'student'
                      : role.toLowerCase(),
                  'dateOfBirth': dateOfBirth ?? '',
                  'address': address ?? '',
                  'gender': gender ?? '',
                  'nationality': nationality ?? '',
                  'niveau': niveau ?? '',
                  'className': className ?? '',
                });
              }
            }
            break;
          }
        }

        setState(() {
          _parsedUsers = users;
          _status = users.isEmpty
              ? 'Aucun utilisateur trouvé dans le fichier'
              : '${users.length} utilisateur(s) prêt(s) à importer';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = 'Aucun fichier sélectionné';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Erreur lors de la lecture: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importUsers() async {
    if (_parsedUsers.isEmpty) return;

    setState(() {
      _isImporting = true;
      _status = 'Chargement des classes...';
      _createdUsers = [];
      _errors = [];
      _successCount = 0;
      _failCount = 0;
    });

    // Reload classes to ensure we have the latest data
    await _loadClasses();

    debugPrint(
      'BulkImport: Starting import with ${_classIdByName.length} classes loaded',
    );
    if (_classIdByName.isEmpty) {
      setState(() {
        _status = 'Erreur: Aucune classe trouvée dans la base de données';
        _isImporting = false;
      });
      return;
    }

    setState(() {
      _status = 'Import en cours...';
    });

    final adminClient = SupabaseConfig.adminClient;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null) {
      setState(() {
        _status = 'Erreur: Non connecté';
        _isImporting = false;
      });
      return;
    }

    // Get school ID
    String? schoolId;
    try {
      final userResp = await Supabase.instance.client
          .from('users')
          .select('school_id')
          .eq('id', currentUserId)
          .single();
      schoolId = userResp['school_id'];
    } catch (e) {
      setState(() {
        _status = 'Erreur: Impossible de récupérer l\'école';
        _isImporting = false;
      });
      return;
    }

    for (var i = 0; i < _parsedUsers.length; i++) {
      final user = _parsedUsers[i];
      setState(
        () => _status =
            'Import ${i + 1}/${_parsedUsers.length}: ${user['fullName']}',
      );

      try {
        final password = _generatePassword();
        final code = await _generateCode(user['role'] ?? 'student');

        // Create auth user
        final authResp = await adminClient.auth.admin.createUser(
          AdminUserAttributes(
            email: user['email']!,
            password: password,
            emailConfirm: true,
          ),
        );

        final newUserId = authResp.user?.id;
        if (newUserId == null) throw Exception('Failed to create auth user');

        // Resolve class ID from niveau and class name
        String? classId;
        String? niveauCode = user['niveau'];
        final className = user['className'];

        debugPrint(
          'BulkImport: Processing ${user['fullName']} - niveau=$niveauCode, class=$className',
        );
        debugPrint(
          'BulkImport: Available classes (first 15): ${_classIdByName.keys.take(15).toList()}',
        );

        // Only try to find class if className is provided and not empty
        if (className != null && className.toString().trim().isNotEmpty) {
          final searchName = className.toString().toLowerCase().trim();

          // Step 1: Try exact name match
          classId = _classIdByName[searchName];
          debugPrint('BulkImport: Exact match for "$searchName": $classId');

          // Step 2: Try without spaces/dashes normalization
          if (classId == null) {
            final normalized = searchName.replaceAll(RegExp(r'[\s\-_]'), '');
            for (final entry in _classIdByName.entries) {
              final entryNormalized = entry.key.replaceAll(
                RegExp(r'[\s\-_]'),
                '',
              );
              if (entryNormalized == normalized) {
                classId = entry.value;
                debugPrint(
                  'BulkImport: Normalized match: "${entry.key}" -> $classId',
                );
                break;
              }
            }
          }

          // Step 3: Try contains match
          if (classId == null) {
            for (final entry in _classIdByName.entries) {
              if (entry.key.contains(searchName) ||
                  searchName.contains(entry.key)) {
                classId = entry.value;
                debugPrint(
                  'BulkImport: Contains match: "${entry.key}" -> $classId',
                );
                break;
              }
            }
          }

          if (classId == null) {
            debugPrint('BulkImport: NO MATCH FOUND for class "$searchName"');
          }
        }

        // Get niveau_id only if niveauCode is provided
        String? niveauId;
        if (niveauCode != null && niveauCode.toString().trim().isNotEmpty) {
          final niveauSearch = niveauCode.toString().toLowerCase().trim();
          final niveauInfo = _availableNiveaux.firstWhere(
            (n) => (n['code'] as String?)?.toLowerCase() == niveauSearch,
            orElse: () => <String, dynamic>{},
          );
          niveauId = niveauInfo['id'] as String?;
          debugPrint(
            'BulkImport: Found niveau_id=$niveauId for code=$niveauCode',
          );
        }

        // If class was found, get niveau from class if not already set
        if (classId != null && niveauId == null) {
          final classInfo = _availableClasses.firstWhere(
            (c) => c['id'] == classId,
            orElse: () => <String, dynamic>{},
          );
          final classNiveauInfo = classInfo['niveaux'] as Map<String, dynamic>?;
          if (classNiveauInfo != null) {
            niveauId = classNiveauInfo['id'] as String?;
            niveauCode ??= classNiveauInfo['code'] as String?;
          }
          niveauId ??= classInfo['niveau_id'] as String?;
        }

        debugPrint(
          'BulkImport: Final - classId=$classId, niveauCode=$niveauCode, niveauId=$niveauId',
        );

        // Insert profile with new fields
        // Convert date from DD/MM/YYYY to YYYY-MM-DD for PostgreSQL
        String? formattedDate;
        final rawDate = user['dateOfBirth'];
        if (rawDate != null && rawDate.isNotEmpty) {
          try {
            // Try DD/MM/YYYY format
            final parts = rawDate.split('/');
            if (parts.length == 3) {
              final day = parts[0].padLeft(2, '0');
              final month = parts[1].padLeft(2, '0');
              final year = parts[2];
              formattedDate = '$year-$month-$day';
            } else if (rawDate.contains('-')) {
              // Already in YYYY-MM-DD format
              formattedDate = rawDate;
            }
          } catch (e) {
            debugPrint('BulkImport: Date parse error for "$rawDate": $e');
          }
        }

        await adminClient.from('users').insert({
          'id': newUserId,
          'school_id': schoolId,
          'email': user['email'],
          'full_name': user['fullName'],
          'role': user['role'] ?? 'student',
          'phone': user['phone']?.isNotEmpty == true ? user['phone'] : null,
          'student_code': code,
          'date_of_birth': formattedDate,
          'address': user['address']?.isNotEmpty == true
              ? user['address']
              : null,
          'gender': user['gender']?.isNotEmpty == true ? user['gender'] : null,
          'nationality': user['nationality']?.isNotEmpty == true
              ? user['nationality']
              : null,
          'niveau_code': niveauCode,
          'niveau_id': niveauId,
          'initial_password': password, // Store for manager reference
        });

        // Create enrollment if class is specified for students
        debugPrint(
          'BulkImport: Checking enrollment - classId=$classId, role=${user['role']}, schoolId=$schoolId',
        );
        if (classId != null && user['role'] == 'student' && schoolId != null) {
          // Get current academic year
          final academicYearResp = await adminClient
              .from('academic_years')
              .select('id')
              .eq('school_id', schoolId)
              .eq('is_current', true)
              .maybeSingle();

          debugPrint('BulkImport: Academic year response: $academicYearResp');
          if (academicYearResp != null) {
            await adminClient.from('enrollments').insert({
              'user_id': newUserId,
              'class_id': classId,
              'academic_year_id': academicYearResp['id'],
              'is_active': true,
              'student_code': code,
            });
            debugPrint(
              'BulkImport: Enrollment created for $newUserId in class $classId',
            );
          } else {
            debugPrint(
              'BulkImport: No current academic year found for school $schoolId',
            );
          }
        } else {
          debugPrint(
            'BulkImport: Skipping enrollment - classId=$classId, role=${user['role']}, schoolId=$schoolId',
          );
        }

        _createdUsers.add({
          'fullName': user['fullName']!,
          'email': user['email']!,
          'password': password,
          'code': code,
          'className': className ?? '',
        });
        _successCount++;
      } catch (e) {
        _errors.add('${user['email']}: $e');
        _failCount++;
      }
    }

    setState(() {
      _isImporting = false;
      _parsedUsers = [];
      _status = 'Import terminé: $_successCount succès, $_failCount échec(s)';
    });
  }

  String _generatePassword({int length = 12}) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#\$%&*';
    final random = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(chars[(random * (i + 1) * 7 + i * 31) % chars.length]);
    }
    return buffer.toString();
  }

  Future<String> _generateCode(String role) async {
    final year = DateTime.now().year;
    final prefix = role == 'student' ? 'STU' : 'MGR';
    final countResp = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('role', role == 'student' ? 'student' : 'staff')
        .like('student_code', '$prefix-$year-%');
    final count = (countResp as List).length + 1;
    return '$prefix-$year-${count.toString().padLeft(4, '0')}';
  }

  Future<void> _downloadTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Utilisateurs'];

    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      'Nom complet *',
    );
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Email *');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue(
      'Téléphone',
    );
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Rôle');
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue(
      'Date naissance',
    );
    sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('Adresse');
    sheet.cell(CellIndex.indexByString('G1')).value = TextCellValue(
      'Genre (M/F)',
    );
    sheet.cell(CellIndex.indexByString('H1')).value = TextCellValue(
      'Nationalité',
    );
    sheet.cell(CellIndex.indexByString('I1')).value = TextCellValue('Niveau *');
    sheet.cell(CellIndex.indexByString('J1')).value = TextCellValue(
      'Classe (optionnel)',
    );

    // Get example class name from available classes
    String exampleClass1 = '';
    String exampleClass2 = '';
    String exampleNiveau1 = '8eme';
    String exampleNiveau2 = '9eme';

    if (_availableClasses.isNotEmpty) {
      exampleClass1 = _availableClasses[0]['name'] ?? '';
      final niveauInfo1 =
          _availableClasses[0]['niveaux'] as Map<String, dynamic>?;
      if (niveauInfo1 != null) {
        exampleNiveau1 = niveauInfo1['code'] ?? '8eme';
      }
      if (_availableClasses.length > 1) {
        exampleClass2 = _availableClasses[1]['name'] ?? '';
        final niveauInfo2 =
            _availableClasses[1]['niveaux'] as Map<String, dynamic>?;
        if (niveauInfo2 != null) {
          exampleNiveau2 = niveauInfo2['code'] ?? '9eme';
        }
      }
    }

    // Row 1 - Example student with class specified
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      'Ahmed Ben Ali',
    );
    sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue(
      'ahmed.benali@example.com',
    );
    sheet.cell(CellIndex.indexByString('C2')).value = TextCellValue(
      '+216 55 123 456',
    );
    sheet.cell(CellIndex.indexByString('D2')).value = TextCellValue('student');
    sheet.cell(CellIndex.indexByString('E2')).value = TextCellValue(
      '15/03/2008',
    );
    sheet.cell(CellIndex.indexByString('F2')).value = TextCellValue(
      'Tunis, Tunisie',
    );
    sheet.cell(CellIndex.indexByString('G2')).value = TextCellValue('M');
    sheet.cell(CellIndex.indexByString('H2')).value = TextCellValue('Tunisien');
    sheet.cell(CellIndex.indexByString('I2')).value = TextCellValue(
      exampleNiveau1,
    );
    sheet.cell(CellIndex.indexByString('J2')).value = TextCellValue(
      exampleClass1,
    );

    // Row 2 - Example student without class (will be auto-assigned)
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      'Fatma Trabelsi',
    );
    sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(
      'fatma.trabelsi@example.com',
    );
    sheet.cell(CellIndex.indexByString('C3')).value = TextCellValue(
      '+216 22 987 654',
    );
    sheet.cell(CellIndex.indexByString('D3')).value = TextCellValue('student');
    sheet.cell(CellIndex.indexByString('E3')).value = TextCellValue(
      '22/07/2009',
    );
    sheet.cell(CellIndex.indexByString('F3')).value = TextCellValue(
      'Sfax, Tunisie',
    );
    sheet.cell(CellIndex.indexByString('G3')).value = TextCellValue('F');
    sheet.cell(CellIndex.indexByString('H3')).value = TextCellValue(
      'Tunisienne',
    );
    sheet.cell(CellIndex.indexByString('I3')).value = TextCellValue(
      exampleNiveau2,
    );
    // J3 left empty - class will be auto-assigned based on niveau

    // Add a sheet with available classes and niveaux for reference
    if (_availableClasses.isNotEmpty || _availableNiveaux.isNotEmpty) {
      final refSheet = excel['Niveaux et Classes'];
      refSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'Code Niveau',
      );
      refSheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(
        'Nom du Niveau',
      );
      refSheet.cell(CellIndex.indexByString('C1')).value = TextCellValue(
        'Nom de la Classe',
      );
      refSheet.cell(CellIndex.indexByString('D1')).value = TextCellValue(
        '(Utilisez le Code Niveau dans la colonne I)',
      );

      // List all classes with their niveau info
      for (var i = 0; i < _availableClasses.length; i++) {
        final row = i + 2;
        final c = _availableClasses[i];
        final niveauInfo = c['niveaux'] as Map<String, dynamic>?;

        refSheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(
          niveauInfo?['code'] ?? '',
        );
        refSheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(
          niveauInfo?['name'] ?? '',
        );
        refSheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(
          c['name'] ?? '',
        );
      }
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes != null) {
      await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le modèle',
        fileName: 'modele_import_utilisateurs.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );
    }
  }

  Future<void> _exportCredentials() async {
    if (_createdUsers.isEmpty) return;

    final excel = Excel.createExcel();
    final sheet = excel['Identifiants'];

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      'Nom complet',
    );
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Email');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue(
      'Mot de passe',
    );
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Code');
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Classe');

    for (var i = 0; i < _createdUsers.length; i++) {
      final row = i + 2;
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(
        _createdUsers[i]['fullName'] ?? '',
      );
      sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(
        _createdUsers[i]['email'] ?? '',
      );
      sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(
        _createdUsers[i]['password'] ?? '',
      );
      sheet.cell(CellIndex.indexByString('D$row')).value = TextCellValue(
        _createdUsers[i]['code'] ?? '',
      );
      sheet.cell(CellIndex.indexByString('E$row')).value = TextCellValue(
        _createdUsers[i]['className'] ?? '',
      );
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-');
      await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer les identifiants',
        fileName: 'identifiants_generes_$timestamp.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );
    }
  }
}
