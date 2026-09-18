# Authentication

## What is the rule?
Use Supabase Phone Auth with Twilio. Store sessions persistently. Use GoRouter redirects to protect authenticated routes.

## Why does it exist?
To meet the MVP requirement of simple phone-based login for Egyptian business owners.

## Where does it apply?
lib/features/auth/ and lib/app/router/ guards.

## Example
If uthState == unauthenticated, router redirects to /login.
