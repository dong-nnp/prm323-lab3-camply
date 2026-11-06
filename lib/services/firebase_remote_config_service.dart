import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'remote_config_service.dart';

final class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService(this._initializeFirebase);

  final Future<void> Function() _initializeFirebase;
  FirebaseRemoteConfig? _remote;
  Map<String, dynamic> _defaults = {};

  @override
  Future<bool> fetchAndActivate() async {
    if (_defaults.isEmpty) {
      final source = await rootBundle.loadString(
        'firebase/remote-config-defaults.json',
      );
      _defaults = jsonDecode(source) as Map<String, dynamic>;
    }
    await _initializeFirebase();
    final remote = FirebaseRemoteConfig.instance;
    if (_remote == null) {
      await remote.setDefaults(_defaults);
      await remote.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 12),
        ),
      );
      _remote = remote;
    }
    return remote.fetchAndActivate();
  }

  @override
  String getString(String key) {
    final value = _remote?.getString(key).trim();
    final valid =
        value != null &&
        value.isNotEmpty &&
        (key == 'event_milestones_enabled'
            ? value.toLowerCase() == 'true' || value.toLowerCase() == 'false'
            : value.length <= 500);
    return valid ? value : _defaults[key]?.toString() ?? '';
  }
}
