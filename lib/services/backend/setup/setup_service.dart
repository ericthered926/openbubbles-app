import 'package:bluebubbles/helpers/backend/startup_tasks.dart';
import 'package:bluebubbles/helpers/network/network_tasks.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:get/get.dart';

SetupService setup = Get.isRegistered<SetupService>()
    ? Get.find<SetupService>()
    : Get.put(SetupService());

class SetupService extends GetxService {
  /// Start the setup process
  /// RustPush handles sync differently - just runs contacts refresh
  Future<void> startSetup() async {
    await sync.startFullSync();
    await finishSetup();
  }

  Future<void> finishSetup() async {
    ss.settings.finishedSetup.value = true;
    await ss.saveSettings();

    await StartupTasks.onStartup();
    await NetworkTasks.onConnect();
  }
}
