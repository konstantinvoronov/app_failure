import 'package:app_failure/app_failure.dart';
import 'package:test/test.dart';

void main() {
  group('AppFailure', () {
    test('moves AppFailure passed as error into cause', () {
      final httpFailure = AppFailure.httpFailure(
        logMessage: 'HTTP request failed',
        request: HttpFailureRequestModel(
          method: 'GET',
          uri: Uri.parse('https://example.com/users'),
        ),
        failureKind: HttpFailureKind.unknown,
        stackTrace: StackTrace.current,
        fatalLevel: FatalLevel.nonFatal,
      );

      final apiFailure = AppFailure.apiFailure(
        logMessage: 'API processing failed',
        cause: httpFailure,
        stackTrace: StackTrace.current,
      );

      expect(apiFailure.cause, same(httpFailure));
      expect(apiFailure.error, isNull);
    });

    test('keeps raw exception as error', () {
      final exception = Exception('Something failed');

      final failure = AppFailure.apiFailure(
        logMessage: 'API processing failed',
        error: exception,
        stackTrace: StackTrace.current,
      );

      expect(failure.cause, isNull);
      expect(failure.error, same(exception));
    });

    test('prints cause chain in diagnostic string', () {
      final validationFailure = AppFailure.validationFailure(
        'Invalid API data',
      );

      final apiFailure = AppFailure.apiFailure(
        logMessage: 'API response could not be processed',
        error: validationFailure,
        stackTrace: StackTrace.current,
      );

      final repositoryFailure = AppFailure.repositoryFailure(
        logMessage: 'Repository failed to load data',
        cause: apiFailure,
        stackTrace: StackTrace.current,
      );

      final text = repositoryFailure.toString();

      expect(text, contains('RepositoryFailure'));
      expect(text, contains('ApiFailure'));
      expect(text, contains('ValidationFailure'));
      expect(text, contains('Repository failed to load data'));
      expect(text, contains('API response could not be processed'));
    });
  });
}
