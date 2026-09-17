import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final String? savedClass = prefs.getString('user_class');
  final String? userName = prefs.getString('user_name');

  runApp(MaterialApp(
    title: 'Purix Academy',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF070B14)),
    home: (isLoggedIn && savedClass != null) 
        ? DashboardScreen(selectedClass: savedClass, userName: userName ?? 'Student') 
        : const LoginScreen(),
  ));
}