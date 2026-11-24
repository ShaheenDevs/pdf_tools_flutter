import 'package:flutter/material.dart';
import 'package:pdf_tools_flutter/app/app.locator.dart';
import 'package:pdf_tools_flutter/app/app_theme.dart';
import 'package:pdf_tools_flutter/ui/views/home/home_view.dart';
import 'package:stacked_services/stacked_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const PdfToolsApp());
}

class PdfToolsApp extends StatelessWidget {
  const PdfToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Tools & Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [StackedService.routeObserver],
      home: const HomeView(),
    );
  }
}
