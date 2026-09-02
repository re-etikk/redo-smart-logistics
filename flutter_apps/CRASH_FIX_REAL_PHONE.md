# 📱 Real Phone Crash — Fix Checklist (emulator OK, phone pe turant band)

Emulator = DEBUG build, phone APK = RELEASE build. Crash release-only cheezon se aata hai.

## 1. Sabse pehla shak: PURANI APK
Agar APK un Gradle hacks wale code se bani thi (`-Xskip-metadata-version-check`,
AarMetadata disabled) to release me `NoSuchMethodError` par TURANT crash hota hai —
bilkul yehi symptom. Is zip me hacks hat chuke hain + `google_maps_flutter: 2.9.0` pinned.
**Fix:** purani APK uninstall → is code se fresh build:
```
flutter clean
flutter pub get
flutter build apk --release
```
`build/app/outputs/flutter-apk/app-release.apk` install karo.

## 2. Asli crash log nikaalo (30 sec — guesswork khatam)
Phone USB se laptop me lagao (USB debugging ON), phir:
```
adb logcat -c
adb logcat -s AndroidRuntime:E flutter:E
```
Ab phone pe app kholo → crash hote hi terminal me exact reason aayega.
Wo lines mujhe paste kar do — main exact fix bata dunga.

## 3. Google Maps key restriction (common #2)
Agar Maps SDK key pe "Android apps" restriction hai to usme release SHA-1 bhi add karo:
```
cd android && ./gradlew signingReport
```
`SHA1` (variant: release) copy → Google Cloud Console → key restrictions me add.
(Demo ke liye shortcut: key ki app-restriction temporarily "None" kar do.)

## 4. Quick sanity list
- Phone aur Render backend dono internet pe ✓ (apiBaseUrl https hai, cleartext issue nahi)
- Android 14 pe pehli location/camera permission runtime pe aayegi — deny mat karna
- `flutter run --release` USB phone pe = release jaisa hi, par logs ke saath (best debugging)
