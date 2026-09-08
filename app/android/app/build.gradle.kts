import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = when {
    rootProject.file("key.properties").exists() -> rootProject.file("key.properties")
    project.file("key.properties").exists() -> project.file("key.properties")
    project.file("src/key.properties").exists() -> project.file("src/key.properties")
    else -> null
}
if (keystorePropertiesFile != null && keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.solana.identityregistry"
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

    signingConfigs {
        val keyAliasProp = keystoreProperties.getProperty("keyAlias")
        val keyPasswordProp = keystoreProperties.getProperty("keyPassword")
        val storeFileProp = keystoreProperties.getProperty("storeFile")
        val storePasswordProp = keystoreProperties.getProperty("storePassword")

        if (keyAliasProp != null && keyPasswordProp != null && storeFileProp != null && storePasswordProp != null) {
            create("release") {
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                storeFile = if (file(storeFileProp).exists()) {
                    file(storeFileProp)
                } else if (rootProject.file(storeFileProp).exists()) {
                    rootProject.file(storeFileProp)
                } else {
                    file("release.keystore")
                }
                storePassword = storePasswordProp
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.findByName("release")
            signingConfig = releaseSigning ?: signingConfigs.getByName("debug")
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
