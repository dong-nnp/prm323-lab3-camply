import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import 'ai_filter_service.dart';
import 'remote_config_service.dart';

final class FirebaseAiFilterService implements AiFilterService {
  FirebaseAiFilterService(this.initialize, this.config);
  final Future<void> Function() initialize;
  final RemoteConfigService config;
  Future<void>? _appCheck;

  @override
  Future<String> suggest(
    String keywords,
    Map<String, List<String>> choices,
  ) async {
    try {
      await initialize();
      await config.fetchAndActivate();
      if (config.getString('ai_filters_enabled') != 'true') {
        throw const AppException(
          code: 'unavailable',
          message: 'AI suggestions are turned off. You can still choose filters manually.',
        );
      }
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        throw const AppException(
          code: 'unavailable',
          message: 'AI suggestions are available on Android.',
        );
      }
      _appCheck ??= FirebaseAppCheck.instance
          .activate(
            providerAndroid: kDebugMode
                ? const AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
          )
          .catchError((Object error) {
            _appCheck = null;
            throw error;
          });
      await _appCheck;
      final token = await FirebaseAppCheck.instance.getToken();
      if (token == null || token.isEmpty) {
        throw const AppException(
          code: 'unavailable',
          message: 'App verification is unavailable. Use manual filters or try again.',
        );
      }
      final modelName = config.getString('ai_filters_model');
      final prompt = config.getString('ai_filters_prompt');
      if (modelName.isEmpty || prompt.isEmpty) {
        throw const AppException(
          code: 'unavailable',
          message: 'AI needs its model and prompt configured. Manual filters are available.',
        );
      }
      final model = FirebaseAI.googleAI().generativeModel(
        model: modelName,
        systemInstruction: Content.system(prompt),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              for (final entry in choices.entries)
                entry.key: Schema.enumString(enumValues: entry.value),
            },
          ),
        ),
      );
      final response = await model
          .generateContent([
            Content.text(jsonEncode({'keywords': keywords})),
          ])
          .timeout(const Duration(seconds: 25));
      return response.text ?? '';
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        code: 'deadline-exceeded',
        message: 'AI took too long. Try again or choose filters manually.',
      );
    } catch (_) {
      throw const AppException(
        code: 'unavailable',
        message: 'AI is unavailable. Check your connection, quota and App Check setup, or use manual filters.',
      );
    }
  }
}
