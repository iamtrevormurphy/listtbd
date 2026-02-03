/// Supabase configuration
/// Uses dart-define environment variables for production builds
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rhzfulgclrzrgtfwrdlp.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable___apbSc0pPE0mQ70-_3JVA_srbUBTts',
  );

  // Prevent instantiation
  SupabaseConfig._();
}
