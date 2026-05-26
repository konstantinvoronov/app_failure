import 'app_failure.dart';

/// Represents the result of an operation that can either succeed with data
/// or fail with an [AppFailure].
///
/// `AppResult` is useful when a function has an expected failure path and that
/// failure should be handled explicitly instead of being thrown as an exception.
///
/// Example:
///
/// ```dart
/// final AppResult<User> result = await repository.loadUser();
///
/// result.fold(
///   (user) {
///     print(user.name);
///   },
///   (failure) {
///     print(failure.message);
///   },
/// );
/// ```
sealed class AppResult<T> {
  const AppResult();

  /// Creates a successful result containing [data].
  ///
  /// If `T` is nullable, [data] may be `null`.
  const factory AppResult.success(T data) = AppSuccess<T>;

  /// Creates a failed result containing an [AppFailure].
  ///
  /// The [failure] describes why the operation failed.
  const factory AppResult.failure(AppFailure failure) = AppFailureResult<T>;

  /// Returns `true` when this result is [AppSuccess].
  bool get isSuccess => this is AppSuccess<T>;

  /// Returns `true` when this result is [AppFailureResult].
  bool get isFailure => this is AppFailureResult<T>;

  /// Returns the success data, or `null` when this result is a failure.
  ///
  /// Be careful when `T` itself is nullable. In that case, `null` may mean either:
  ///
  /// - this result is a failure
  /// - this result is a successful result with `null` data
  T? get dataOrNull {
    return switch (this) {
      AppSuccess<T>(:final data) => data,
      AppFailureResult<T>() => null,
    };
  }

  /// Returns the [AppFailure], or `null` when this result is successful.
  AppFailure? get failureOrNull {
    return switch (this) {
      AppSuccess<T>() => null,
      AppFailureResult<T>(:final failure) => failure,
    };
  }

  /// Handles both possible outcomes and returns a single value.
  ///
  /// The first callback handles successful data.
  /// The second callback handles failure.
  ///
  /// Example:
  ///
  /// ```dart
  /// final value = result.fold(
  ///   (data) => data,
  ///   (failure) => fallbackValue,
  /// );
  /// ```
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(AppFailure failure) onFailure,
  ) {
    return switch (this) {
      AppSuccess<T>(:final data) => onSuccess(data),
      AppFailureResult<T>(:final failure) => onFailure(failure),
    };
  }
}

/// A successful [AppResult].
final class AppSuccess<T> extends AppResult<T> {
  /// The value produced by a successful operation.
  final T data;

  const AppSuccess(this.data);
}

/// A failed [AppResult].
final class AppFailureResult<T> extends AppResult<T> {
  /// The failure produced by a failed operation.
  final AppFailure failure;

  const AppFailureResult(this.failure);
}
