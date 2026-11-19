import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.niceapp"
    compileSdk = 36
    //compileSdk = 34//flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"//flutter.ndkVersion
    //minSdkVersion: 23 
    //minSdk = 23

    compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
    }
    dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    implementation("com.google.android.gms:play-services-maps:18.1.0")
    implementation("com.google.android.gms:play-services-location:21.0.1")
   // implementation("com.mapbox.mapboxsdk:mapbox-android-sdk:9.6.2")
    }


   // kotlinOptions {
   //     jvmTarget ="21" //JavaVersion.VERSION_21.toString()
   // }

   kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_21
    }
}
    java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
    // buildFeatures {
      //  buildConfig = true // ✅ Enables custom BuildConfig fields
   // }
   }

  signingConfigs {
        create("release") {
            storeFile = file("D:\\Finovec\\Keys\\release-key.jks")
            storePassword = "ba4nyibA,"
            keyAlias = "vicsacs"
            keyPassword = "ba4nyibA,"
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.niceapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion//flutter.minSdkVersion
        targetSdk = 34//flutter.targetSdkVersion
        versionCode = 1//flutter.versionCode
        versionName = "1.0"//flutter.versionName
        multiDexEnabled=true

  }

    buildTypes {
    getByName("release") {
        isMinifyEnabled = false
        isShrinkResources = false // ✅ Add this line
        signingConfig = signingConfigs.getByName("release")
    }
    getByName("debug") {
        isMinifyEnabled = false
        isShrinkResources = false // ✅ Add this line too
        signingConfig = signingConfigs.getByName("release")
    }
}
}

flutter {
    source = "../.."
}
