import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

/// Tells a driver's device that a trip is waiting for them.
///
/// Removed along with global.dart in "Upload clean passenger app without
/// secrets", and for a better reason than the Maps key: FCM's v1 API is
/// authorised by a **service account**, and a service account shipped inside an
/// APK can be extracted by anyone who downloads it — earlier in this repository
/// two API keys were pulled out of a release APK in about a second. That
/// credential is not scoped to sending one notification; it is a server
/// identity.
///
/// So this is rebuilt to work exactly as before, with one difference: the
/// credential is read from the build rather than stored here.
///
///   flutter build apk --release \
///     --dart-define=FCM_SERVICE_ACCOUNT="$(cat service-account.json)"
///
/// Unset, the app builds and every other screen behaves normally — the driver
/// simply is not pushed, and the reason is logged rather than swallowed.
///
/// The real fix is not a better hiding place. Sending belongs on a server the
/// passenger cannot read: a Cloud Function that takes a trip id, looks the
/// driver's token up itself, and holds the credential where no phone can reach
/// it. Until that exists this keeps the flow working end to end.
class PushNotificationSystem {
  PushNotificationSystem._();

  static const String _serviceAccountJson =
      String.fromEnvironment('FCM_SERVICE_ACCOUNT');

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  /// Pushes [tripID] to the device holding [deviceToken].
  ///
  /// Never throws: a notification that fails to send must not take down the
  /// screen that requested the trip — the trip itself is already written to the
  /// database, and the driver app also watches for it.
  static Future<void> sendNotificationToSelectedDriver(
    String deviceToken,
    BuildContext context,
    String tripID,
  ) async {
    if (_serviceAccountJson.isEmpty) {
      debugPrint(
        'PushNotificationSystem: FCM_SERVICE_ACCOUNT is not set — '
        'trip $tripID was created but no push was sent to $deviceToken.',
      );
      return;
    }

    auth.AutoRefreshingAuthClient? client;

    try {
      final Map<String, dynamic> account =
          jsonDecode(_serviceAccountJson) as Map<String, dynamic>;

      // The project the credential belongs to is in the credential itself, so
      // the endpoint cannot drift out of step with the account being used.
      final String projectId = account['project_id'] as String;

      client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(account),
        _scopes,
      );

      final response = await client.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': {
            'token': deviceToken,
            'notification': {
              'title': 'NEW TRIP REQUEST',
              'body': 'A passenger is waiting for a ride.',
            },
            // The driver app reads the id from here and loads the trip itself,
            // so the notification carries a reference rather than a copy that
            // can go stale between sending and tapping.
            'data': {'tripID': tripID},
          },
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'PushNotificationSystem: FCM returned ${response.statusCode} — '
          '${response.body}',
        );
      }
    } catch (error) {
      debugPrint('PushNotificationSystem: send failed — $error');
    } finally {
      client?.close();
    }
  }
}
