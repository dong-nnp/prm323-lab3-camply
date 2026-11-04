plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.prm393_lab03"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.prm393_lab03"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Flutter 3.47 copies the packaged APK in an assembleDebug doLast action without
// declaring its inputs/outputs. Track that copy so unchanged APKs are reused.
// Keep Flutter's action: changed inputs or a missing/modified destination still
// cause the APK to be copied. Scope this to our unflavored, non-split debug APK;
// release/profile and split-per-ABI builds keep Flutter's default behavior.
androidComponents {
    onVariants(selector().withBuildType("debug")) { variant ->
        if (variant.name == "debug" && project.findProperty("split-per-abi") != "true") {
            val packagedApk = variant.artifacts.get(com.android.build.api.artifact.SingleArtifact.APK)
            val flutterApk = layout.buildDirectory.file("outputs/flutter-apk/app-debug.apk")
            tasks.matching { it.name == "assembleDebug" }.configureEach {
                inputs.dir(packagedApk).withPropertyName("packagedDebugApk")
                outputs.file(flutterApk).withPropertyName("flutterDebugApk")
            }
            // Flutter otherwise deletes/re-copies the merged asset directory on
            // every launch, even when compileFlutterBuildDebug is UP-TO-DATE.
            // Run compilation first and keep cleaning for every other outcome
            // (including FROM-CACHE). Android asset changes and missing outputs
            // are still handled by mergeDebugAssets/copyFlutterAssetsDebug.
            tasks.matching { it.name == "cleanMergeDebugAssets" }.configureEach {
                val compileFlutter = tasks.named("compileFlutterBuildDebug")
                dependsOn(compileFlutter)
                onlyIf("Flutter asset bundle is not already up-to-date") {
                    compileFlutter.get().state.skipMessage != "UP-TO-DATE"
                }
            }
        }
    }
}
