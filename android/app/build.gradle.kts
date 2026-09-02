import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("dev.flutter.flutter-gradle-plugin")
}

// Charge le fichier de clés (assure-toi que le nom et l'emplacement sont corrects)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties") // ou "key.properties" si c'est ton nom
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.reader().use { keystoreProperties.load(it) }
} else {
    println("⚠️ Fichier keystore.properties introuvable à la racine du module android/")
}

android {
    namespace = "com.alertcontacts.alertcontacts"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlin { compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11) } }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.reader().use { localProperties.load(it) }
    }
    val envProperties = Properties()
    val envPropertiesFile = rootProject.file("../.env")
    if (envPropertiesFile.exists()) {
        envPropertiesFile.reader().use { envProperties.load(it) }
    }
    val mapsApiKey = localProperties.getProperty("MAPS_API_KEY_ANDROID") ?: ""
    val posthogProjectApiKey =
        localProperties.getProperty("POSTHOG_PROJECT_API_KEY")
            ?: envProperties.getProperty("POSTHOG_PROJECT_API_KEY")
            ?: ""
    val posthogHost =
        localProperties.getProperty("POSTHOG_HOST")
            ?: envProperties.getProperty("POSTHOG_HOST")
            ?: "https://us.i.posthog.com"

    defaultConfig {
        applicationId = "com.alertcontacts.alertcontacts"
        minSdk = maxOf(21, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
        manifestPlaceholders["POSTHOG_PROJECT_API_KEY"] = posthogProjectApiKey
        manifestPlaceholders["POSTHOG_HOST"] = posthogHost
        manifestPlaceholders["POSTHOG_TRACK_LIFECYCLE"] = "false"
        manifestPlaceholders["POSTHOG_DEBUG"] = "false"
        buildConfigField("String", "MAPS_API_KEY", "\"$mapsApiKey\"")
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
        }
        getByName("release") {
            // ✅ Utilise la VRAIE clé d’upload (celle avec la SHA-1 qui finit par ...:9A)
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    implementation("com.google.android.gms:play-services-location:21.2.0")
    implementation("com.google.code.gson:gson:2.10.1")

    // OkHttp
    implementation(platform("com.squareup.okhttp3:okhttp-bom:4.12.0"))
    implementation("com.squareup.okhttp3:okhttp")
    implementation("com.squareup.okhttp3:logging-interceptor")

    implementation(kotlin("stdlib-jdk7"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")

}

flutter {
    source = "../.."
}
