import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/browser_model.dart';
import 'ui/browser_screen.dart';

void main() {
  runApp(const BrowserApp());
}

class BrowserApp extends StatelessWidget {
  const BrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrowserModel()),
      ],
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
