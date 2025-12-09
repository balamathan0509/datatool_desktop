import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

void main() {
  runApp(const DataToolApp());
}

class DataToolApp extends StatefulWidget {
  const DataToolApp({super.key});

  @override
  State<DataToolApp> createState() => _DataToolAppState();
}

class _DataToolAppState extends State<DataToolApp> {
  final webviewController = WebviewController();
  Process? backendProcess;
  bool backendReady = false;
  bool webviewReady = false;
  String status = 'Starting backend...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _startBackend();
    setState(() {
      backendReady = true;
      status = 'Launching dashboard...';
    });
    await _initWebView();
  }

  Future<void> _startBackend() async {
    // Path to your backend folder
    const backendDir = r'C:\Users\balam\DataTool\backend';

    backendProcess = await Process.start(
      'python',
      ['app.py'],
      workingDirectory: backendDir,
      runInShell: true,
      mode: ProcessStartMode.detached, // no console window
    );
  }

  Future<void> _waitForBackend() async {
    final uri = Uri.parse('http://127.0.0.1:5000/health');
    for (int i = 0; i < 50; i++) {
      try {
        final client = HttpClient();
        final req = await client.getUrl(uri);
        final res = await req.close();
        if (res.statusCode == 200) {
          return;
        }
      } catch (_) {
        // ignore and retry
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setState(() {
      status = 'Backend did not start. Check Python/Flask.';
    });
  }

  Future<void> _initWebView() async {
    await webviewController.initialize();
    setState(() {
      webviewReady = true;
    });

    // Path to your existing index.html
    const htmlPath =
        'file:///C:/Users/balam/DataTool/frontend/index.html';

    await webviewController.loadUrl(htmlPath);
  }

  @override
  void dispose() {
    webviewController.dispose();
    backendProcess?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataTool Analytics',
      home: Scaffold(
        body: SafeArea(
          child: !backendReady || !webviewReady
              ? Center(child: Text(status))
              : Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xff0f766e),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Data Analytics Dashboard',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            onPressed: () => webviewController.reload(),
                            child: const Text(
                              'Reload dashboard',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Webview(webviewController),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}