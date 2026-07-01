import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> loginWithUsername(String username, String password) async {
    // Hapi 1: gjej email-in që i përket këtij username
    final profile = await _supabase
        .from('profiles')
        .select('email')
        .eq('username', username)
        .maybeSingle();

    if (profile == null) {
      throw Exception('Username nuk ekziston');
    }

    final email = profile['email'] as String;

    // Hapi 2: hyr me email + password
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}