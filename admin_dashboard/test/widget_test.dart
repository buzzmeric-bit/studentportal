import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/main.dart';

void main() {
  testWidgets('Admin Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AdminApp()));
    
    // Verify the app builds
    expect(find.byType(AdminApp), findsOneWidget);
  });
}