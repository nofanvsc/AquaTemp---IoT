import 'package:flutter/material.dart';
import 'package:aquatemp/pages/home.dart';
import 'package:aquatemp/pages/updateSuhu.dart';
import 'package:animations/animations.dart';
import 'package:aquatemp/pages/profil.dart';
import 'package:aquatemp/pages/riwayat.dart';
import 'package:aquatemp/pages/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://broimfjahqvfaiosfpkj.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyb2ltZmphaHF2ZmFpb3NmcGtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyNDA4ODYsImV4cCI6MjA2MDgxNjg4Nn0.zuq0K6uSIO9R0LfgGKm3YZKo_OtCDdvAtUm7EHc403Y';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  // Sign in anonymously
  try {
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'ak4kurniawan@gmail.com',
      password: 'Spensaganomor1',
    );
    debugPrint('Anonymous authentication successful');
  } catch (e) {
    debugPrint('Error in anonymous authentication: $e');
    // If sign in fails, try to sign up
    try {
      await Supabase.instance.client.auth.signUp(
        email: 'ak4kurniawan@gmail.com',
        password: 'Spensaganomor1',
      );
      debugPrint('Anonymous user created');
    } catch (e) {
      debugPrint('Error creating anonymous user: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const SplashScreen(),
      color: const Color(0xFFEEF1F8),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    UpdateSuhuPage(),
    RiwayatPage(),
    ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.thermostat),
            label: 'Suhu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
