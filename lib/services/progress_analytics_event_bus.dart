class ProgressAnalyticsEventBus {
  ProgressAnalyticsEventBus._();

  static int _revision = 0;
  static int _reconciledRevision = 0;

  static int get revision => _revision;

  static bool get isDirty => _revision != _reconciledRevision;

  static void markDirty() {
    _revision++;
  }

  static void markReconciled() {
    _reconciledRevision = _revision;
  }

  static void resetForTest() {
    _revision = 0;
    _reconciledRevision = 0;
  }
}
