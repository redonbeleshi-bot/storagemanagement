import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/magazina_screen.dart';
import 'screens/furnizuesit_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/order_cart_screen.dart';  // ✅ Shto këtë import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menaxhim Magazine',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/magazina': (context) => const MagazinaScreen(),
        '/furnizuesit': (context) => const FurnizuesitScreen(),
        '/raporte': (context) => const ReportsScreen(),
        // ✅ Nuk kemi nevojë për rrugë të veçantë për OrderCartScreen
        // sepse hapet me Navigator.push nga FurnizuesitScreen
      },
    );
  }
}