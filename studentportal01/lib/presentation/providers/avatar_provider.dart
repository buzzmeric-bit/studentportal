import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Available preset avatars
const List<String> presetAvatars = [
  'assets/avatars/Gemini_Generated_Image_1d8gtw1d8gtw1d8g.png',
  'assets/avatars/Gemini_Generated_Image_3wzusr3wzusr3wzu.png',
  'assets/avatars/Gemini_Generated_Image_6yaeg6yaeg6yaeg6.png',
  'assets/avatars/Gemini_Generated_Image_73wn1j73wn1j73wn.png',
  'assets/avatars/Gemini_Generated_Image_7ro6yx7ro6yx7ro6.png',
  'assets/avatars/Gemini_Generated_Image_he1ml7he1ml7he1m.png',
  'assets/avatars/Gemini_Generated_Image_kzsyvkzsyvkzsyvk.png',
  'assets/avatars/Gemini_Generated_Image_v27t6wv27t6wv27t.png',
  'assets/avatars/Gemini_Generated_Image_v4c5stv4c5stv4c5.png',
];

// Avatar state - can be preset path or custom file path
class AvatarState {
  final String? presetPath;
  final String? customFilePath;
  
  const AvatarState({this.presetPath, this.customFilePath});
  
  bool get hasAvatar => presetPath != null || customFilePath != null;
  bool get isCustom => customFilePath != null;
}

class AvatarNotifier extends StateNotifier<AvatarState> {
  AvatarNotifier() : super(const AvatarState()) {
    _loadSavedAvatar();
  }
  
  // Get current user ID for user-specific storage
  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;
  
  String get _presetKey => 'avatar_preset_path_${_currentUserId ?? 'guest'}';
  String get _customKey => 'avatar_custom_path_${_currentUserId ?? 'guest'}';
  
  Future<void> _loadSavedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final preset = prefs.getString(_presetKey);
    final custom = prefs.getString(_customKey);
    
    if (custom != null) {
      state = AvatarState(customFilePath: custom);
    } else if (preset != null) {
      state = AvatarState(presetPath: preset);
    }
  }
  
  /// Call this when user logs in to reload their avatar
  Future<void> reloadForCurrentUser() async {
    state = const AvatarState(); // Reset first
    await _loadSavedAvatar();
  }
  
  void selectPreset(String path) {
    state = AvatarState(presetPath: path);
    _savePreset(path);
  }
  
  void selectCustom(String filePath) {
    state = AvatarState(customFilePath: filePath);
    _saveCustom(filePath);
  }
  
  void clear() {
    state = const AvatarState();
    _clearSaved();
  }
  
  Future<void> _savePreset(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presetKey, path);
    await prefs.remove(_customKey);
  }
  
  Future<void> _saveCustom(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customKey, filePath);
    await prefs.remove(_presetKey);
  }
  
  Future<void> _clearSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_presetKey);
    await prefs.remove(_customKey);
  }
}

final avatarProvider = StateNotifierProvider<AvatarNotifier, AvatarState>((ref) {
  return AvatarNotifier();
});
