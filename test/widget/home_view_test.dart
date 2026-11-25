import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_tools_flutter/ui/views/home/home_view.dart';

void main() {
  testWidgets('home view displays the initial document workspace', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeView()),
    );

    expect(find.text('PDF Tools & Scanner'), findsOneWidget);
    expect(find.text('Quick tools'), findsOneWidget);

    // ensureVisible walks the actual scrollable ancestors. This avoids
    // ambiguously selecting the outer ListView and the nested GridView's
    // Scrollable when using scrollUntilVisible.
    await tester.ensureVisible(find.text('No documents yet'));
    await tester.pumpAndSettle();

    expect(find.text('Scan document'), findsOneWidget);
    expect(find.text('Recent documents'), findsOneWidget);
    expect(find.text('No documents yet'), findsOneWidget);
  });
}
