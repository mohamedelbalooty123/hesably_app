# Domain Layer

## What is the rule?
The domain layer contains pure Dart logic (Entities, Use Cases, Repository Interfaces). It must not depend on Flutter or external libraries (like Supabase).

## Why does it exist?
To isolate core business rules from UI and framework changes.

## Where does it apply?
Inside lib/features/<feature>/domain/.

## Example
ConfirmTransactionUseCase takes input from presentation and invokes the TransactionRepository.
