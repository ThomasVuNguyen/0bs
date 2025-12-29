import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'models/browser_model.dart';
import 'ui/browser_screen.dart';

void main() {
  runApp(const BrowserApp());

  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(600, 400);
    win.size = const Size(1024, 768);
    win.alignment = Alignment.center;
    win.title = "Minimal Browser";
    win.show();
  });
}

class BrowserApp extends StatelessWidget {
  const BrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BrowserModel())],
      child: MaterialApp(
        title: 'Minimal Browser',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const BrowserScreen(),
      ),
    );
  }
}
