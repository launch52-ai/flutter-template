// Template: UpdateStatus enum for force update feature
//
// Location: lib/features/force_update/domain/enums/
//
// Usage:
// 1. Copy to target location
// 2. Update import paths as needed

/// Represents the current update status of the app.
enum UpdateStatus {
  /// App is up to date, no action needed.
  upToDate,

  /// A newer version is available but not required.
  /// Show dismissible soft update dialog.
  softUpdateAvailable,

  /// App version is below minimum required.
  /// Block app until user updates.
  forceUpdateRequired,

  /// Server is under maintenance.
  /// Block app and show maintenance screen.
  maintenanceMode,
}
