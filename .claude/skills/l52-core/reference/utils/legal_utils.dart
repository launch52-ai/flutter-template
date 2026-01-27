// Template: Legal URL Utilities
//
// Location: lib/core/utils/legal_utils.dart
//
// Usage:
// 1. Copy to target location
// 2. Import in login screen and settings screen
// 3. Use openPrivacyPolicy() and openTermsOfService()
//
// Dependencies: url_launcher

import 'package:url_launcher/url_launcher.dart';

import '../constants/legal_constants.dart';

/// Utilities for opening legal documents.
///
/// Usage in login screen:
/// ```dart
/// TextButton(
///   onPressed: LegalUtils.openPrivacyPolicy,
///   child: Text('Privacy Policy'),
/// )
/// ```
///
/// Usage in settings screen:
/// ```dart
/// ListTile(
///   title: Text('Privacy Policy'),
///   trailing: Icon(Icons.open_in_new),
///   onTap: LegalUtils.openPrivacyPolicy,
/// )
/// ```
abstract final class LegalUtils {
  /// Open Privacy Policy in browser.
  static Future<bool> openPrivacyPolicy() async {
    return _launchUrl(LegalConstants.privacyPolicyUrl);
  }

  /// Open Terms of Service in browser.
  static Future<bool> openTermsOfService() async {
    return _launchUrl(LegalConstants.termsOfServiceUrl);
  }

  /// Open support email.
  static Future<bool> openSupportEmail({String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalConstants.supportEmail,
      queryParameters: subject != null ? {'subject': subject} : null,
    );
    return _launchUrl(uri.toString());
  }

  static Future<bool> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
