import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'class_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      final userName = account?.displayName ?? 'Student';
      final userEmail = account?.email ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', userName);
      await prefs.setString('user_email', userEmail);

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClassScreen(userName: userName),
        ),
      );
    } catch (error) {
      // अगर साइन-इन कैंसिल हो या एरर आए, तो स्मूथ अनुभव के लिए आगे बढ़ने दें
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', 'Student');

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ClassScreen(userName: 'Student'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkVoid = Color(0xFF070B14);
    const goldAccent = Color(0xFFD4AF37);
    const neonCyan = Color(0xFF00F0FF);

    return Scaffold(
      backgroundColor: darkVoid,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // High-Definition Gold Logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: goldAccent.withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PURIX ACADEMY',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: goldAccent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'NEW WAY OF LEARNING',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Access high-yield board question banks, simulations & notes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                height: 52,
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F1F1F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _handleGoogleSignIn(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F1F),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: neonCyan.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'SECURE BOARD LEARNING PORTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}