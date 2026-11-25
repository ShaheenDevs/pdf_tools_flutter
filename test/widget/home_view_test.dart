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

    await tester.scrollUntilVisible(
      find.text('Scan document'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Scan document'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recent documents'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Recent documents'), findsOneWidget);
    expect(find.text('No documents yet'), findsOneWidget);
  });
}
