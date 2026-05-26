# app_failure


`app_failure` is a lightweight Dart/Flutter library for structured failure handling.

Instead of relying on scattered exceptions, nulls, flags, and hidden propagation, the library helps structure failures as readable, composable data objects that can move safely across application layers.

`app_failure` follows a declarative approach: failure-capable operations should make both success and failure paths visible in code. 

It also provides simple, ready-to-use patterns for chaining failures, stacking layer context, resolving messages, and converting failure chains into readable logs.

The package is built around two core types:

```dart
AppFailure
AppResult<T>
```

## Basic example

```dart
Future<AppResult<User>> loadUser() async {
  try {
    final response = await api.loadUser();

    return AppResult.success(response);
  } catch (e, st) {
    return AppResult.failure(
      AppFailure(
        error: e,
        stackTrace: st,
        logMessage: 'Failed to load user',
        uiMessage: 'Could not load user.',
      ),
    );
  }
}
```

## Core idea: failure chains

`app_failure` is not just another `Result` type.

The main idea is that failures should preserve the full story as they move through application layers.

A low-level failure explains what technically went wrong.  
Each upper layer can wrap it and add its own context without losing the original cause.

```text
first failure = technical root cause
last failure  = user/application context
full chain    = complete failure report
```

For example, an API failure can be wrapped by the repository layer:

```dart
return AppResult.failure(
  RepositoryFailure(
    logMessage: 'User repository failed',
    cause: apiFailure,
    stackTrace: st,
  ),
);
```

The `apiFailure` remains available as the cause.  
The repository does not replace the original failure — it adds context.

A full chain may look like this:

```text
HttpFailure
  -> ApiFailure
    -> RepositoryFailure
      -> ControllerFailure
```

This allows the app to keep both sides of the story:

- the original technical cause for debugging
- the final application context for UI, logging, reporting, and support


In asynchronous apps, failures often do not happen in a simple straight line.

Several operations may run at the same time:

- multiple API requests
- retries
- background refreshes
- cached data resolution
- parallel repository calls
- UI actions started before previous actions finish

With a regular single failure report, the final error often loses the path that produced it.

The key idea is:

> In concurrency, the problem is not only “what failed”, but **which async path produced this failure**.

That is where chains are stronger than a single failure object.


## Principles

- Every error inside the app is represented as **AppFailure**.

- A **failure** is not the same thing as an **error**. A failure means that the system could not complete the intended operation. An `Error` or `Exception` is one possible source of a failure, but failures can also come from validation rules, denied permissions, cancelled operations, unavailable data, failed business conditions, or rejected API responses. **Any Error is a Failure.**

- **Failures often originate in deeper layers and travel outward as a chain.** Each layer can add its own context without replacing the original cause.

- **In an app, the UI is usually the final layer that reacts to a failure.** It decides how the failure should affect the user experience: show a message, hide a widget, block a feature, ask for permission, retry an operation, or report a critical issue.


## Basics of `app_failure`

- **All logical failures and caught exceptions are represented as `AppFailure`.**
  
- **`AppFailure`** captures the cause, severity, user-facing message, log message, and stack trace.


- **Failure-capable functions return `AppResult<T>` instead of throwing.**  
  Exceptions are caught inside the function and converted into an `AppFailure`.

- **Each layer should wrap a lower-level `AppFailure` in its own `AppFailure` and create a chain.**  
  The lower-level failure is preserved as the `cause`, so the full failure chain is not lost.


> Unknown exceptions are also wrapped into `AppFailure`.

  ```dart
  try {
    final result = await someOperation();

    return AppResult.success(result);
  } catch (e, st) {
    return AppResult.failure(
      AppFailure.unhandledException(e, st),
    );
  }
```

## Pattern rule

> Errors are **not thrown directly** from inner layers to UI.

### ❌ Poor error flow
```dart
  void someMethod(){
    try{
      innerMethod();
    }catch(e,st){
      log(e.toString());
    }
  }

  void innerMethod(){
    throw(Exception('failed to read'));
  }
```

