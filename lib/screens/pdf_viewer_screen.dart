import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

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
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _secureScreen();
  }

  // Screenshot aur Screen Recording Block Karne Ka Logic
  Future<void> _secureScreen() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  void dispose() {
    FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    super.dispose();
  }

  // Ye function Google Drive ke share link ko Direct Download/View link me badal deta hai
  String _getDirectPdfLink(String url) {
    if (url.contains('drive.google.com')) {
      // Link se File ID nikalna
      final RegExp regExp = RegExp(r'[-\w]{25,}');
      final match = regExp.firstMatch(url);
      if (match != null) {
        final fileId = match.group(0);
        // Direct PDF stream link return karna
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final directUrl = _getDirectPdfLink(widget.pdfUrl);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
      // Ye widget directly PDF ko app ke andar show karega
      body: SfPdfViewer.network(
        directUrl,
        key: _pdfViewerKey,
        canShowScrollHead: false,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        pageSpacing: 4,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error loading PDF: Ensure link is 'Anyone with link'")),
          );
        },
      ),
    );
  }
}