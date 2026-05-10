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
    namespace = "com.americangroupllc.buddyplay"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.americangroupllc.buddyplay"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "com.americangroupllc.buddyplay.HiltTestRunner"

        // Telemetry slot — empty in v1 (no SDKs pulled). Kept so v1.1 can
        // opt in by setting these env vars at build time.
        buildConfigField("String", "SENTRY_DSN",       "\"${System.getenv("SENTRY_DSN") ?: ""}\"")
        buildConfigField("String", "POSTHOG_API_KEY",  "\"${System.getenv("POSTHOG_API_KEY") ?: ""}\"")
        buildConfigField("String", "POSTHOG_HOST",     "\"${System.getenv("POSTHOG_HOST") ?: "https://us.i.posthog.com"}\"")
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
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.51.1")
    kapt("com.google.dagger:hilt-compiler:2.51.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // Storage — DataStore for prefs, no Room (single tiny JSON file is enough).
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // Coil for any image loading we add later (e.g. opponent avatars).
    implementation("io.coil-kt:coil-compose:2.6.0")

    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    androidTestImplementation("com.google.dagger:hilt-android-testing:2.51.1")
    kaptAndroidTest("com.google.dagger:hilt-android-compiler:2.51.1")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
