import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_sidebar.dart';

// Provider for contact info state using AsyncNotifier pattern (Riverpod 3.x)
class ContactInfoNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return await loadContactInfo();
  }

  Future<Map<String, dynamic>> loadContactInfo() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('app_settings')
          .select()
          .eq('key', 'contact_info')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        return Map<String, dynamic>.from(response['value'] as Map);
      } else {
        // Default values
        return {
          'phone': '53 518 054',
          'email': 'lyceepythagore19@gmail.com',
          'address': 'Rue El Emir Faicel, Kairouan',
          'facebook': 'https://www.facebook.com/profile.php?id=100064041700592',
          'maps': 'https://www.google.com/maps/dir/35.831194,10.594667/35.6744015,10.1017/@35.7573801,10.0281956,10z',
          'website': 'https://aziz-tounsi.github.io/',
          'hours': 'Lun - Sam: 08:00 - 17:00',
        };
      }
    } catch (e) {
      // Return defaults on error
      return {
        'phone': '53 518 054',
        'email': 'lyceepythagore19@gmail.com',
        'address': 'Rue El Emir Faicel, Kairouan',
        'facebook': 'https://www.facebook.com/profile.php?id=100064041700592',
        'maps': 'https://www.google.com/maps/dir/35.831194,10.594667/35.6744015,10.1017/@35.7573801,10.0281956,10z',
        'website': 'https://aziz-tounsi.github.io/',
        'hours': 'Lun - Sam: 08:00 - 17:00',
      };
    }
  }

  Future<bool> saveContactInfo(Map<String, dynamic> info) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Check if record exists
      final existing = await supabase
          .from('app_settings')
          .select()
          .eq('key', 'contact_info')
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('app_settings')
            .update({'value': info, 'updated_at': DateTime.now().toIso8601String()})
            .eq('key', 'contact_info');
      } else {
        await supabase
            .from('app_settings')
            .insert({
              'key': 'contact_info',
              'value': info,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
      
      state = AsyncValue.data(info);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final contactInfoProvider = AsyncNotifierProvider<ContactInfoNotifier, Map<String, dynamic>>(
  ContactInfoNotifier.new,
);

class ContactInfoScreen extends ConsumerStatefulWidget {
  const ContactInfoScreen({super.key});

  @override
  ConsumerState<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends ConsumerState<ContactInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _facebookController;
  late TextEditingController _mapsController;
  late TextEditingController _websiteController;
  late TextEditingController _hoursController;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _facebookController = TextEditingController();
    _mapsController = TextEditingController();
    _websiteController = TextEditingController();
    _hoursController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _facebookController.dispose();
    _mapsController.dispose();
    _websiteController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic> data) {
    _phoneController.text = data['phone'] ?? '';
    _emailController.text = data['email'] ?? '';
    _addressController.text = data['address'] ?? '';
    _facebookController.text = data['facebook'] ?? '';
    _mapsController.text = data['maps'] ?? '';
    _websiteController.text = data['website'] ?? '';
    _hoursController.text = data['hours'] ?? '';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final info = {
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'facebook': _facebookController.text.trim(),
      'maps': _mapsController.text.trim(),
      'website': _websiteController.text.trim(),
      'hours': _hoursController.text.trim(),
    };

    final success = await ref.read(contactInfoProvider.notifier).saveContactInfo(info);

    setState(() {
      _isLoading = false;
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(success 
                ? 'Informations sauvegardées avec succès!' 
                : 'Erreur lors de la sauvegarde'),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactInfoAsync = ref.watch(contactInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/settings'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: contactInfoAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
                    data: (data) {
                      // Populate fields only once when data is first loaded
                      if (_phoneController.text.isEmpty && data['phone'] != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _populateFields(data);
                        });
                      }
                      return _buildForm(context);
                    },
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.contact_phone,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations de Contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Gérer les informations affichées dans l\'application',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Modifications non sauvegardées',
                    style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveChanges,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Sauvegarde...' : 'Sauvegarder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        onChanged: () => setState(() => _hasChanges = true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact principal
            _buildSectionCard(
              title: 'Contact Principal',
              icon: Icons.phone,
              iconColor: const Color(0xFF10B981),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        label: 'Numéro de téléphone',
                        hint: '53 518 054',
                        icon: Icons.phone_outlined,
                        validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTextField(
                        controller: _emailController,
                        label: 'Adresse email',
                        hint: 'contact@ecole.com',
                        icon: Icons.email_outlined,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Requis';
                          if (!v!.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _addressController,
                  label: 'Adresse physique',
                  hint: 'Rue El Emir Faicel, Kairouan',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _hoursController,
                  label: 'Heures d\'ouverture',
                  hint: 'Lun - Sam: 08:00 - 17:00',
                  icon: Icons.access_time_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Réseaux sociaux
            _buildSectionCard(
              title: 'Réseaux Sociaux & Web',
              icon: Icons.public,
              iconColor: const Color(0xFF3B82F6),
              children: [
                _buildTextField(
                  controller: _facebookController,
                  label: 'Lien Facebook',
                  hint: 'https://www.facebook.com/...',
                  icon: Icons.facebook,
                  iconColor: const Color(0xFF1877F2),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _mapsController,
                  label: 'Lien Google Maps',
                  hint: 'https://www.google.com/maps/...',
                  icon: Icons.map_outlined,
                  iconColor: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _websiteController,
                  label: 'Site Web / Portfolio',
                  hint: 'https://...',
                  icon: Icons.language,
                  iconColor: const Color(0xFF8B5CF6),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Preview
            _buildPreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color? iconColor,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: iconColor ?? Colors.grey[500], size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.visibility, color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Aperçu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_iphone, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Visible dans l\'app mobile',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildPreviewItem(Icons.phone, _phoneController.text.isEmpty ? '---' : _phoneController.text),
              _buildPreviewItem(Icons.email, _emailController.text.isEmpty ? '---' : _emailController.text),
              _buildPreviewItem(Icons.location_on, _addressController.text.isEmpty ? '---' : _addressController.text),
              _buildPreviewItem(Icons.access_time, _hoursController.text.isEmpty ? '---' : _hoursController.text),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
