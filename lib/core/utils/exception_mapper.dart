import 'dart:async';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';

abstract final class ExceptionMapper {
  static AppException map(Object error) => switch (error) {
    AppException() => error,
    TimeoutException() => const AppException(
      code: 'timeout',
      message: AppStrings.timeoutError,
    ),
    _ => const AppException(
      code: 'unexpected',
      message: AppStrings.unexpectedError,
    ),
  };
}
