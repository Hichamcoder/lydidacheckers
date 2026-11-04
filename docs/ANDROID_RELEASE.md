# Android release checklist

## Current CI debug target

- Engine: Godot 4.7.2 stable.
- Android target API: 36.
- Minimum API: 24.
- ABI: arm64-v8a.
- Package id: com.lydida.checkers.
- CI output: debug APK artifact, not a Play Store release.

Google Play's policy states that new apps and updates must target Android 16 / API 36 or higher from August 31, 2026:
https://support.google.com/googleplay/android-developer/answer/11926878

Godot Android export documentation:
https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html

## Production release gates

1. Run CI successfully and download the debug APK artifact.
2. Install and test on physical Android devices.
3. Validate both rule sets against independent test positions and game records.
4. Benchmark AI time and memory usage on low-, mid- and high-range devices.
5. Create app icon, screenshots, privacy policy and support contact.
6. Generate a release keystore and back it up securely. Never commit the keystore or passwords.
7. Add release signing values as GitHub Actions secrets and implement a separate signed AAB workflow.
8. Test the AAB through Play Console internal testing before submission.

No Firebase project, credentials, release keystore or Play Console access has been configured in this project.
