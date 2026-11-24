// GENERATED CODE - DO NOT MODIFY BY HAND
//
// This initial locator follows the generated registration style used by
// the reference application. Run build_runner after changing app.dart.

import 'package:stacked_shared/stacked_shared.dart';
import 'package:stacked_services/stacked_services.dart';

final locator = StackedLocator.instance;

Future<void> setupLocator({
  String? environment,
  EnvironmentFilter? environmentFilter,
}) async {
  locator.registerEnvironment(
    environment: environment,
    environmentFilter: environmentFilter,
  );

  locator.registerLazySingleton(() => NavigationService());
}
