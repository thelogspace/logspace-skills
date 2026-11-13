// Picked up automatically by flutter test for every test under test/.
// Enables leak tracking: a widget test fails if it leaves undisposed objects
// (controllers, focus nodes, streams, images, ...).
import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings
      // Objects created by flutter_test helpers aren't our leaks.
      .withIgnored(createdByTestHelpers: true);
  await testMain();
}
