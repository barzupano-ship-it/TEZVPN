import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "ru.tezvpn.tezvpn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ru.tezvpn.app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePath = System.getenv("CM_KEYSTORE_PATH")?.takeIf { it.isNotEmpty() }
        ?: keystoreProperties.getProperty("storeFile")?.takeIf { it.isNotEmpty() }
    if (!keystorePath.isNullOrEmpty()) {
        signingConfigs {
            create("release") {
                storeFile = file(keystorePath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")?.takeIf { it.isNotEmpty() }
                    ?: keystoreProperties.getProperty("storePassword")
                keyAlias = System.getenv("CM_KEY_ALIAS")?.takeIf { it.isNotEmpty() }
                    ?: keystoreProperties.getProperty("keyAlias")
                keyPassword = System.getenv("CM_KEY_PASSWORD")?.takeIf { it.isNotEmpty() }
                    ?: keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (!keystorePath.isNullOrEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
    packaging {
        resources {
            excludes += setOf(
                "META-INF/versions/9/OSGI-INF/MANIFEST.MF",
                "META-INF/INDEX.LIST",
                "META-INF/*.kotlin_module",
            )
        }
    }
}

dependencies {
    implementation("com.zaneschepke:amneziawg-android:2.3.7")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
