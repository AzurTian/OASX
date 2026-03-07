part of server;

extension ServerControllerDeployIo on ServerController {
  void readDeploy() {
    final filePath = '${rootPathServer.value}\\config\\deploy.yaml';
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        deployContent.value = file.readAsStringSync();
      } else {
        deployContent.value = 'File not found';
      }
    } catch (e) {
      deployContent.value = 'Error reading file: $e';
    }
  }

  void writeDeploy(String value) {
    final filePath = '${rootPathServer.value}\\config\\deploy.yaml';
    deployContent.value = value;
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        file.writeAsStringSync(deployContent.value);
      } else {
        deployContent.value = 'File not found';
      }
    } catch (e) {
      deployContent.value = 'Error writing file: $e';
    }
  }
}
