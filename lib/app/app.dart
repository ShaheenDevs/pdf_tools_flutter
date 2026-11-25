import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:pdf_tools_flutter/services/file_storage_service.dart';
import 'package:pdf_tools_flutter/ui/views/home/home_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';

@StackedApp(
  routes: [MaterialRoute(page: HomeView, initial: true)],
  dependencies: [
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: AppDatabase),
    LazySingleton(classType: FileStorageService),
  ],
)
class App {}
