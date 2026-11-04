# Android debug build performance

## Project-level fix (Flutter 3.47.8 / Gradle 9.3.1 / AGP 9.1.0)

`android/app/build.gradle.kts` adds incremental tracking for the unflavored,
non-split `debug` APK. Flutter's original copy action is retained. The packaged
APK directory is an input and `outputs/flutter-apk/app-debug.apk` is an output
of `assembleDebug`; unchanged APKs can therefore be UP-TO-DATE. Missing or
modified outputs and changed packaged APKs cause the copy to execute again.

The Flutter `cleanMergeDebugAssets` hook now waits for Flutter compilation and
skips only when that task's outcome is exactly `UP-TO-DATE`. For all other
outcomes, including `FROM-CACHE`, Flutter's original cleanup remains enabled.
This avoids deleting and recopying the asset bundle on an unchanged launch.
AGP merge/copy task inputs and outputs still track Android asset changes and
missing files. Java/Kotlin/Dex/packaging prerequisites remain in the task graph.

No tasks are disabled globally. Release/profile, flavors and split-per-ABI
builds retain default behavior. No Flutter SDK patch, dependency removal,
Defender exclusion, global cache deletion or RAM/daemon setting was applied.
Recheck the Flutter task wiring/outcome after a Flutter/AGP/Gradle upgrade.

## Verification, 04 November 2026

- Actual baseline `flutter run --no-resident --no-pub -v`: Gradle **85.1s**,
  total command **195.865s**. Host memory pressure makes total time variable.
- With APK tracking only: second Gradle invocation **24.308s**; assembleDebug
  UP-TO-DATE, but Flutter still recopied assets (9.018s in that profile).
- With both changes, identical Gradle arguments captured from Flutter run:
  **7.419s / 5.831s**, both successful. Warm compile, merge, asset copy and APK
  copy reuse outputs; the cleanup hook skips on UP-TO-DATE.
- Missing Flutter APK: moved only the generated APK to a scratch backup, then
  rebuilt. The destination was regenerated and its SHA-256 matched the original.
- Changed entrypoint: used a temporary Dart entrypoint outside the project;
  the APK hash changed and the Flutter output matched the packaged output.
  Restored the original entrypoint and verified both APK hashes matched again.
  The probe was not installed; app Dart code was not edited for these checks.
- Missing packaged APK: backed up that single build artifact and rebuilt it;
  AGP regenerated a valid packaged output and Flutter copied the matching APK.
  No project source, Gradle dependency cache or application data was deleted.

The old APK was 169,002,659 bytes while its ZIP entries had about85.8MB of
compressed content. Fresh packaging produced **86,072,627 bytes**; the large
unused ZIP regions were an additional transfer/copy cost. This regeneration
was a one-time artifact recovery, not a permanent guarantee of APK size after
future incremental packaging. Build output size is separate from runtime heap.

User-supplied log separately recorded Gradle39.6s, APK installation71.3s and
sync14.0s. The Gradle fix does not bypass Android installation or guarantee a
fixed total launch time. Legacy KGP/Java warnings were non-fatal. Missing
google_app_id means Analytics is unconfigured; no Firebase credentials were
invented. Slow Android class verification and skipped startup frames require
separate emulator/host investigation; they do not identify a Dart rendering bug.

Normal command remains `flutter run -d emulator-5554`. Hot reload/restart are
still available, but the fix also applies to a new Flutter run session.

See `docs/test-plan.md` for the final native build and launch verification.

## Final Flutter CLI checks

- `flutter build apk --debug --target-platform android-x64 --no-pub`: success,
  Gradle63.9s, total69.957s (Flutter build uses different target/filesystem input
  properties from Flutter run; not an unchanged warm-run benchmark).
- First `flutter run --no-resident --no-pub -v` after that build: success,
  Gradle40.7s, install15.8s, total114.393s. The input transition rebuilt the bundle.
- Second identical run: success, Gradle**8.6s**, install**1.893s**, sync**4.1s**,
  total**39.739s**. `cleanMergeDebugAssets` SKIPPED, `copyFlutterAssetsDebug` and
  `assembleDebug` UP-TO-DATE. MainActivity was the emulator's top resumed activity.
- Final APK114,782,260 bytes. The86MB fresh-package result was temporary;
  subsequent incremental packaging grew the APK again. No APK compactor or
  permanent size guarantee was introduced.
- Startup log still reports skipped frames. This change addresses build/copy
  work, not all startup latency or emulator scheduling. The before/after runs
  were not isolated A/B hardware measurements; memory pressure and cache warmth
  varied. Do not claim all installation improvement comes from this Gradle edit.
