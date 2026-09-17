import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/sheet_service.dart';
import 'quiz_screen.dart';

class ChapterScreen extends StatefulWidget {
  final String className;
  final String subjectName;
  final String subSubjectName; 
  final String mode;

  const ChapterScreen({super.key, required this.className, required this.subjectName, required this.subSubjectName, required this.mode});

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _chapters = [];
  bool _isHindiLanguage = false;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    String prefix = widget.className.contains("9") ? "9th" : widget.className.contains("10") ? "10th" : "8th";
    String sheetName = widget.mode == 'mcq' ? '$prefix MCQ' : widget.mode == 'notes' ? '$prefix Notes' : '$prefix practice pdf';
    final data = await SheetService.fetchSheetData(sheetName);

    // Exact Sub-Subject (e.g., Physics) ke chapters filter karna
    final filtered = data.where((item) {
      final sub = (item['Subject'] ?? item['subject'] ?? '').toString().trim().toLowerCase();
      final subSub = (item['Sub-subject'] ?? item['sub-subject'] ?? '').toString().trim().toLowerCase();
      return sub == widget.subjectName.toLowerCase() && subSub == widget.subSubjectName.toLowerCase();
    }).toList();

    if (mounted) setState(() { _chapters = filtered; _isLoading = false; });
  }

  // App ke andar hi PDF open karna
  void _openPdfLink(String url) async {
    if (url.trim().isEmpty || url.trim() == 'N/A') return;
    String finalUrl = url.trim();
    if (finalUrl.contains('drive.google.com') && finalUrl.contains('/view')) {
      finalUrl = finalUrl.replaceAll('/view?usp=sharing', '/preview').replaceAll('/view', '/preview');
    }
    try {
      await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error opening PDF.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00F0FF);
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D), elevation: 0, iconTheme: const IconThemeData(color: Colors.white),
        title: Text("${widget.subSubjectName.toUpperCase()} - CHAPTERS", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          ActionChip(
            backgroundColor: neonCyan.withValues(alpha: 0.15),
            label: Text(_isHindiLanguage ? "HIN" : "ENG", style: const TextStyle(color: neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
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
                final pdfLinkHin = item['Drive-link-hin'] ?? item['Drive_link_hin'] ?? '';
                final pdfLinkEng = item['Drive-link-eng'] ?? item['Drive_link_eng'] ?? '';
                final selectedPdfLink = _isHindiLanguage ? (pdfLinkHin.isNotEmpty ? pdfLinkHin : pdfLinkEng) : (pdfLinkEng.isNotEmpty ? pdfLinkEng : pdfLinkHin);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF0B111E), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                  child: Row(
                    children: [
                      Expanded(child: Text(chapterName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
                      if (widget.mode == 'mcq')
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF66)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(selectedClass: widget.className, subject: widget.subjectName, chapter: chapterName, quizSetNumber: 1))),
                          child: const Text("START", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                        )
                      else
                        IconButton(icon: Icon(widget.mode == 'notes' ? Icons.menu_book : Icons.picture_as_pdf, color: neonCyan), onPressed: () => _openPdfLink(selectedPdfLink)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}