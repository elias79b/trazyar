// abstract final class AppConfig {
//   static const String supabaseUrl = String.fromEnvironment(
//     'SUPABASE_URL',
//     defaultValue: 'https://xvktvjbnarrhleiidltp.supabase.co',
//   );
//   static const String supabaseAnonKey = String.fromEnvironment(
//     'SUPABASE_ANON_KEY',
//     defaultValue: 'sb_publishable_eguv5H3UjJdzmIr3Fe-SfA_a33q7yq9',
//   );
//
//   static bool get isSupabaseConfigured {
//     return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
//   }
// }
class AppConfig {
  static const supabaseUrl = 'https://xvktvjbnarrhleiidltp.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_eguv5H3UjJdzmIr3Fe-SfA_a33q7yq9';
}