import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late String _directPdfUrl;

  @override
  void initState() {
    super.initState();
    _directPdfUrl = _getDirectDownloadLink(widget.pdfUrl);
  }

  String _getDirectDownloadLink(String url) {
    String cleanUrl = url.trim();
    if (cleanUrl.contains('drive.google.com')) {
      final regExp = RegExp(r'[-\w]{25,}');
      final match = regExp.firstMatch(cleanUrl);
      if (match != null) {
        String fileId = match.group(0)!;
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }
    return cleanUrl;
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00F0FF);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 13, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SfPdfViewer.network(
        _directPdfUrl,
        canShowScrollHead: false,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        pageLayoutMode: PdfPageLayoutMode.continuous,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          debugPrint('PDF Loaded Successfully!');
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          debugPrint('PDF Load Failed: ${details.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load PDF. Check Drive share link.')),
          );
        },
      ),
    );
  }
}