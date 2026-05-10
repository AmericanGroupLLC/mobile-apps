// Note the `import java.util.Properties` at the top — Kotlin DSL doesn't
// auto-import java.util.* and the `release` signing block uses Properties.
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.kapt")
    id("com.google.dagger.hilt.android")
}

android {
    namespace = "com.americangroupllc.offlineaibuddy"
    compileSdk = 34
    ndkVersion = "26.1.10909125"

    defaultConfig {
        applicationId = "com.americangroupllc.offlineaibuddy"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Telemetry slot — empty in v1 (no SDKs pulled). Kept so v1.1
        // can opt in by setting these env vars at build time.
        buildConfigField("String", "SENTRY_DSN",       "\"${System.getenv("SENTRY_DSN") ?: ""}\"")
        buildConfigField("String", "POSTHOG_API_KEY",  "\"${System.getenv("POSTHOG_API_KEY") ?: ""}\"")
        buildConfigField("String", "POSTHOG_HOST",     "\"${System.getenv("POSTHOG_HOST") ?: "https://us.i.posthog.com"}\"")
        // Monetization — same pattern. NoopEntitlementService /
        // NoopAdGate are the fallbacks when these are empty.
        buildConfigField("String", "REVENUECAT_API_KEY", "\"${System.getenv("REVENUECAT_API_KEY_ANDROID") ?: ""}\"")
        buildConfigField("String", "ADMOB_APP_ID",       "\"${System.getenv("ADMOB_APP_ID_ANDROID") ?: ""}\"")

        // AdMob APPLICATION_ID for the AndroidManifest <meta-data>. Defaults
        // to Google's official sample/test ID so CI / dev builds don't crash
        // at startup; release builds pass -PADMOB_APP_ID_ANDROID=ca-app-pub-...
        // (see STORE-PACKAGING.md §2). The env var is supported as a
        // secondary source so local shells can `export ADMOB_APP_ID_ANDROID=...`.
        manifestPlaceholders["admobAppId"] =
            (project.findProperty("ADMOB_APP_ID_ANDROID") as String?)
                ?: System.getenv("ADMOB_APP_ID_ANDROID")
                ?: "ca-app-pub-3940256099942544~3347511713"

        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++17"
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    signingConfigs {
        create("release") {
            val ksProps = rootProject.file("keystore.properties")
            if (ksProps.exists()) {
                val props = Properties()
                props.load(ksProps.inputStream())
                storeFile     = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias      = props.getProperty("keyAlias")
                keyPassword   = props.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.findByName("release")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    implementation(project(":core"))

    val composeBom = platform("androidx.compose:compose-bom:2024.06.00")
    // Apply the BOM to BOTH implementation AND androidTestImplementation so
    // `androidx.compose.ui:ui-test-junit4` resolves with a matching version.
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-compose:1.9.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.0")
    implementation("androidx.navigation:navigation-compose:2.8.0")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.51.1")
    kapt("com.google.dagger:hilt-compiler:2.51.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")
    implementation("androidx.hilt:hilt-work:1.2.0")
    kapt("androidx.hilt:hilt-compiler:1.2.0")

    // Storage — DataStore for prefs, no Room (small JSON files are enough).
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // WorkManager for the background-friendly model download.
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // Coil for any image loading we add later.
    implementation("io.coil-kt:coil-compose:2.6.0")

    // Monetization — RevenueCat + Google Mobile Ads (initialised
    // lazily; falls back to Noop when the keys aren't set).
    implementation("com.revenuecat.purchases:purchases:8.0.0")
    implementation("com.google.android.gms:play-services-ads:23.2.0")

    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
