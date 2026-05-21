plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.saferoom"
    compileSdk = 36  // или flutter.compileSdkVersion если хотите оставить как было
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // Добавьте эту строку
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.saferoom"
        minSdk = 26
        targetSdk = 36 // Пробуем 35
        versionCode = 25  // УВЕЛИЧЬТЕ СИЛЬНО! (было 20)
        versionName = "2.0.0"  // Меняем версию
        multiDexEnabled = true
//        targetSdk = flutter.targetSdkVersion
//        versionCode = flutter.versionCode
//        versionName = flutter.versionName

        // Добавьте эту строку
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {



    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
