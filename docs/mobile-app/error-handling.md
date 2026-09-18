# Error Handling

## What is the rule?
Catch exceptions in the Data layer, map them to Failure objects (e.g., NetworkFailure, ServerFailure), and return them to the Domain layer using Either<Failure, Success> (from pdart or dartz).

## Why does it exist?
To prevent unhandled exceptions from crashing the app and to provide user-friendly UI error states.

## Where does it apply?
Data layer (try-catch) and Domain/Presentation layers (Failure mapping).

## Example
`dart
return Left(ServerFailure('Connection timeout'));
`
"@
    "testing-strategy.md" = @"
# Testing Strategy

## What is the rule?
Write Unit Tests for Use Cases, Cubits, and Data Sources. Write Widget Tests for reusable UI components. Prioritize core flows: Auth, Capture, Sync, Confirmation.

## Why does it exist?
To prevent regressions in critical business paths (e.g., AI confirmation boundary).

## Where does it apply?
	est/ directory, mirroring the structure of lib/.

## Example
	est/features/auth/presentation/cubit/auth_cubit_test.dart
"@
    "environment-config.md" = @"
# Environment Configuration

## What is the rule?
Use compile-time variables (--dart-define) or env files for API keys and URLs. Never commit secrets to Git. Gemini API keys must NOT be present in the Flutter app.

## Why does it exist?
To secure production environments and allow easy switching between dev and prod Supabase instances.

## Where does it apply?
lib/app/config/ and CI/CD pipelines.

## Example
Supabase.initialize(url: String.fromEnvironment('SUPABASE_URL'), ...)
"@
    "security.md" = @"
# Security

## What is the rule?
Client-side validation is for UX only. True security relies on Supabase Row Level Security (RLS). Tokens are managed automatically by supabase_flutter. Do not log sensitive user data.

## Why does it exist?
To prevent data leaks and unauthorized access to other businesses' records.

## Where does it apply?
Supabase configuration, local storage security, and logging.

## Example
Do not print auth tokens or full receipt images to console in production.
