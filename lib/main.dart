import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weshare/screens/Login.dart';
import 'package:weshare/services/supabaseservices.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey:SupabaseService.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF258cf4),
          background: const Color(0xFFf5f7f8),
          onBackground: Colors.black,
        ),
        fontFamily: 'Plus Jakarta Sans',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF258cf4),
          background: const Color(0xFF101922),
          onBackground: Colors.white,
        ),
        fontFamily: 'Plus Jakarta Sans',
      ),
      themeMode: ThemeMode.dark,
      home: const LoginPage(),
    );
  }
}