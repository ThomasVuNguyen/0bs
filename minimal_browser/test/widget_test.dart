import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_browser/main.dart';
import 'package:minimal_browser/ui/browser_screen.dart';

void main() {
  testWidgets('App uses BrowserScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BrowserApp());

    // Verify that BrowserScreen is present.
    expect(find.byType(BrowserScreen), findsOneWidget);
  });
}
