part of '../app_failure.dart';

/// Represents a validation failure.
///
/// [ValidationFailure] can be used in two different situations:
///
/// 1. User/input validation.
///
///    Use the default constructor when validation fails because of user input
///    or domain input rules.
///
///    Example:
///
///    ```dart
///    return AppResult.failure(
///      ValidationFailure('Email is required'),
///    );
///    ```
///
///    This form is intentionally short because UI/input validation usually
///    needs only a user-facing message.
///
/// 2. Internal data-processing validation.
///
///    Use [ValidationFailure.processing] when validation fails while processing
///    data inside the app, for example inside a mapper, parser, DTO converter,
///    API response processor, or domain object factory.
///
///    Example:
///
///    ```dart
///    return AppResult.failure(
///      ValidationFailure.processing(
///        logMessage: 'Invalid user payload: id must be String',
///        error: error,
///        stackTrace: stackTrace,
///      ),
///    );
///    ```
///
///    This form keeps debugging information, the original error, stack trace,
///    and optional cause chain.
///
/// Examples:
///
/// - invalid email
/// - missing required field
/// - wrong field type
/// - server field validation
/// - invalid API response shape
/// - mapper/parsing/type-mismatch failure
final class ValidationFailure extends AppFailure {
  /// Creates a simple validation failure for user/input validation.
  ///
  /// Use this constructor when the failure can be shown directly to the user
  /// and no additional debugging context is required.
  ValidationFailure(String message)
      : super._(
    uiMessage: message,
    logMessage: '',
  );

  /// Creates a validation failure with full processing/debug context.
  ///
  /// Use this constructor when validation fails inside internal app processing,
  /// such as mapping, parsing, DTO conversion, API response processing, or
  /// domain object creation.
  ///
  /// This constructor is useful when the validation failure is not just a UI
  /// input problem, but part of a larger failure chain.
  ValidationFailure.processing({
    String? uiMessage,
    required String logMessage,
    AppFailure? cause,
    Object? error,
    StackTrace? stackTrace,
    FatalLevel fatalLevel = FatalLevel.nonFatal,
    bool? showReportBugDialog,
  }) : super._(
    uiMessage: uiMessage,
    logMessage: logMessage,
    cause: cause,
    error: error,
    stackTrace: stackTrace,
    fatalLevel: fatalLevel,
    showReportBugDialog: showReportBugDialog,
  );
}