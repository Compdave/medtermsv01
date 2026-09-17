// lib/core/services/version_service.dart

import 'dart:io';
import 'supabase_service.dart';

/// Handles app version checking against the app_versions table
/// (see version-notification-plan.md).
///
/// Read-only: writes to app_versions only ever happen server-side — the
/// release script (Component A, scripts/notify_release_version.sh) sets
/// pending_version right after a smoke-tested release, and the
/// app-version-promotion Edge Function (Component B) promotes it to
/// live_version once the store confirms the build is actually live. The
/// client has no write policy on this table and never writes to it —
/// unlike the old single-row "app writes on first open" table this
/// replaced, which let any client claim to be the latest version.
///
/// Errors are thrown from [fetchLatestVersion] — callers are responsible
/// for try/catch, or use [checkForUpdate] which never throws.
class VersionService {
  VersionService._();

  static final _client = SupabaseService.client;

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch the current live version string for [versionCheckAppId] on this
  /// platform. Returns null if no row exists yet, or on unsupported
  /// (non-iOS/Android) platforms.
  static Future<String?> fetchLatestVersion(String versionCheckAppId) async {
    if (!Platform.isIOS && !Platform.isAndroid) return null;
    final platform = Platform.isIOS ? 'ios' : 'android';

    final response = await _client
        .from('app_versions')
        .select('live_version')
        .eq('app_id', versionCheckAppId)
        .eq('platform', platform)
        .maybeSingle();

    return response?['live_version'] as String?;
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

  // ---------------------------------------------------------------------------
  // Combined check
  // ---------------------------------------------------------------------------

  /// Returns the live version string if [currentVersion] is behind it, or
  /// null if already up to date, no row exists yet, or the check failed.
  /// Never throws — a broken version check should never block sign-in or
  /// any other flow that calls it.
  static Future<String?> checkForUpdate({
    required String versionCheckAppId,
    required String currentVersion,
  }) async {
    try {
      final stored = await fetchLatestVersion(versionCheckAppId);
      if (stored == null) return null;
      final hasUpdate =
          isNewerVersion(stored: currentVersion, current: stored);
      return hasUpdate ? stored : null;
    } catch (_) {
      return null;
    }
  }
}
