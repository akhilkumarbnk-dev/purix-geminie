import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  bool _isLoading = true;

  // Drive link se direct File ID nikal kar Clean Preview Link banana
  String _getCleanPreviewLink(String url) {
    String cleanUrl = url.trim();
    if (cleanUrl.contains('drive.google.com')) {
      // Regex to extract exactly the 25+ character Google Drive File ID
      final regExp = RegExp(r'[-\w]{25,}');
      final match = regExp.firstMatch(cleanUrl);
      if (match != null) {
        // Ye line ensure karegi ki PDF hamesha bina sign-in ke preview mode me khule
        return 'https://drive.google.com/file/d/${match.group(0)}/preview';
      }
    }
    return cleanUrl;
  }

  @override
  void initState() {
    super.initState();
    
    final finalUrl = _getCleanPreviewLink(widget.pdfUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF070B14))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));
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
      body: Stack(
        children: [
          // App ke andar WebView render karega (Bina Chrome ke)
          WebViewWidget(controller: _controller),
          
          // Jab tak PDF load ho raha hai, tab tak Neon Loader dikhega
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: neonCyan,
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }
}