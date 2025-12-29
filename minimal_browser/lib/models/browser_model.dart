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

  // Custom CSS Rules
  final Map<String, String> _customCssRules = {
    'mail.google.com': r'''
      /* Hide right side panel (Tasks, Keep, etc sidebar) */
      .brC-brG { display: none !important; }
      
      /* Hide the right-hand side add-on bar container */
      .bAw { width: 0 !important; display: none !important; }

      /* Hide native ads (Top picks) in Promotions/Social tabs */
      tr[class*="zA"] > td > div > span:contains("Ad") { display: none !important; } 
      
      /* Hide "Meet" and "Hangouts" left sidebar sections if present */
      .aT5-aOt-I-JX-Jr, 
      div[aria-label="Hangouts"], 
      div[aria-label="Meet"] { display: none !important; }

      /* General cleanup for cleaner look */
      .aKh { height: auto !important; } /* Adjust header height if needed */
    ''',
  };

  Map<String, String> get customCssRules => _customCssRules;

  void addOrUpdateCssRule(String domain, String css) {
    _customCssRules[domain] = css;
    notifyListeners();
  }

  void removeCssRule(String domain) {
    _customCssRules.remove(domain);
    notifyListeners();
  }

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
        _injectCustomCss(tab);

        tab.controller.executeScript(r'''
          (function() {
            let isDragging = false;
            let lastX, lastY;
            let scrollTarget = window;

            function getScrollParent(node) {
              if (!node || node === document || node === document.body || node === document.documentElement) {
                return window;
              }
              
              const style = window.getComputedStyle(node);
              const overflowY = style.overflowY;
              const overflowX = style.overflowX;
              const isScrollableY = (overflowY === 'auto' || overflowY === 'scroll') && node.scrollHeight > node.clientHeight;
              const isScrollableX = (overflowX === 'auto' || overflowX === 'scroll') && node.scrollWidth > node.clientWidth;

              if (isScrollableY || isScrollableX) {
                return node;
              }
              return getScrollParent(node.parentNode);
            }

            // Mouse Drag-to-Scroll
            window.addEventListener('mousedown', (e) => {
              if (e.button !== 0) return;
              
              const tag = e.target.tagName.toLowerCase();
              if (tag === 'input' || tag === 'textarea' || tag === 'select' || tag === 'a' || tag === 'button') {
                return;
              }
              if (e.target.isContentEditable) return;

              scrollTarget = getScrollParent(e.target);
              
              isDragging = true;
              isDragStarted = false; // Reset drag started flag
              startX = e.clientX;
              startY = e.clientY;
              lastX = e.clientX;
              lastY = e.clientY;
            });
            
            window.addEventListener('mouseup', () => { isDragging = false; isDragStarted = false; });
            window.addEventListener('mouseleave', () => { isDragging = false; isDragStarted = false; });
            
            window.addEventListener('mousemove', (e) => {
              if (isDragging && e.buttons === 1) { 
                // Threshold check
                if (!isDragStarted) {
                  const moveX = Math.abs(e.clientX - startX);
                  const moveY = Math.abs(e.clientY - startY);
                  if (moveX > 5 || moveY > 5) {
                    isDragStarted = true;
                  } else {
                    return; // Ignore micro-movements
                  }
                }

                const deltaX = e.clientX - lastX;
                const deltaY = e.clientY - lastY;
                
                if (scrollTarget === window) {
                   window.scrollBy(-deltaX, -deltaY);
                } else {
                   scrollTarget.scrollLeft -= deltaX;
                   scrollTarget.scrollTop -= deltaY;
                }
                
                lastX = e.clientX;
                lastY = e.clientY;
              } else {
                 isDragging = false;
                 isDragStarted = false;
              }
            });
          })();
        ''');
      }
    });
  }

  void _injectCustomCss(TabModel tab) {
    final url = tab.url;
    _customCssRules.forEach((domain, css) {
      if (url.contains(domain)) {
        // Escape newlines and quotes for JS string
        final safeCss = css.replaceAll('\n', ' ').replaceAll("'", "\\'");

        tab.controller.executeScript('''
          (function() {
            const style = document.createElement('style');
            style.textContent = '$safeCss';
            document.head.appendChild(style);
            console.log('Antigravity Browser: Custom CSS injected for $domain');
          })();
        ''');
      }
    });
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
