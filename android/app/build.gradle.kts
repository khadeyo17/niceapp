plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.niceapp"
    compileSdk = 35
    //compileSdk = 34//flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"//flutter.ndkVersion
    //minSdkVersion: 23 
    //minSdk = 23

    compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    }
    dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    implementation("com.google.android.gms:play-services-maps:18.1.0")
    implementation("com.google.android.gms:play-services-location:21.0.1")
   // implementation("com.mapbox.mapboxsdk:mapbox-android-sdk:9.6.2")
    }
    kotlinOptions {
        jvmTarget ="17" //JavaVersion.VERSION_17.toString()
    }
    java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
    // buildFeatures {
      //  buildConfig = true // ✅ Enables custom BuildConfig fields
   // }
   }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.niceapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23//flutter.minSdkVersion
        targetSdk = 34//flutter.targetSdkVersion
        versionCode = 1//flutter.versionCode
        versionName = "1.0"//flutter.versionName
        multiDexEnabled=true


    //buildConfigField("String", "MAPBOX_ACCESS_TOKEN", "\"${project.findProperty("MAPBOX_DOWNLOADS_TOKEN") ?: ""}\"")
    //manifestPlaceholders["MAPBOX_ACCESS_TOKEN"] = project.findProperty("MAPBOX_DOWNLOADS_TOKEN") ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
