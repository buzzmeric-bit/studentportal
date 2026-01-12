/// Supabase configuration
/// Replace these values with your actual Supabase project credentials
class SupabaseConfig {
  static const String url = 'https://cazuauxivrboygehrkij.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhenVhdXhpdnJib3lnZWhya2lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4ODQzMTYsImV4cCI6MjA4MzQ2MDMxNn0._rYkNtubGQo745cX-YApjWQyYC4s8r37SEa6AoiVppo';
  
  // Storage bucket names
  static const String profileBucket = 'profiles';
  static const String documentsBucket = 'documents';
  /// Bucket for announcement attachments
  /// CREATE IN SUPABASE: Storage > New bucket > "announcement-attachments" > Public
  static const String attachmentsBucket = 'announcement-attachments';
  /// Bucket for suggestion attachments
  /// CREATE IN SUPABASE: Storage > New bucket > "suggestion-attachments" > Public
  static const String suggestionAttachmentsBucket = 'suggestion-attachments';
}
