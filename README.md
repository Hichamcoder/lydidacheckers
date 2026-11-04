# LYDIDA Checkers

An offline-first checkers game project built with Godot 4.7.2.

## Project scope

- English checkers and Spanish draughts rule sets.
- Human-versus-AI play with a bounded alpha-beta search engine.
- Touch-first Android interface.
- Automated rules/AI tests and Android debug APK build pipeline.

## Build

1. Install Godot 4.7.2 and its matching export templates.
2. Open this repository in Godot.
3. Run the project from the editor.
4. For Android, install JDK 17 and the Android SDK components specified in `docs/ANDROID_RELEASE.md`.
5. Use the `Android Debug` export preset or the GitHub Actions workflow.

## Release status

This repository is the source of truth for development. A debug APK is for testing only. Production release requires physical-device validation, an owner-controlled release keystore, a signed Android App Bundle, store assets, privacy/support information and Play Console testing. Do not commit keystores or passwords.

Firebase, online accounts and multiplayer are not configured in the current offline-first milestone. The AI is not claimed to be unbeatable; competitive strength must be measured through independent matches and benchmarks.
