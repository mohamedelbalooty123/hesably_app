# Localization

## What is the rule?
App is Arabic-first and RTL-first. Use lutter_localizations and .arb files for string definitions. Never hardcode user-facing strings in UI files.

## Why does it exist?
The target market is Egypt, requiring native Arabic language support and numeric formatting (Latin digits in Arabic locale context).

## Where does it apply?
Across all Presentation layer widgets.

## Example
Use AppLocalizations.of(context)!.loginTitle instead of 'تسجيل الدخول'.
