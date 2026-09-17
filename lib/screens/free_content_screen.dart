import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/sheet_service.dart';

class FreeContentScreen extends StatefulWidget {
  final String selectedClass;

  const FreeContentScreen({super.key, required this.selectedClass});

  @override
  State<FreeContentScreen> createState() => _FreeContentScreenState();
}

class _FreeContentScreenState extends State<FreeContentScreen> {
  List<dynamic> _freeItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFreeContent();
  }

  Future<void> _fetchFreeContent() async {
    try {
      final sheetName = "${widget.selectedClass.replaceAll('Class ', '')} Notes";
      final data = await SheetService.fetchSheetData(sheetName);

      final freeFiltered = data.where((item) {
        final access = (item['Access Type'] ?? item['Is-free'] ?? item['is_free'] ?? '').toString().trim();
        return access.toUpperCase() == 'FREE';
      }).toList();

      if (!mounted) return;
      setState(() {
        _freeItems = freeFiltered;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openPdf(String url) async {
    if (url.isEmpty || url == 'N/A') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF link not available.')),
      );
      return;
    }

    String finalUrl = url;
    if (url.contains('drive.google.com') && url.contains('/view')) {
      finalUrl = finalUrl.replaceAll('/view?usp=sharing', '/preview').replaceAll('/view', '/preview');
    }

    final uri = Uri.parse(finalUrl);
    try {
      final launched = await canLaunchUrl(uri);
      if (!mounted) return;

      if (launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF link.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening PDF.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00F0FF);
    const darkVoid = Color(0xFF070B14);

    return Scaffold(
      backgroundColor: darkVoid,
      appBar: AppBar(
        title: Text('${widget.selectedClass} - Free Matrix', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0F1D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonCyan))
          : _freeItems.isEmpty
              ? const Center(
                  child: Text(
                    'No Free Content Available Yet.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _freeItems.length,
                  itemBuilder: (context, index) {
                    final item = _freeItems[index];
                    final chapterName = item['Chapter'] ?? item['chapter'] ?? 'Free Resource';
                    final subjectName = item['Subject'] ?? item['subject'] ?? 'General';
                    final pdfLink = item['Drive-link-hin'] ?? item['Drive-link-eng'] ?? '';

                    return Card(
                      color: const Color(0xFF0B111E),
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: neonCyan.withValues(alpha: 0.3), width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          chapterName,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Subject: $subjectName (FREE ACCESS)',
                          style: TextStyle(color: neonCyan.withValues(alpha: 0.8), fontSize: 11, fontFamily: 'monospace'),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: neonCyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _openPdf(pdfLink),
                          child: const Text('View PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}