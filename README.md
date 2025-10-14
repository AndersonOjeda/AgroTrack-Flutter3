# example_ia

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Supabase Setup

- Create a project in Supabase and copy your `Project URL` and `anon public key`.
- Duplicate `.env.example` to `.env` and set:
  - `SUPABASE_URL` with your project URL.
  - `SUPABASE_ANON_KEY` with your anon key.
- Ensure `.env` is listed under `assets` in `pubspec.yaml`.
- Run `flutter pub get` and start the app.

### Notes
- Android requires Internet permission; it's already declared in `AndroidManifest.xml`.
- For web, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` via build-time env or serve `.env` securely.
