import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sheet_service.dart';
import 'quiz_screen.dart';
import 'pdf_viewer_screen.dart';

class ChapterScreen extends StatefulWidget {
  final String className;
  final String subjectName;
  final String subSubjectName;
  final String mode;

  const ChapterScreen({
    super.key,
    required this.className,
    required this.subjectName,
    required this.subSubjectName,
    required this.mode,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _chapters = [];
  bool _isHindiLanguage = false;
  
  // NAYA: User ka subscription status store karne ke liye
  String _userSubscription = 'FREE';

  @override
  void initState() {
    super.initState();
    _loadChaptersAndUserStatus();
  }

  Future<void> _loadChaptersAndUserStatus() async {
    // 1. Check local status (FREE ya PRO)
    final prefs = await SharedPreferences.getInstance();
    _userSubscription = prefs.getString('user_sub') ?? 'FREE';

    // 2. Fetch sheet data
    String prefix = widget.className.contains("9") ? "9th" : widget.className.contains("10") ? "10th" : "8th";
    String sheetName = widget.mode == 'mcq' ? '$prefix MCQ' : widget.mode == 'notes' ? '$prefix Notes' : '$prefix practice pdf';
    final data = await SheetService.fetchSheetData(sheetName);

    final filtered = data.where((item) {
      final sub = (item['Subject'] ?? item['subject'] ?? '').toString().trim().toLowerCase();
      final subSub = (item['Sub-subject'] ?? item['sub-subject'] ?? '').toString().trim().toLowerCase();
      return sub == widget.subjectName.toLowerCase() && subSub == widget.subSubjectName.toLowerCase();
    }).toList();

    if (mounted) {
      setState(() {
        _chapters = filtered;
        _isLoading = false;
      });
    }
  }

  // VALIDATION: PDF Open karne se pehle check
  void _openPdfLink(String url, String title, bool isFreeContent) {
    if (!isFreeContent && _userSubscription != 'PRO') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔒 PRO CONTENT: Please upgrade to Purix PRO from dashboard."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (url.trim().isEmpty || url.trim() == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link not available.")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfUrl: url,
          title: title,
        ),
      ),
    );
  }

  // VALIDATION: Quiz start karne se pehle check
  void _startQuiz(String chapterName, bool isFreeContent) {
    if (!isFreeContent && _userSubscription != 'PRO') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔒 PRO QUIZ: Please upgrade to Purix PRO from dashboard."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          selectedClass: widget.className,
          subject: widget.subjectName,
          chapter: chapterName,
          quizSetNumber: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00F0FF);
    const neonGold = Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${widget.subSubjectName.toUpperCase()} - CHAPTERS",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          ActionChip(
            backgroundColor: neonCyan.withOpacity(0.15),
            label: Text(
              _isHindiLanguage ? "HIN" : "ENG",
              style: const TextStyle(color: neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () => setState(() => _isHindiLanguage = !_isHindiLanguage),
          ),
          const SizedBox(width: 8)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonCyan))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final item = _chapters[index];
                final chapterName = item['Chapter'] ?? item['chapter'] ?? 'Topic ${index + 1}';
                
                // NAYA: Google sheet se 'Access Type' ya 'Is-free' column padhna
                final accessType = (item['Access Type'] ?? item['Is-free'] ?? item['is_free'] ?? 'PAID').toString().trim().toUpperCase();
                final bool isFreeContent = accessType == 'FREE';
                final bool hasAccess = isFreeContent || _userSubscription == 'PRO';

                final pdfLinkHin = item['Drive-link-hin'] ?? item['Drive_link_hin'] ?? '';
                final pdfLinkEng = item['Drive-link-eng'] ?? item['Drive_link_eng'] ?? '';
                final selectedPdfLink = _isHindiLanguage 
                    ? (pdfLinkHin.isNotEmpty ? pdfLinkHin : pdfLinkEng) 
                    : (pdfLinkEng.isNotEmpty ? pdfLinkEng : pdfLinkHin);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B111E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasAccess ? Colors.white12 : Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Lock/Unlock Icon
                      Icon(
                        hasAccess ? Icons.check_circle_outline : Icons.lock_outline,
                        color: hasAccess ? neonCyan : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chapterName,
                          style: TextStyle(
                            color: hasAccess ? Colors.white : Colors.white60,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.mode == 'mcq')
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasAccess ? const Color(0xFF00FF66) : Colors.grey[800],
                          ),
                          onPressed: () => _startQuiz(chapterName, isFreeContent),
                          child: Text(
                            hasAccess ? "START" : "LOCKED",
                            style: TextStyle(
                              color: hasAccess ? Colors.black : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: Icon(
                            hasAccess 
                                ? (widget.mode == 'notes' ? Icons.menu_book : Icons.picture_as_pdf)
                                : Icons.lock,
                            color: hasAccess ? neonCyan : Colors.redAccent,
                          ),
                          onPressed: () => _openPdfLink(selectedPdfLink, chapterName, isFreeContent),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}