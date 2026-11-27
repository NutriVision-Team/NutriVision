# Android Google sign-in: signing fingerprints

`android/app/google-services.json` was refreshed from the Firebase project  and now contains the Android OAuth client.
The Firebase Android app com.example.sufradepi currently has this registered SHA-1: `<your SHA-1>` (plus a SHA-256).
Google sign-in on a device works only for builds signed with a registered key.

Before a release build: add the RELEASE keystore SHA-1 and SHA-256 in Firebase console > Project settings > Your apps > com.example.sufradepi > Add fingerprint,
then re-download google-services.json. Get them with:
`keytool -list -v -keystore <release.jks> -alias <alias>`
If your own debug keystore differs from the registered SHA-1, add that one too.
