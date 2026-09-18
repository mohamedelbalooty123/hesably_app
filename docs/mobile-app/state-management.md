# State Management

## What is the rule?
Use lutter_bloc (specifically Cubit for most cases, Bloc for complex event streams). State classes must be immutable (using equatable or reezed).

## Why does it exist?
To provide predictable, easily testable state transitions and separate UI from business logic.

## Where does it apply?
All presentation-layer components requiring state that extends beyond trivial ephemeral UI state.

## Example
`dart
class TransactionCubit extends Cubit<TransactionState> {
  // Uses immutable state classes
  void loadTransactions() async { ... }
}
`
"@
    "routing.md" = @"
# Routing

## What is the rule?
Use go_router for declarative routing. 

## Why does it exist?
To support deep linking, nested navigation, and centralized route guards (like authentication checks).

## Where does it apply?
All navigation must go through the centralized router in lib/app/router/.

## Example
`dart
context.go('/transactions/details');
`
"@
    "dependency-injection.md" = @"
# Dependency Injection

## What is the rule?
Use get_it and injectable for managing dependencies. Keep registration in a central configuration layer.

## Why does it exist?
To decouple implementations from their abstractions, making unit testing easier by allowing mock injections.

## Where does it apply?
Any class needing external services, repositories, or use cases.

## Example
`dart
final repo = getIt<TransactionRepository>();
`
"@
    "data-layer.md" = @"
# Data Layer

## What is the rule?
The data layer consists of Data Sources (API/Local DB) and Repositories (implementing Domain interfaces). It must map external models to domain entities.

## Why does it exist?
To abstract the origin of data (Supabase vs local storage) from the domain logic.

## Where does it apply?
Inside lib/features/<feature>/data/.

## Example
TransactionRemoteDataSource interacts with Supabase, while TransactionRepositoryImpl combines remote data with local cache if needed.
