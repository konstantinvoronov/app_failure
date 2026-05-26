# AI Instructions for using `app_failure`

## Core principle
- Exceptions are an internal implementation detail. Failures are the external contract.
The package helps you model failures as explicit data, preserve context across clean architecture layers, and declare how failures should be processed instead of relying on hidden exception propagation.

## Base principles

Do not create a new failure type for every possible error.

`app_failure` is based on layered failure chains and processing intent.

The goal is to preserve context as a failure moves through the app. 
The goal is not to build an exhaustive taxonomy of thousands of error classes.

## ValidationFailure rule

Use `ValidationFailure` when data does not match the contract expected by the current layer.

A validation failure does not have to happen only inside a UI form validator.

It may also happen when:

- an API DTO cannot be converted into an application model
- a required field is missing
- a value has an unexpected format
- a value is outside the allowed domain
- stored/cache data cannot be trusted
- external data does not satisfy the app model contract

Example:

```text
A mapper receives API data.
The mapper cannot convert it into the expected model.
This is a ValidationFailure because the received data violates the model contract.
```

###Failure wrapping rule

When a failure crosses a layer boundary, wrap it with the failure type of the current layer.

Do not replace the previous failure.

Preserve it as cause.

Example:

-> ValidationFailure
(failure in mapper lead to) -> ApiFailure
(api returns it's own ApiFailure with cause ValidationFailure) -> RepositoryFailure
(Repository returns it's own RepositoryFailure with ApiFailure as cause with cause ValidationFailure) -> ControllerFailure
(Controller returns to ui its own ControllerFailure with RepositoryFailure with ApiFailure as cause with cause ValidationFailure)

Each layer adds context.

The original cause remains available for logs, reports, and diagnostics.


## Processing intent rule

Each next stop may update processingIntent due to its logic
and declare how the failure should be processed but next level may again overrite it

visible or silent
retryable or not retryable
user-actionable or not
feature-fatal or app-fatal
reportable or not
clear state or keep state

The UI or global processor should use last processing intent to decide behavior.

The cause chain should be used for messages, logs, and diagnostics.

## Local throw rule

Inside a single function, throw may be used only as a local early-exit tool to keep the happy path linear.

The thrown failure must be caught inside the same function and returned as failure data.
Never let internal exceptions become the cross-layer contract.

only unhandled exceptions or appFatal failure should be wrapped to correct AppFailure and than throwen to a global level processor.

###Correct idea:

inside function: throw AppFailure for local early exit
function boundary: return AppResult.failure(...)

## Do not silently ignore failures

When calling a failure-returning function, always choose one of:

handle it locally
wrap it with current layer context
return it
locally abort and catch into a returned failure

Never ignore a failure result.
Never return fallback data without recording the failure unless the project explicitly declares this as a silent processing intent.

only unhandled exceptions or appFatal failure should throw to a global level processor.

## Message rule

User-facing messages are resolved from the failure chain according to the project message policy. Desicions
is configured if user asks to ai agent to configure ui message policy and agent should use ui_message_configuration policy

Default latest outermost message wins. 

The project may use:

latest message wins
root cause message wins
priority-based message resolution
custom resolver

When unsure, preserve messages and context in the chain instead of overwriting them.

## Loggin rule
Layer that does not generates its own error must not return AppResult and obliged to execute error AppFailureConsumer.

## AppFailureConsu  mer 

Must be called in all that call function that has calles that return AppResult inside and doesnt return AppResult itself.
AppFailureConsumer process failure must decide on logic, logit , and does final logic on failaure or rethrow it to global  
AppFailureConsumer with inside unhandled throw.


## Technology adapter rule

The core package should not depend on Dio, Firebase, SQLite, platform channels, or other external technologies.

Technology-specific packages should map external exceptions into core failures.

Example:

DioException -> AdapterFailure / ApiFailure
FirebaseException -> AdapterFailure / DataFailure
SqliteException -> DataFailure

Do not add external package types directly to the core AppFailure model.

