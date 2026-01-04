import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://ibqsjydimimijsxukfsf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlicXNqeWRpbWltaWpzeHVrZnNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcyMzEwNzYsImV4cCI6MjA4MjgwNzA3Nn0.c2JyD1bAcu2wvqSsXqf3y0DhjtEp_0rHK5Cv_XMeo-o';
  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  GoTrueClient get auth => Supabase.instance.client.auth;
}