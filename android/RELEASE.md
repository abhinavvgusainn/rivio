# Android release builds

The Android application ID is `com.rivio.app`. The version name and code
come from `pubspec.yaml` (`1.0.0+1` means version name `1.0.0`, code `1`).

Rivio stores study data on-device and has no app backend. Ads and consent
requests need a network connection; the rest of the app does not.

Release builds never use the Android debug signing key. To sign a Play upload,
create or use the app's upload keystore, store it in a secure location, and set
these environment variables on the build machine or CI runner:

- `RIVIO_RELEASE_STORE_FILE`
- `RIVIO_RELEASE_STORE_PASSWORD`
- `RIVIO_RELEASE_KEY_ALIAS`
- `RIVIO_RELEASE_KEY_PASSWORD`

Set all four variables together. With them configured, build the Play artifact
with `flutter build appbundle --release`. Without them, Gradle can build an
unsigned release artifact, but it cannot be uploaded to Google Play. Never
commit the keystore or its passwords; back up the upload key securely.