> Instead, use `AppResult` and let the outermost layer fold and react.  

### ✅ AppResult return pattern

```dart
    void someMethod() {
      final result = innerMethod();
    
      result.fold(
        onSuccess: (_) {
          // Operation completed successfully.
        },
        onFailure: (failure) {
          log(failure.toString());
        },
      );
    }
    
    AppResult<void> innerMethod() {
      return AppResult.failure(
        AppFailure(
          logMessage: 'innerMethod failed',
          stackTrace: StackTrace.current,
        ),
      );
    }
```

> Do not log every failure. Only a function that doesn’t throw and neither returns `AppResult` should consume the failure, log it, and react.

## Inside one function, exceptions may be used as a local early-exit mechanism to keep the happy path linear.

### ✅ Happy path pattern

```dart
    Future<AppResult<int>> someFunction() async {
      try {
        (await firstAction()).fold(
          (v) {},
          (f) => throw f,
        );

        final int result = (await secondAction()).fold(
          (v) => v,
          (f) => throw f,
        );

        
        return AppResult.success(result);
      } catch (e, st) {
        return AppResult.failure(
          AppFailure(
            error: e,
            stackTrace: st,
            logMessage: 'someFunction failed',
          ),
        );
      }
    }
```

## Use the appropriate layer failure type

`AppFailure` represents one failure in the failure chain.

Each failure should be represented by the most specific `AppFailure` subtype available for the layer where it happened.

Every failure type is designed to carry enough context for the upper layer to understand what failed and react properly.

- `ValidationFailure` — used when validation fails. It may contain a user-facing validation message, or detailed data mismatch information when the failure comes from mapping/parsing.
- `HttpFailure` — used when an HTTP request fails. It may carry request data, response data, status code, error kind, and the original error.
- `ApiFailure` — used when API-level processing fails.
- `RepositoryFailure` — used when a repository or use case operation fails.
- `ControllerFailure` — used when a controller or feature flow fails.

A failure chain may contain several failure types.

For example, a low-level `HttpFailure` can be wrapped into an `ApiFailure`, then later into a `RepositoryFailure` or `ControllerFailure`.

### ✅ Pick the correct AppFailure subclass

```dart
    import 'package:dio_app_failure_adapter/dio_app_failure_adapter.dart';
    
    Future<AppResult<dynamic>> loadUsers() async {
      try {
        final response = await dio.get('/users');
    
        if (response.statusCode != 200) {
          final httpFailure = HttpFailure(
            logMessage: 'Unexpected HTTP response',
            request: response.requestOptions.toHttpFailureRequestModel(),
            response: response.toHttpFailureResponseModel(),
            failureKind: HttpFailureKind.badResponse,
            debugDescription: response.toString(),
            stackTrace: StackTrace.current,
          );
    
          return AppResult.failure(
            ApiFailure(
              logMessage: 'Users API returned unexpected response',
              cause: httpFailure,
              stackTrace: StackTrace.current,
            ),
          );
        }
    
        return AppResult.success(response.data);
      } on DioException catch (e, st) {
        final httpFailure = e.toHttpFailure(
          stackTrace: st,
          logMessage: 'Dio failed',
        );
    
        return AppResult.failure(
          ApiFailure(
            logMessage: 'Users API request failed',
            cause: httpFailure,
            error: e,
            stackTrace: st,
          ),
        );
      }
    }
```

## Log the entire failure chain as one piece

Do not log every failure at every layer.

Log a failure only at the place where it is finally consumed: when you do **not** rethrow it and do **not** return it as `AppResult`.

At that point, wrap the caught failure with the current layer context and log the final `AppFailure`.

### ✅ Logging pattern — log only when consuming the failure

