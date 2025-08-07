import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchSpots() async {
    final response = await client.from('spots').select();
    return List<Map<String, dynamic>>.from(response);
  }
}