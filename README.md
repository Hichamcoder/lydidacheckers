# LYDIDA Checkers

Offline-first 8×8 checkers with two distinct rulesets, built in Godot 4.7.2.

## Included in this milestone

- English checkers and Spanish 64-square draughts.
- Compulsory captures, multi-capture paths and promotion.
- Spanish flying kings and maximum-capture selection.
- Human versus AI play using bounded alpha-beta search.
- Touch-focused board UI, undo and restart.
- Automated smoke tests for rule differences and AI move legality.
- GitHub Actions workflow that runs Godot tests and attempts an Android API 36 debug APK export.

## Build and run

Open the repository in Godot 4.7.2 and run the main scene. For Android, install Godot's matching export templates, JDK 17 and the Android SDK components documented in docs/ANDROID_RELEASE.md.

## Release status

A successful debug APK export is not a production Play Store release. Release requires device testing, a separately managed signing keystore, a signed AAB, store assets, privacy/support information and Play Console internal testing.

No Firebase credentials, keystore, or Play Console credentials are stored here. The game runs locally and does not need an account for this milestone. The AI is a search-based opponent; it is not claimed to be unbeatable.
