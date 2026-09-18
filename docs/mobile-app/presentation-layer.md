# Presentation Layer

## What is the rule?
Contains Widgets, Pages, and Cubits. Widgets must be dumb (only rendering state and dispatching actions to Cubit).

## Why does it exist?
To keep the UI maintainable, testable, and separate from complex business operations.

## Where does it apply?
Inside lib/features/<feature>/presentation/.

## Example
A UI button triggers context.read<AuthCubit>().login(...), it does NOT call Supabase directly.
