import '../core/errors/app_exception.dart';

/// Presentation state shared by ViewModels, without Flutter or SDK types.
sealed class AppState<T> {
  const AppState();
}

final class AppLoading<T> extends AppState<T> {
  const AppLoading();
}

final class AppEmpty<T> extends AppState<T> {
  const AppEmpty(this.message);

  final String message;
}

final class AppError<T> extends AppState<T> {
  const AppError(this.error);

  final AppException error;
}

final class AppData<T> extends AppState<T> {
  const AppData(this.value);

  final T value;
}
