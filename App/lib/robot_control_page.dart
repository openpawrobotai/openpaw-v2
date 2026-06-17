import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RobotControlPage extends StatefulWidget {
  final String robotUrl;
  const RobotControlPage({super.key, required this.robotUrl});

  @override
  State<RobotControlPage> createState() => _RobotControlPageState();
}

class _RobotControlPageState extends State<RobotControlPage> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _hasTriedReload = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/119.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            print('WebView started loading URL: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            String message;
            final desc = error.description.toLowerCase();

            if (desc.contains('timed out')) {
              message =
              'Connection timed out. Check robot power and Wi‑Fi, then tap Refresh.';
            } else if (desc.contains('aborted') ||
                error.errorCode == -6 ||
                error.errorCode == -1) {
              message =
              'Connection aborted. Retrying once, or tap Refresh if it continues.';
              if (!_hasTriedReload) {
                _hasTriedReload = true;
                controller.reload();
              }
            } else {
              message =
              'WebView error ${error.errorCode}: ${error.description}';
            }

            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
            setState(() => _isLoading = false);
          },
        ),
      );

    // Small delay then load the robot URL
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      print('Loading robot URL: ${widget.robotUrl}');
      controller.loadRequest(Uri.parse(widget.robotUrl));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot Control Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasTriedReload = true;
              });
              controller.reload();
            },
            tooltip: 'Reload Robot Page',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
