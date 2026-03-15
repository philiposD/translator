import org.jetbrains.kotlin.gradle.dsl.JvmTarget // This is critical for line 16 to work

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.translator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // USE THE WIDELY COMPATIBLE SYNTAX
    kotlinOptions {
        jvmTarget = "17" // In Kotlin DSL, use double quotes and '='
    }

    dependencies {
        implementation("com.google.mlkit:text-recognition-chinese:16.0.0")
    }

    defaultConfig {
        applicationId = "com.example.translator"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    aaptOptions {
        noCompress "task"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = false
            isShrinkResources = false
//            isMinifyEnabled = true
//            proguardFiles(
//                getDefaultProguardFile("proguard-android-optimize.txt"),
//                "proguard-rules.pro"
//            )
        }
    }
}

flutter {
    source = "../.."
}
