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

  @override
  void initState() {
    super.initState();
    
    // Google Drive share link ko securely 'Preview' mode me convert karna
    String finalUrl = widget.pdfUrl.trim();
    if (finalUrl.contains('drive.google.com') && finalUrl.contains('/view')) {
      finalUrl = finalUrl.replaceAll('/view?usp=sharing', '/preview').replaceAll('/view', '/preview');
    }

    // WebView Initialize karna
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
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
      // App ke andar hi secure Google Drive PDF preview dikhana
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: neonCyan),
            ),
        ],
      ),
    );
  }
}