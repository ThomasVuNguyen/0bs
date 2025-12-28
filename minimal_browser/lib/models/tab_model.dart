import 'package:webview_windows/webview_windows.dart';

class TabModel {
  final String id;
  String title;
  String url;
  final WebviewController controller;
  bool isInitialized = false;

  TabModel({
    required this.id,
    this.title = 'New Tab',
    this.url = 'about:blank',
    required this.controller,
  });

  Future<void>? _initFuture;

  Future<void> initialize() {
    if (isInitialized) return Future.value();
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      await controller.initialize();
      isInitialized = true;
    } catch (e) {
      // Reset future on failure to allow retry
      _initFuture = null;
      rethrow;
    }
  }

  void dispose() {
    controller.dispose();
  }
}
