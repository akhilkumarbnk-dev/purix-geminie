import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/sheet_service.dart';
import 'class_screen.dart';
import 'subject_screen.dart';
import 'free_content_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String selectedClass;
  const DashboardScreen({super.key, required this.userName, required this.selectedClass});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String currentClass;
  late String currentName;
  String currentPhone = '';
  String currentEmail = '';
  String subscriptionStatus = 'FREE';
  final String supportWhatsAppNumber = "919508774890";
  final String academyUPI = "6201161834@ptyes";

  @override
  void initState() {
    super.initState();
    currentClass = widget.selectedClass;
    currentName = widget.userName;
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      currentPhone = prefs.getString('user_phone') ?? '';
      currentEmail = prefs.getString('user_email') ?? 'N/A';
      subscriptionStatus = prefs.getString('user_sub') ?? 'FREE';
      currentName = prefs.getString('user_name') ?? widget.userName;
    });
    if (currentPhone.isEmpty || currentName.isEmpty || currentName.toLowerCase() == 'student') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showProfileDialog(isMandatory: true);
      });
    }
  }

  void _showProfileDialog({bool isMandatory = false}) {
    final nameCtrl = TextEditingController(text: currentName.toLowerCase() == 'student' ? '' : currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);
    const neonGold = Color(0xFFFFD700);

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (dialogContext) => PopScope(
        canPop: !isMandatory,
        child: Dialog(
          backgroundColor: const Color(0xFF0B111E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: neonGold, width: 1.5)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isMandatory ? "COMPLETE CADET PROFILE" : "EDIT CADET PROFILE", style: const TextStyle(color: neonGold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Cadet Name (Mandatory)", neonGold, Icons.person)),
                const SizedBox(height: 14),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: _inputDeco("WhatsApp Number", neonGold, Icons.phone)),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity, height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: neonGold),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      if (name.isEmpty || name.toLowerCase() == 'student' || phone.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid name and 10-digit number.")));
                        return;
                      }
                      final prefs = await SharedPreferences.getInstance();
                      final email = prefs.getString('user_email') ?? 'N/A';
                      await prefs.setString('user_name', name);
                      await prefs.setString('user_phone', phone);
                      
                      if (!mounted) return;
                      setState(() { currentName = name; currentPhone = phone; currentEmail = email; });
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);

                      final sub = await SheetService.syncUserProfile(name: name, phone: phone, email: email, selectedClass: currentClass);
                      if (!mounted) return;
                      await prefs.setString('user_sub', sub);
                      setState(() => subscriptionStatus = sub);
                    },
                    child: const Text("SAVE & SYNC", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, Color color, IconData icon) {
    return InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(icon, color: color, size: 20), filled: true, fillColor: const Color(0xFF101726),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color)),
    );
  }

  void _openWhatsApp({String message = "Hello Purix Academy!"}) async {
    final cleanPhone = supportWhatsAppNumber.replaceAll('+', '').replaceAll(' ', '');
    final uri = Uri.parse("whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}");
    try { await launchUrl(uri); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("WhatsApp couldn't open.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00F0FF);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(backgroundColor: const Color(0xFF25D366), onPressed: () => _openWhatsApp(), icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20), label: const Text("HELP DESK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D), elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(currentName.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)), Text(currentClass.toUpperCase(), style: TextStyle(fontSize: 11, color: neonCyan.withValues(alpha: 0.9))) ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.0,
              children: [
                _moduleCard('MCQ TEST', const Color(0xFF00FF66), Icons.flash_on, 'mcq'),
                _moduleCard('PRACTICE SETS', const Color(0xFFFF9900), Icons.hub, 'practice'),
                _moduleCard('PURIX NOTES', const Color(0xFFBF00FF), Icons.memory, 'notes'),
                _moduleCard('FREE MATRIX', const Color(0xFF00F0FF), Icons.radar, 'free'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(String title, Color color, IconData icon, String mode) {
    return InkWell(
      onTap: () {
        if (mode == 'free') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => FreeContentScreen(selectedClass: currentClass)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectScreen(selectedClass: currentClass, mode: mode)));
        }
      },
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF0B111E), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(icon, color: color, size: 30), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)) ]),
      ),
    );
  }
}