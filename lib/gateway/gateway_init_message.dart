/// Passed to [gatewayEntryPoint] when spawning the Gateway isolate.
///
/// Only plain Dart types — no Isar objects, no Flutter types.
/// Dart copies plain objects across isolate boundaries via [SendPort].
class GatewayInitMessage {
  /// Absolute path to the directory containing the Isar database file.
  /// Obtained in Isolate 1 via [getApplicationDocumentsDirectory()] and
  /// passed here so the Gateway isolate never needs Flutter plugins.
  final String isarDirectory;

  const GatewayInitMessage({
    required this.isarDirectory,
  });
}
