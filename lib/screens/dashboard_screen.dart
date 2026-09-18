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

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.selectedClass,
  });

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
    _loadUserDataAndCheckProfile();
  }

  Future<void> _loadUserDataAndCheckProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      currentPhone = prefs.getString('user_phone') ?? '';
      currentEmail = prefs.getString('user_email') ?? '';
      subscriptionStatus = prefs.getString('user_sub') ?? 'FREE';
      currentName = prefs.getString('user_name') ?? widget.userName;
    });

    // STRICT CHECK: Agar phone khali h ya name 'Student' h, to popup open hoga
    if (currentPhone.isEmpty || currentName.isEmpty || currentName.toLowerCase() == 'student') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showProfileDialog(isMandatory: true);
        }
      });
    }
  }

  void _showProfileDialog({bool isMandatory = false}) {
    // Agar name 'Student' hai to box khali dikhaye taaki user apna naam type kare
    final nameCtrl = TextEditingController(text: currentName.toLowerCase() == 'student' ? '' : currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);
    const neonGold = Color(0xFFFFD700);

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (dialogContext) {
        return PopScope(
          canPop: !isMandatory,
          child: Dialog(
            backgroundColor: const Color(0xFF0B111E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: neonGold, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: neonGold, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isMandatory ? "COMPLETE CADET PROFILE" : "EDIT CADET PROFILE",
                        style: const TextStyle(
                          color: neonGold,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Strict Validation: Valid Name and 10-digit WhatsApp/Mobile Number are mandatory to access modules.",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Cadet Name (Mandatory)",
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      prefixIcon: const Icon(Icons.person, color: neonGold, size: 20),
                      filled: true,
                      fillColor: const Color(0xFF101726),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: neonGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "WhatsApp / Mobile Number (10 Digits)",
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      prefixIcon: const Icon(Icons.phone, color: neonGold, size: 20),
                      filled: true,
                      fillColor: const Color(0xFF101726),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: neonGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonGold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 6,
                      ),
                      onPressed: () async {
                        final enteredName = nameCtrl.text.trim();
                        final enteredPhone = phoneCtrl.text.trim();

                        // Strict Validation checks
                        if (enteredName.isEmpty || enteredName.toLowerCase() == 'student' || enteredPhone.length < 10) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error: Please enter your real name and a 10-digit number.")),
                          );
                          return;
                        }

                        final prefs = await SharedPreferences.getInstance();
                        final savedEmail = prefs.getString('user_email') ?? 'N/A';
                        await prefs.setString('user_name', enteredName);
                        await prefs.setString('user_phone', enteredPhone);

                        if (!mounted) return;
                        setState(() {
                          currentName = enteredName;
                          currentPhone = enteredPhone;
                          currentEmail = savedEmail;
                        });

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);

                        final sub = await SheetService.syncUserProfile(
                          name: enteredName,
                          phone: enteredPhone,
                          email: currentEmail.isNotEmpty ? currentEmail : "N/A",
                          selectedClass: currentClass,
                        );

                        if (!mounted) return;
                        await prefs.setString('user_sub', sub);
                        
                        if (!mounted) return;
                        setState(() {
                          subscriptionStatus = sub;
                        });
                      },
                      child: const Text(
                        "SAVE & SYNC ACCESS",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openWhatsApp({String message = "Hello Purix Academy! I want to upgrade to PRO Access."}) async {
    final cleanPhone = supportWhatsAppNumber.replaceAll('+', '').replaceAll(' ', '');
    // WHATSAPP FIX: Direct scheme
    final uri = Uri.parse("whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}");

    try {
      await launchUrl(uri);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp. Please check if installed.")),
      );
    }
  }

  void _showPaymentDialog() {
    const neonGold = Color(0xFFFFD700);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF0B111E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: neonGold, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium, color: neonGold, size: 36),
                const SizedBox(height: 10),
                const Text(
                  "UPGRADE TO PURIX PRO",
                  style: TextStyle(color: neonGold, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Unlock All Chapter MCQs, Premium Notes & Practice Sets @ ₹599",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101726),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      const Text("PAYMENT AMOUNT: ₹599", style: TextStyle(color: neonGold, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("PAY VIA UPI ID", style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace')),
                      const SizedBox(height: 4),
                      SelectableText(
                        academyUPI,
                        style: const TextStyle(color: neonGold, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                      const Divider(color: Colors.white12, height: 18),
                      const Text(
                        "After payment of ₹599, share screenshot on WhatsApp to instantly activate full access.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _openWhatsApp(message: "Hi Purix Academy, I have paid ₹599 for PRO Pass. Here is my screenshot for Cadet: $currentName ($currentClass).");
                    },
                    icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                    label: const Text("SEND SCREENSHOT ON WHATSAPP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeClass() async {
    final newClass = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ClassScreen(
          userName: currentName,
        ),
      ),
    );

    if (newClass != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_class', newClass);

      if (!mounted) return;
      setState(() {
        currentClass = newClass;
      });

      SheetService.syncUserProfile(
        name: currentName,
        phone: currentPhone,
        email: currentEmail.isNotEmpty ? currentEmail : "N/A",
        selectedClass: newClass,
      );
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openProfileSheet() {
    const neonCyan = Color(0xFF00F0FF);
    const neonGreen = Color(0xFF00FF66);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B111E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: neonCyan, width: 1.2),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: neonCyan.withValues(alpha: 0.15),
                child: Text(
                  currentName.isNotEmpty ? currentName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 26, color: neonCyan, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                currentName.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                'NODE: $currentClass  |  STATUS: $subscriptionStatus',
                style: const TextStyle(color: neonGreen, fontSize: 11, fontFamily: 'monospace'),
              ),
              if (currentPhone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'PHONE: $currentPhone',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101726),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.edit, color: neonCyan),
                  title: const Text('Edit Cadet Details', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Update phone or name', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showProfileDialog(isMandatory: false);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101726),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz, color: neonCyan),
                  title: const Text('Switch Target Class', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Change syllabus node', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _changeClass();
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101726),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('Terminate Session (Logout)', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleLogout();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00F0FF);
    const neonGreen = Color(0xFF00FF66);
    const neonGold = Color(0xFFFFD700);
    const darkVoid = Color(0xFF070B14);

    return Scaffold(
      backgroundColor: darkVoid,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF25D366),
        elevation: 6,
        onPressed: () => _openWhatsApp(),
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
        label: const Text(
          "HELP DESK",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: neonGreen,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: neonGreen, blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currentName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              currentClass.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
                color: neonCyan.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _openProfileSheet,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: neonCyan.withValues(alpha: 0.15),
                child: Text(
                  currentName.isNotEmpty ? currentName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: neonCyan, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 750;
          final crossAxisCount = isWideScreen ? 4 : 2;
          final aspectRatio = isWideScreen ? 1.05 : 0.92;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1424),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: neonCyan.withValues(alpha: 0.35), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: neonCyan.withValues(alpha: 0.08),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PURIX ACADEMY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NEW WAY OF LEARNING',
                            style: TextStyle(
                              color: neonCyan.withValues(alpha: 0.85),
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: neonGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: neonGreen.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'TARGET: 95%+',
                          style: TextStyle(
                            color: neonGreen,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'CORE MODULES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: aspectRatio,
                  children: [
                    _sciFiModuleCard(
                      code: 'SEC.01',
                      title: 'MCQ TEST',
                      desc: 'Timed Simulation',
                      glowColor: const Color(0xFF00FF66),
                      icon: Icons.flash_on_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectScreen(
                              selectedClass: currentClass,
                              mode: 'mcq',
                            ),
                          ),
                        );
                      },
                    ),
                    _sciFiModuleCard(
                      code: 'SEC.02',
                      title: 'PRACTICE SETS',
                      desc: 'Question Bank',
                      glowColor: const Color(0xFFFF9900),
                      icon: Icons.hub_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectScreen(
                              selectedClass: currentClass,
                              mode: 'practice',
                            ),
                          ),
                        );
                      },
                    ),
                    _sciFiModuleCard(
                      code: 'SEC.03',
                      title: 'PURIX NOTES',
                      desc: 'Core Theory Data',
                      glowColor: const Color(0xFFBF00FF),
                      icon: Icons.memory_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectScreen(
                              selectedClass: currentClass,
                              mode: 'notes',
                            ),
                          ),
                        );
                      },
                    ),
                    _sciFiModuleCard(
                      code: 'SEC.04',
                      title: 'FREE MATRIX',
                      desc: 'PYQs & Blueprint',
                      glowColor: const Color(0xFF00F0FF),
                      icon: Icons.radar_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FreeContentScreen(
                              selectedClass: currentClass,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1424),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: neonGold.withValues(alpha: 0.5), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: neonGold.withValues(alpha: 0.08),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.workspace_premium, color: neonGold, size: 22),
                              SizedBox(width: 8),
                              Text(
                                "PURIX PRO PASS (₹599)",
                                style: TextStyle(
                                  color: neonGold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: neonGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: neonGold.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              subscriptionStatus == "PRO" ? "ACTIVE" : "UPGRADE",
                              style: const TextStyle(
                                color: neonGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subscriptionStatus == "PRO"
                            ? "All premium tests, PDF assignments, and rapid revision notes are unlocked for your node."
                            : "Unlock all locked tests, complete formula sheets, and chapter assignment banks at just ₹599.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: neonGold, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            backgroundColor: neonGold.withValues(alpha: 0.05),
                          ),
                          onPressed: _showPaymentDialog,
                          icon: const Icon(Icons.bolt, color: neonGold, size: 18),
                          label: Text(
                            subscriptionStatus == "PRO" ? "VIEW MEMBERSHIP PERKS" : "GET PRO ACCESS NOW (₹599)",
                            style: const TextStyle(
                              color: neonGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sciFiModuleCard({
    required String code,
    required String title,
    required String desc,
    required Color glowColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B111E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glowColor.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: glowColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: glowColor.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      color: glowColor,
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: glowColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: glowColor.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: glowColor, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}