```dart
Future<void> onSomething() async {
  try {
    final int result = (await someFunction()).fold(
          (resultData) => resultData,
          (failure) => throw failure,
    );

    // Continue with result.
  } catch (e, st) {
    final failure = AppFailure(
      error: e,
      stackTrace: st,
      logMessage: 'onSomething failed',
    );

    // Logs the entire failure chain with all collected context in one line.    
    // This is a complete failure report, not just a single log record.
    log('$failure');
  }
}
```

## Emit failure to the UI and let the UI react to it

Use a state with an explicit `failure` field and a `copyWith`.

### ✅ Consume pattern — bring the entire AppFailure chain to the UI

```dart
    final class MyState {
      final AppFailure? failure;
    
      const MyState({
        this.failure,
      });
    
      MyState copyWith({
        AppFailure? failure,
        bool clearFailure = false,
      }) {
        return MyState(
          failure: clearFailure ? null : failure ?? this.failure,
        );
      }
    }
```

> Then catch the failure at the controller / Bloc / Cubit level, wrap it with feature context, emit it to the UI, and log the full failure chain once.

```dart
    Future<void> blocEventProcessor() async {
      try {
        final int result = (await someFunction()).fold(
              (resultData) => resultData,
              (failure) => throw failure,
        );
    
        // Success processing.
      } catch (e, st) {
        final failure = AppFailure(
          error: e,
          stackTrace: st,
          logMessage: 'blocEventProcessor failed',
          uiMessage: 'Some user-facing message',
        );
    
        emit(state.copyWith(failure: failure));
    
        log('$failure');
      }
    }
```
> In the UI:

```dart
    /// Used in Bloc listeners to ensure consistent UI-level failure handling.
    Widget uiFailureHandler({
      required AppFailure failure,
    }) {
      if (failure.fatalLevel == FatalLevel.silent) {
        return const SizedBox.shrink();
      }
    
      if (failure.isAppFatal) {
        return AppFatalFailureWidget(failure: failure);
      }
    
      if (failure.isFeatureFatal) {
        return FeatureFatalFailureWidget(failure: failure);
      }
    
      return switch (failure) {
        ValidationFailure() => ValidationFailureWidget(failure: failure),
        HttpFailure() => HttpFailureWidget(failure: failure),
        ApiFailure() => ApiFailureWidget(failure: failure),
        RepositoryFailure() => RepositoryFailureWidget(failure: failure),
        ControllerFailure() => ControllerFailureWidget(failure: failure),
        _ => UnknownFailureWidget(failure: failure),
      };
    }
```
  
## Why use app_failure?

As Flutter applications grow, error handling often becomes inconsistent:

- some features throw exceptions
- others return nullable values
- some layers show snackbars directly
- network and infrastructure errors leak into UI
- failures lose context between layers
- retry, fatality, and reporting behavior become scattered
- different developers handle the same problem differently

Over time this creates hidden behavior and unpredictable failure flows.

`app_failure` introduces a declarative failure model where:

- failures are explicit
- every layer declares how failures should be processed
- context is preserved through layered cause chains
- failures are returned as data across boundaries
- processing behavior becomes deterministic and centralized

The package helps teams standardize:

- retry behavior
- visibility rules
- fatality handling
- reporting decisions
- user-facing messages
- failure propagation between layers

without tightly coupling application logic to exception types or infrastructure details.

---

## 📦 Installation

```yaml
dependencies:
  app_failure: ^1.0.1
```

Then:

```dart
import 'package:stateful_data/app_failure.dart';
```

---

## 📘 Documentation & Sources

- **Repository:** https://github.com/konstantinvoronov/app_failure
- **Issue Tracker:** https://github.com/konstantinvoronov/app_failure/issues
- **Homepage:** https://github.com/konstantinvoronov/app_failure

More docs and layer-specific examples (repositories, controllers, UI) will be added over time.

---

## 🧑‍💻 Author

**Konstantin Voronov**  
Software engineer focused on declarative architecture patterns for Flutter and Dart.

Email: `me@konstantinvoronov.com`

---

## ⭐ Support

If you find this package useful, please consider giving it a ⭐ on GitHub.


