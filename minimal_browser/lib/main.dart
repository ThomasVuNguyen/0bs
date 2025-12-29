import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/browser_model.dart';
import 'ui/browser_screen.dart';

void main() {
  runApp(const BrowserApp());

  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(600, 400);
    win.size = const Size(1024, 768);
    win.alignment = Alignment.center;
    win.title = "0bs Browser";
    win.show();
  });
}

class BrowserApp extends StatelessWidget {
  const BrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    const colCoral = Color(0xFFF86F54);
    const colPaper = Color(0xFFF3F1E4);
    const colCharcoal = Color(0xFF212121);
    const colRoyalBlue = Color(0xFF537CF7);
    const colSeaGreen = Color(0xFF00A6A6);

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BrowserModel())],
      child: MaterialApp(
        title: '0bs Browser',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: colPaper,
          colorScheme: ColorScheme.light(
            primary: colCoral,
            secondary: colRoyalBlue,
            surface: colPaper,
            onSurface: colCharcoal,
            background: colPaper,
            onBackground: colCharcoal,
            tertiary: colSeaGreen,
          ),
          textTheme: GoogleFonts.bricolageGrotesqueTextTheme().apply(
            bodyColor: colCharcoal,
            displayColor: colCharcoal,
          ),
          iconTheme: const IconThemeData(color: colCharcoal),
        ),
        home: const BrowserScreen(),
      ),
    );
  }
}
