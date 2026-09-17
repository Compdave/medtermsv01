// lib/core/services/version_service.dart

import 'supabase_service.dart';

/// Handles app version checking and update notification.
/// Errors are thrown — callers are responsible for try/catch.
class VersionService {
  VersionService._();

  static final _client = SupabaseService.client;

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch the current live version string from the versions table.
  /// Returns null if the table is empty.
  /// Calls: latestversion()
  static Future<String?> fetchLatestVersion() async {
    final response = await _client.rpc('latestversion');

    final list = response as List;
    if (list.isEmpty) return null;
    return (list.first as Map<String, dynamic>)['version'] as String?;
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  /// Update the stored version string to [version].
  /// Always writes to id = 1 (single-row table).
  /// Called automatically when a user installs a newer build.
  /// Calls: updateversion(p_version)
  static Future<void> updateVersion(String version) async {
    await _client.rpc(
      'updateversion',
      params: {'p_version': version},
    );
  }

  // ---------------------------------------------------------------------------
  // Compare
  // ---------------------------------------------------------------------------

  /// Returns true if [current] is newer than [stored].
  /// Compares semver segments numerically to avoid string sort issues.
  /// Example: "2.21.37.38" > "2.21.37.37" returns true.
  static bool isNewerVersion({
    required String stored,
    required String current,
  }) {
    try {
      final s = stored.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      final length = s.length > c.length ? s.length : c.length;
      for (int i = 0; i < length; i++) {
        final sv = i < s.length ? s[i] : 0;
        final cv = i < c.length ? c[i] : 0;
        if (cv > sv) return true;
        if (cv < sv) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check the stored version against [currentVersion] and update
  /// the DB if the current build is newer. Returns true if an update
  /// was recorded (i.e. this user was first to install the new version).
  static Future<bool> checkAndUpdateVersion(String currentVersion) async {
    final stored = await fetchLatestVersion();
    if (stored == null ||
        isNewerVersion(stored: stored, current: currentVersion)) {
      await updateVersion(currentVersion);
      return true;
    }
    return false;
  }
}
