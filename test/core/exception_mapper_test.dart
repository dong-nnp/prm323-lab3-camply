import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/constants/app_strings.dart';
import 'package:prm393_lab03/core/utils/exception_mapper.dart';

void main() {
  test('unexpected errors do not expose implementation details', () {
    final error = ExceptionMapper.map(
      StateError('internal diagnostic details'),
    );
    expect(error.code, 'unexpected');
    expect(error.message, AppStrings.unexpectedError);
    expect(error.message, isNot(contains('internal diagnostic details')));
  });

  test('timeout gives an actionable message', () {
    final error = ExceptionMapper.map(TimeoutException('request timeout'));
    expect(error.code, 'timeout');
    expect(error.message, AppStrings.timeoutError);
  });
}
