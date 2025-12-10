// lib/screens/webview_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 유지

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    this.title = '웹 페이지', // 기본 제목 설정
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  double _progress = 0; // 로딩 진행률 저장

  @override
  void initState() {
    super.initState();

    // WebViewController 초기화
    _controller = WebViewController();

    // ★ 최종 수정: setNavigationDelegate는 웹에서 지원되지 않으므로, 모바일 환경에서만 설정합니다.
    if (!kIsWeb) {
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _progress = 0;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _progress = 1.0;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      );
    }

    _controller.loadRequest(Uri.parse(widget.url)); // URL 로드는 모든 환경에서 실행
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          // 로딩 진행률은 모바일 환경에서만 정확히 표시됩니다.
          child: _progress < 1.0 && !kIsWeb
              ? LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          )
              : Container(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}