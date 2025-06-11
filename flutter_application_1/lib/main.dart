import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'pages/home_page.dart';
import 'pages/tracker_page.dart';
import 'pages/profile_page.dart';
import 'pages/splash_page.dart';
import 'pages/welcome_page.dart';
import 'pages/sign_up_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/pairing_page.dart';
import 'widgets/calendar_section.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00A3FF),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(
            0xFF00A3FF,
            <int, Color>{
              50: Color(0xFFE6F6FF),
              100: Color(0xFFB3E5FF),
              200: Color(0xFF80D4FF),
              300: Color(0xFF4DC3FF),
              400: Color(0xFF26B6FF),
              500: Color(0xFF00A3FF),
              600: Color(0xFF0092E6),
              700: Color(0xFF007ECC),
              800: Color(0xFF006BB3),
              900: Color(0xFF004A80),
            },
          ),
        ).copyWith(
          primary: const Color(0xFF00A3FF),
          secondary: const Color(0xFF00A3FF),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/welcome': (context) => const WelcomePage(),
        '/sign_up': (context) => const SignUpPage(),
        '/sign_in': (context) => const SignInPage(),
        '/profile_setup': (context) => const ProfileSetupPage(),
        '/pairing': (context) => const PairingPage(),
        '/main': (context) => const MainPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final GlobalKey<CalendarSectionState> _calendarKey =
      GlobalKey<CalendarSectionState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(calendarKey: _calendarKey),
      TrackerPage(onBackToHome: () {
        setState(() {
          _selectedIndex = 0;
        });
      }),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _calendarKey.currentState?.forceRefresh();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF00A3FF),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: Iconify(
                  MaterialSymbols.home_rounded,
                  size: 24,
                  color: _selectedIndex == 0
                      ? const Color(0xFF00A3FF)
                      : Colors.grey,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Iconify(
                  Ph.heartbeat_fill,
                  size: 24,
                  color: _selectedIndex == 1
                      ? const Color(0xFF00A3FF)
                      : Colors.grey,
                ),
                label: 'Tracker',
              ),
              BottomNavigationBarItem(
                icon: Iconify(
                  MaterialSymbols.person,
                  size: 24,
                  color: _selectedIndex == 2
                      ? const Color(0xFF00A3FF)
                      : Colors.grey,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
