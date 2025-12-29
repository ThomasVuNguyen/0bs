import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../models/browser_model.dart';
import '../models/tab_model.dart';
import '../services/process_stats_service.dart';

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WindowBorder(
        color: Colors.transparent,
        width: 0,
        child: Column(
          children: [
            const _CustomTitleBar(),
            const _NavBar(),
            Expanded(
              child: Consumer<BrowserModel>(
                builder: (context, model, child) {
                  if (model.tabs.isEmpty) {
                    return const Center(child: Text('No Tabs'));
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
      ),
    );
  }
}

class _CustomTitleBar extends StatelessWidget {
  const _CustomTitleBar();

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Container(
        color: const Color(0xFFF0F0F0), // Light grey background like Arc
        child: Row(
          children: [
            Expanded(child: const _TabsArea()),
            const _WindowButtons(),
          ],
        ),
      ),
    );
  }
}

class _TabsArea extends StatelessWidget {
  const _TabsArea();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<BrowserModel>();

    // We combine tabs and the drag area
    return Stack(
      children: [
        // The drag area fills the space.
        MoveWindow(child: Container()),

        // Tabs on top
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...model.tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  return GestureDetector(
                    onTap: () {
                      model.switchToTab(index);
                    },
                    child: _TabItem(
                      tab: tab,
                      isSelected: index == model.currentIndex,
                      onClose: () => model.closeTab(tab.id),
                    ),
                  );
                }),
                // New Tab Button
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => model.addTab(),
                  tooltip: 'New Tab',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final TabModel tab;
  final bool isSelected;
  final VoidCallback onClose;

  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(top: 4, left: 4, right: 2, bottom: 0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        // Subtle border for inactive tabs or active
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  spreadRadius: 1,
                  blurRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                tab.title.isEmpty ? 'New Tab' : tab.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.close, size: 14, color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) {
    final colors = WindowButtonColors(
      iconNormal: Colors.black,
      mouseOver: const Color(0xFFE0E0E0),
      mouseDown: const Color(0xFFD0D0D0),
      iconMouseOver: Colors.black,
      iconMouseDown: Colors.black,
    );

    final closeColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: Colors.black,
      iconMouseOver: Colors.white,
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: colors),
        MaximizeWindowButton(colors: colors),
        CloseWindowButton(colors: closeColors),
      ],
    );
  }
}

class _NavBar extends StatefulWidget {
  const _NavBar();

  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> {
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

    // Sync URL if needed (simple sync)
    if (currentTab != null &&
        _urlController.text != currentTab.url &&
        !_urlController.selection.isValid) {
      _urlController.text = currentTab.url;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // Nav Controls
          _NavButton(
            icon: Icons.arrow_back,
            onPressed: (currentTab?.isInitialized == true)
                ? () => currentTab!.controller.goBack()
                : null,
          ),
          const SizedBox(width: 4),
          _NavButton(
            icon: Icons.arrow_forward,
            onPressed: (currentTab?.isInitialized == true)
                ? () => currentTab!.controller.goForward()
                : null,
          ),
          const SizedBox(width: 4),
          _NavButton(
            icon: Icons.refresh,
            onPressed: (currentTab?.isInitialized == true)
                ? () => currentTab!.controller.reload()
                : null,
          ),
          const SizedBox(width: 12),

          // Address Bar
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.transparent), // Clean look
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  // Lock icon or generic site icon
                  const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 8),
                        hintText: 'Enter URL',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (value) => model.updateUrl(value),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Stats (Subtle)
          StreamBuilder<ResourceStats>(
            stream: _statsService.statsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final stats = snapshot.data!;
              final ramMb = (stats.ramBytes / 1024 / 1024).toStringAsFixed(0);
              return Text(
                '${ramMb}MB',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: Colors.black54),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 20,
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
        title: const Text('Permission requested'),
        content: Text('Allow \'$kind\'?'),
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
