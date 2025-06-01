import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/tracker_page.dart';
import 'pages/profile_page.dart';
import 'pages/splash_page.dart';
import 'pages/welcome_page.dart';
import 'pages/sign_up_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/profile_setup_page.dart';
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
        primaryColor: const Color(0xFF007BFF),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(
            0xFF007BFF,
            <int, Color>{
              50: Color(0xFFE3F0FF),
              100: Color(0xFFB8DAFF),
              200: Color(0xFF8CC4FF),
              300: Color(0xFF5FAEFF),
              400: Color(0xFF399BFF),
              500: Color(0xFF007BFF),
              600: Color(0xFF006FE6),
              700: Color(0xFF005FCC),
              800: Color(0xFF004FB3),
              900: Color(0xFF003380),
            },
          ),
        ).copyWith(
          primary: const Color(0xFF007BFF),
          secondary: const Color(0xFF007BFF),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/welcome': (context) => const WelcomePage(),
        '/sign_up': (context) => const SignUpPage(),
        '/sign_in': (context) => const SignInPage(),
        '/profile_setup': (context) => const ProfileSetupPage(),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
