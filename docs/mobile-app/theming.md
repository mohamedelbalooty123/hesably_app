# Theming

## What is the rule?
Use a semantic token-based theme. The primary color is #0A7A3D. Do not hardcode colors in widgets. Define roles like primary, surface, error inside ThemeData.

## Why does it exist?
To allow consistent visual application that matches the new Stitch design without manual duplication.

## Where does it apply?
lib/app/theme/ and all widget build methods.

## Example
color: Theme.of(context).colorScheme.primary instead of color: Color(0xFF0A7A3D).
