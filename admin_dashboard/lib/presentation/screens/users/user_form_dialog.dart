import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/user_model.dart';
import '../../providers/users_provider.dart';
import '../../providers/curriculum_provider.dart';
import '../../providers/classes_provider.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  final UserModel? user;
  const UserFormDialog({super.key, this.user});
  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _nationalityController;
  late TextEditingController _studentCodeController;
  String _selectedRole = 'student';
  String? _selectedNiveauCode;
  String? _selectedSectionCode;
  String? _selectedGender;
  String? _selectedClassId; // For class enrollment
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _autoGeneratePassword = true;
  String? _generatedCredentials;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.user?.fullName ?? '',
    );
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _addressController = TextEditingController(
      text: widget.user?.address ?? '',
    );
    _nationalityController = TextEditingController(
      text: widget.user?.nationality ?? '',
    );
    _studentCodeController = TextEditingController(
      text: widget.user?.studentCode ?? '',
    );
    _selectedRole = widget.user?.role ?? 'student';
    _selectedNiveauCode = widget.user?.niveauCode;
    _selectedSectionCode = widget.user?.sectionCode;
    _selectedGender = widget.user?.gender;
    _dateOfBirth = widget.user?.dateOfBirth;

    if (!isEditing) {
      _generatePassword();
    } else {
      // Load current enrollment class
      _loadCurrentEnrollment();
    }
  }

  Future<void> _loadCurrentEnrollment() async {
    if (widget.user == null) return;
    try {
      final supabase = Supabase.instance.client;
      final enrollment = await supabase
          .from('enrollments')
          .select('class_id')
          .eq('user_id', widget.user!.id)
          .maybeSingle();
      if (enrollment != null && mounted) {
        setState(() {
          _selectedClassId = enrollment['class_id'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading enrollment: $e');
    }
  }

  void _generatePassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#\$%&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    final password = List.generate(
      12,
      (i) => chars[(random + i * 17) % chars.length],
    ).join();
    _passwordController.text = password;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nationalityController.dispose();
    _studentCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getRoleColor(_selectedRole).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getRoleColor(_selectedRole),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.person_add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing
                            ? 'Modifier utilisateur'
                            : 'Nouvel utilisateur',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'Modifiez les informations'
                            : 'Le code sera généré automatiquement',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role selector
                      Text(
                        'Type d\'utilisateur',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _RoleButton(
                            role: 'student',
                            label: 'Étudiant',
                            icon: Icons.school,
                            isSelected: _selectedRole == 'student',
                            onTap: isEditing
                                ? null
                                : () =>
                                      setState(() => _selectedRole = 'student'),
                          ),
                          const SizedBox(width: 8),
                          _RoleButton(
                            role: 'staff',
                            label: 'Manager',
                            icon: Icons.admin_panel_settings,
                            isSelected: _selectedRole == 'staff',
                            onTap: isEditing
                                ? null
                                : () => setState(() => _selectedRole = 'staff'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Nom complet *',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),

                      const SizedBox(height: 16),

                      // Student Code (for students only)
                      if (_selectedRole == 'student')
                        TextFormField(
                          controller: _studentCodeController,
                          decoration: InputDecoration(
                            labelText: 'Code Étudiant',
                            hintText: 'Ex: STU-2026-0001 (auto si vide)',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                      if (_selectedRole == 'student')
                        const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        },
                        enabled: !isEditing,
                      ),

                      if (!isEditing) ...[
                        const SizedBox(height: 16),

                        // Password section
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe *',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () => setState(
                                          () => _showPassword = !_showPassword,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 20),
                                        tooltip: 'Copier',
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: _passwordController.text,
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Mot de passe copié',
                                              ),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                obscureText: !_showPassword,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Requis' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Générer nouveau',
                              onPressed: _generatePassword,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Notez ce mot de passe. Vous devrez le communiquer à l\'utilisateur.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText: '+216 XX XXX XXX',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Adresse',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Gender selector
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Genre',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('Sélectionner'),
                                ),
                                DropdownMenuItem(
                                  value: 'M',
                                  child: Text('Masculin'),
                                ),
                                DropdownMenuItem(
                                  value: 'F',
                                  child: Text('Féminin'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedGender = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _nationalityController,
                              decoration: InputDecoration(
                                labelText: 'Nationalité',
                                prefixIcon: const Icon(Icons.flag_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: 'Tunisienne',
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Niveau (only for students)
                      if (_selectedRole == 'student') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedNiveauCode,
                          decoration: InputDecoration(
                            labelText: 'Niveau éducatif',
                            prefixIcon: const Icon(Icons.school_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Sélectionner un niveau'),
                            ),
                            ...niveauxList.map(
                              (n) => DropdownMenuItem(
                                value: n['code'] as String,
                                child: Text(n['name'] as String),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedNiveauCode = v;
                            // Reset section if niveau changes and doesn't require section
                            if (!niveauRequiresSection(v)) {
                              _selectedSectionCode = null;
                            }
                          }),
                        ),

                        // Section (only for 2ème, 3ème, Bac)
                        if (niveauRequiresSection(_selectedNiveauCode)) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedSectionCode,
                            decoration: InputDecoration(
                              labelText: 'Section *',
                              prefixIcon: const Icon(Icons.category_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Sélectionner une section'),
                              ),
                              ...sectionsList.map(
                                (s) => DropdownMenuItem(
                                  value: s['code'] as String,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: _parseColor(
                                            s['color'] as String?,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(s['name'] as String),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedSectionCode = v),
                            validator: (v) {
                              if (niveauRequiresSection(_selectedNiveauCode) &&
                                  v == null) {
                                return 'Section requise pour ce niveau';
                              }
                              return null;
                            },
                          ),
                        ],

                        // Class selection
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, _) {
                            final classesAsync = ref.watch(classesProvider);
                            return classesAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Erreur: $e'),
                              data: (classesState) {
                                final classes = classesState.classes;
                                return DropdownButtonFormField<String>(
                                  value: _selectedClassId,
                                  decoration: InputDecoration(
                                    labelText: 'Classe',
                                    prefixIcon: const Icon(
                                      Icons.class_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Sélectionner une classe'),
                                    ),
                                    ...classes.map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedClassId = v),
                                );
                              },
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Date of birth
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dateOfBirth ?? DateTime(2000),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _dateOfBirth = date);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date de naissance',
                            prefixIcon: const Icon(Icons.cake_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _dateOfBirth != null
                                ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color: _dateOfBirth != null ? null : Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      // Show credentials after creation
                      if (_generatedCredentials != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Utilisateur créé!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _generatedCredentials!,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getRoleColor(_selectedRole),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isEditing ? Icons.save : Icons.add,
                            color: Colors.white,
                          ),
                    label: Text(
                      isEditing ? 'Enregistrer' : 'Créer utilisateur',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'staff':
        return Colors.blue;
      case 'teacher':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final notifier = ref.read(usersProvider.notifier);

    bool success;
    final email = _emailController.text;
    final password = _passwordController.text;

    debugPrint('UserFormDialog: Starting submit, isEditing=$isEditing');
    debugPrint('UserFormDialog: fullName=${_fullNameController.text}');
    debugPrint('UserFormDialog: classId=$_selectedClassId');

    if (isEditing) {
      debugPrint('UserFormDialog: Calling updateUser for ${widget.user!.id}');
      success = await notifier.updateUser(
        widget.user!.id,
        fullName: _fullNameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        role: _selectedRole,
        studentCode: _studentCodeController.text.isNotEmpty ? _studentCodeController.text : null,
        dateOfBirth: _dateOfBirth?.toIso8601String().split('T')[0],
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        niveauCode: _selectedNiveauCode,
        sectionCode: _selectedSectionCode,
        gender: _selectedGender,
        nationality: _nationalityController.text.isNotEmpty
            ? _nationalityController.text
            : null,
      );
      debugPrint('UserFormDialog: updateUser returned $success');

      // Update enrollment if class is selected
      if (success && _selectedClassId != null && _selectedRole == 'student') {
        debugPrint('UserFormDialog: Calling updateEnrollment');
        final enrollResult = await notifier.updateEnrollment(
          widget.user!.id,
          _selectedClassId!,
        );
        debugPrint('UserFormDialog: updateEnrollment returned $enrollResult');
      }
    } else {
      success = await notifier.createUser(
        email: email,
        password: password,
        fullName: _fullNameController.text,
        role: _selectedRole,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        dateOfBirth: _dateOfBirth?.toIso8601String().split('T')[0],
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        niveauCode: _selectedNiveauCode,
        sectionCode: _selectedSectionCode,
        gender: _selectedGender,
        nationality: _nationalityController.text.isNotEmpty
            ? _nationalityController.text
            : null,
        classId: _selectedClassId,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);

      if (!isEditing) {
        // Show credentials dialog for newly created user
        _showCredentialsDialog(
          context,
          _fullNameController.text,
          email,
          password,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCredentialsDialog(
    BuildContext context,
    String name,
    String email,
    String password,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Utilisateur créé !', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'IMPORTANT - Sauvegardez ces identifiants',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Communiquez ces informations à l\'utilisateur pour qu\'il puisse se connecter.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nom: $name',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildCredentialRow(ctx, 'Email', email),
            const SizedBox(height: 12),
            _buildCredentialRow(ctx, 'Mot de passe', password),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: 'Email: $email\nMot de passe: $password'),
              );
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Identifiants copiés !'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy_all),
            label: const Text('Copier tout'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Fermer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copié !'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Copier',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.grey;
  }
}

class _RoleButton extends StatelessWidget {
  final String role;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RoleButton({
    required this.role,
    required this.label,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  Color get _color {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'staff':
        return Colors.blue;
      case 'teacher':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? _color : Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
