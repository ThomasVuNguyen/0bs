import 'package:flutter/foundation.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:uuid/uuid.dart';
import 'tab_model.dart';

class BrowserModel extends ChangeNotifier {
  final List<TabModel> _tabs = [];
  int _currentIndex = 0;
  final _uuid = Uuid();

  List<TabModel> get tabs => List.unmodifiable(_tabs);
  int get currentIndex => _currentIndex;
  TabModel? get currentTab => _tabs.isNotEmpty ? _tabs[_currentIndex] : null;

  BrowserModel() {
    _addInitialTab();
  }

  Future<void> _addInitialTab() async {
    await addTab();
  }

  Future<void> addTab({String url = 'https://www.google.com'}) async {
    final controller = WebviewController();
    final id = _uuid.v4();

    final tab = TabModel(id: id, controller: controller, url: url);

    _tabs.add(tab);
    _currentIndex = _tabs.length - 1;
    notifyListeners();

    // Initialize the controller
    await tab.initialize();
    await tab.controller.loadUrl(url);

    // Listen for title changes
    tab.controller.title.listen((title) {
      tab.title = title;
      notifyListeners();
    });

    // Listen to url changes (if available directly or via other streams)
    // webview_windows controller has url stream usually
    tab.controller.url.listen((newUrl) {
      tab.url = newUrl;
      notifyListeners();
    });

    // Inject Drag-to-Scroll script
    tab.controller.loadingState.listen((state) {
      if (state == LoadingState.navigationCompleted) {
        tab.controller.executeScript(r'''
          (function() {
            let isDragging = false;
            let lastX, lastY;
            
            window.addEventListener('mousedown', (e) => {
              // Only left click (button 0) and not on interactive elements if needed needed
              // But for now, global drag
              isDragging = true;
              lastX = e.clientX;
              lastY = e.clientY;
            });
            
            window.addEventListener('mouseup', () => {
              isDragging = false;
            });
            
            window.addEventListener('mouseleave', () => {
              isDragging = false;
            });
            
            window.addEventListener('mousemove', (e) => {
              if (isDragging) {
                // Determine delta
                const deltaX = e.clientX - lastX;
                const deltaY = e.clientY - lastY;
                
                // Scroll
                window.scrollBy(-deltaX, -deltaY);
                
                // Update last pos
                lastX = e.clientX;
                lastY = e.clientY;
              }
            });
          })();
        ''');
      }
    });

    notifyListeners();
  }

  Future<void> closeTab(String id) async {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final tab = _tabs[index];
    tab.dispose();
    _tabs.removeAt(index);

    if (_currentIndex >= _tabs.length) {
      _currentIndex = _tabs.length - 1;
    }

    if (_tabs.isEmpty) {
      // Create a new empty tab if all closed? Or just close app?
      // Browsers usually keep one tab or show a start page.
      // We will create a new empty tab.
      await addTab();
    } else {
      notifyListeners();
    }
  }

  void switchToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void updateUrl(String url) {
    if (currentTab != null) {
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
      currentTab!.controller.loadUrl(url);
    }
  }
}
