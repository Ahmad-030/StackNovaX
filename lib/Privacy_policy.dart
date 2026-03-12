import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});
  @override State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: (r) =>
        (r.url.startsWith('http') || r.url.startsWith('https'))
            ? NavigationDecision.prevent
            : NavigationDecision.navigate,
      ));
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    final html = await rootBundle.loadString('assets/privacy_policy.html');
    await _controller.loadHtmlString(html, baseUrl: 'about:blank');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FF),
    appBar: AppBar(
      title: const Text('Privacy Policy',
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600, fontSize: 16)),
      backgroundColor: const Color(0xFF0D47A1),
      foregroundColor: Colors.white,
      elevation: 0, centerTitle: true,
    ),
    body: Stack(children: [
      WebViewWidget(controller: _controller),
      if (_isLoading) const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: Color(0xFF2979FF)),
        SizedBox(height: 12),
        Text('Loading privacy policy…', style: TextStyle(color: Color(0xFF8898AA), fontSize: 13)),
      ])),
    ]),
  );
}
