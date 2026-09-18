# Folder Structure

## What is the rule?
Code is divided into pp/ (bootstrap), core/ (shared infrastructure), and eatures/ (feature-specific code).

## Why does it exist?
To prevent a monolithic codebase and enforce boundary separation between independent features.

## Where does it apply?
All new features must reside in lib/features/<feature_name>/.

## Example
``
lib/
├── app/
├── core/
└── features/
    └── receipt_capture/
``
