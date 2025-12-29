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

  Future<String> getHtmlContent() async {
    if (!isInitialized) return '';
    // webview_windows executeScript returns dynamic, usually the result of the evaluation
    // We assume it returns the string or we might need to JSON decode if it returns a JSON string?
    // The plugin docs say it returns the result of the execution.
    final result = await controller.executeScript(
      'document.documentElement.outerHTML',
    );
    return result.toString();
  }

  void dispose() {
    controller.dispose();
  }
}
