import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String title;

  const PaymentWebViewScreen({
    super.key,
    required this.initialUrl,
    required this.title,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  // Белый список разрешенных хостов // NEW
  final List<String> _allowedHosts = [ // NEW
    'yookassa.ru', // NEW
    'yoomoney.ru', // NEW
    'yookassaproj201514.vercel.app', // NEW
  ]; // NEW

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final Uri parsedUri = Uri.parse(request.url); // NEW

            // Редирект успешного завершения -> Закрываем экран // NEW
            if (request.url.contains('yookassaproj201514.vercel.app') || request.url.contains('success')) { // CHANGED
              Navigator.of(context).pop(); // CHANGED - Закрытие без передачи результата на клиент
              return NavigationDecision.prevent; // CHANGED
            }

            // Валидация доменов // NEW
            final bool isAllowedHost = _allowedHosts.any((host) => parsedUri.host.endsWith(host)); // NEW
            if (isAllowedHost || parsedUri.scheme == 'about') { // NEW
              return NavigationDecision.navigate; // NEW
            } // NEW

            return NavigationDecision.prevent; // CHANGED
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}