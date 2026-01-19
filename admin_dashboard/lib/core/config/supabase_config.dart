import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for Admin Dashboard
/// Uses the same Supabase project as the student app
class SupabaseConfig {
  static const String url = 'https://cazuauxivrboygehrkij.supabase.co';
  
  /// Service role key for admin operations (creating users, etc.)
  /// WARNING: Never expose in public client apps!
  static const String serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhenVhdXhpdnJib3lnZWhya2lqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Nzg4NDMxNiwiZXhwIjoyMDgzNDYwMzE2fQ.Lc4xJVNGspo7sCHLg7nq_K_UAbgvpyIravgNtbVpmLE';
  
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhenVhdXhpdnJib3lnZWhya2lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4ODQzMTYsImV4cCI6MjA4MzQ2MDMxNn0._rYkNtubGQo745cX-YApjWQyYC4s8r37SEa6AoiVppo';

  /// Storage bucket name for announcement attachments
  /// CREATE THIS BUCKET IN SUPABASE DASHBOARD: Storage > New bucket > "announcement-attachments" > Public
  static const String attachmentsBucket = 'announcement-attachments';
  
  /// Storage bucket name for suggestion attachments  
  /// CREATE THIS BUCKET IN SUPABASE DASHBOARD: Storage > New bucket > "suggestion-attachments" > Public
  static const String suggestionAttachmentsBucket = 'suggestion-attachments';

  /// Main client for user auth and normal operations
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Admin client with service_role key for creating users
  static SupabaseClient? _adminClient;
  static SupabaseClient get adminClient {
    _adminClient ??= SupabaseClient(url, serviceRoleKey);
    return _adminClient!;
  }

  static Future<void> initialize() async {
    // Use anon key for normal auth operations
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Check if a storage bucket exists
  static Future<bool> bucketExists(String bucketName) async {
    try {
      final buckets = await client.storage.listBuckets();
      return buckets.any((b) => b.name == bucketName);
    } catch (_) {
      return false;
    }
  }
}
