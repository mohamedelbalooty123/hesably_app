# Supabase Integration

## What is the rule?
All Supabase calls must be isolated inside Data Sources. Never call Supabase.instance.client from a UI widget or domain entity.

## Why does it exist?
To enforce the Data Layer boundary and allow mocking during tests.

## Where does it apply?
lib/features/<feature>/data/datasources/ and lib/core/network/.

## Example
`dart
class AuthRemoteDataSource {
  final SupabaseClient client;
  // ...
}
`
"@
    "storage.md" = @"
# Storage Architecture

## What is the rule?
Receipt images are stored in a private Supabase bucket scoped to the user's business ID via RLS. Locally, use path_provider for temporary capture storage before upload.

## Why does it exist?
To secure user data while allowing reliable offline capture and background upload.

## Where does it apply?
lib/features/receipt_capture/ and core storage services.

## Example
Path format: {business_id}/{transaction_id}/receipt.jpg.
