import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_windows/webview_windows.dart';
import '../models/browser_model.dart';
import '../models/tab_model.dart';
import '../services/process_stats_service.dart';

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: Consumer<BrowserModel>(
              builder: (context, model, child) {
                if (model.tabs.isEmpty) {
                  return const Center(child: Text('No Global Tabs'));
                }
                return IndexedStack(
                  index: model.currentIndex,
                  children: model.tabs
                      .map((tab) => _TabContent(tab: tab))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabContent extends StatefulWidget {
  final TabModel tab;
  const _TabContent({required this.tab});

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> {
  @override
  void initState() {
    super.initState();
    // Ensure tab is initialized if not already (safeguard)
    widget.tab.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.tab.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Webview(
      widget.tab.controller,
      permissionRequested: _onPermissionRequested,
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
    String url,
    WebviewPermissionKind kind,
    bool isUserInitiated,
  ) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.deny;
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar();

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final TextEditingController _urlController = TextEditingController();
  final ProcessStatsService _statsService = ProcessStatsService();

  @override
  void initState() {
    super.initState();
    _statsService.startMonitoring();
  }

  @override
  void dispose() {
    _statsService.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<BrowserModel>();
    final currentTab = model.currentTab;

    // Update URL bar if the current tab's URL changes and it's not focused?
    // For simplicity, we just sync completely for now or rely on user input.
    // A proper browser updates the text only when the page changes, not while typing.
    // We will update it if the currentTab.url doesn't match and it's not being edited (simple check).
    if (currentTab != null &&
        _urlController.text != currentTab.url &&
        !_urlController.selection.isValid) {
      // This is a naive check.
      // Better: Listen to tab changes in a refined way.
      // For MVP, just setting it if empty or vastly different.
      // Actually, let's just let the model drive it when switching tabs.
    }

    // When switching tabs, we definitely want to update the text.
    // We can use a PostFrameCallback or just set it in build if specific conditions meet.
    // Let's rely on a listener in the state.

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // Tab Bar
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: model.tabs.length,
                    itemBuilder: (context, index) {
                      final tab = model.tabs[index];
                      final isSelected = index == model.currentIndex;
                      return GestureDetector(
                        onTap: () {
                          model.switchToTab(index);
                          _urlController.text = tab.url;
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tab.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 14),
                                onPressed: () {
                                  model.closeTab(tab.id);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    model.addTab();
                  },
                ),
              ],
            ),
          ),

          // Navigation Bar
          if (currentTab != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      if (currentTab.isInitialized) {
                        await currentTab.controller.goBack();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () async {
                      if (currentTab.isInitialized) {
                        await currentTab.controller.goForward();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      if (currentTab.isInitialized) {
                        await currentTab.controller.reload();
                      }
                    },
                  ),
                  Expanded(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: TextField(
                        controller: _urlController
                          ..text = currentTab.url, // Naive binding
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search or enter address',
                          contentPadding: EdgeInsets.only(bottom: 12),
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          model.updateUrl(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

          // Resource Stats Bar
          StreamBuilder<ResourceStats>(
            stream: _statsService.statsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final stats = snapshot.data!;
              final ramMb = (stats.ramBytes / 1024 / 1024).toStringAsFixed(1);
              final cpu = stats.cpuPercent.toStringAsFixed(1);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'RAM: ${ramMb}MB',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CPU: $cpu%',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
