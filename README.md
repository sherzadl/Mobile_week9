# Lecture 7 — MP Practice (Flutter)

This project implements **all tasks** from the PDF:
- GET posts (JSONPlaceholder), print first title, list titles
- Loading spinner, error + Retry
- Details screen (title & body) with back
- POST to `https://reqres.in/api/posts` with SnackBar on success
- Currency screen using CBU.uz API (date + code → list rates)

## Run locally

```bash
# 1) Generate platform folders (Android/iOS/web) if missing
flutter create .

# 2) Get packages
flutter pub get

# 3) Run (choose any device)
flutter run
# For web specifically:
flutter run -d chrome
```

> **Android Internet permission** is automatically handled by Flutter's default templates. No extra native code is required for this app.

## Notes for Web (CBU CORS)

CBU.uz blocks browser cross-origin requests. When running on the web, the app automatically proxies CBU requests through `https://api.allorigins.win/raw?url=...` so it works in Chrome. On mobile/desktop, it calls CBU directly.

## Repo structure

```
mp_practice_flutter/
  lib/
    main.dart
  pubspec.yaml
  README.md
```
