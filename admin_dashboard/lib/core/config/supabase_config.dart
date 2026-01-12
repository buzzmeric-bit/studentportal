import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for Admin Dashboard
/// Uses the same Supabase project as the student app
class SupabaseConfig {
  static const String url = 'https://cazuauxivrboygehrkij.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhenVhdXhpdnJib3lnZWhya2lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4ODQzMTYsImV4cCI6MjA4MzQ2MDMxNn0._rYkNtubGQo745cX-YApjWQyYC4s8r37SEa6AoiVppo';

  /// Storage bucket name for announcement attachments
  /// CREATE THIS BUCKET IN SUPABASE DASHBOARD: Storage > New bucket > "announcement-attachments" > Public
  static const String attachmentsBucket = 'announcement-attachments';
  
  /// Storage bucket name for suggestion attachments  
  /// CREATE THIS BUCKET IN SUPABASE DASHBOARD: Storage > New bucket > "suggestion-attachments" > Public
  static const String suggestionAttachmentsBucket = 'suggestion-attachments';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
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
