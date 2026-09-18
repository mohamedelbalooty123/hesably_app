# System Architecture

## What is the rule?
The application uses a Feature-First Clean Architecture structure with BLoC/Cubit for state management. Layers must remain isolated: Presentation -> Domain -> Data.

## Why does it exist?
To separate business logic from UI, allowing independent scaling, testing, and AI-assisted implementation.

## Where does it apply?
Across the entire lib/ directory structure.

## Example
lib/features/transactions/ contains data/, domain/, and presentation/ subfolders. Presentation logic cannot directly call the Supabase database.
