// Note the `import java.util.Properties` at the top — Kotlin DSL doesn't
// auto-import java.util.* and the `release` signing block uses Properties.
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.devtools.ksp")
    id("com.google.dagger.hilt.android")
}

android {
    namespace = "com.myhealth.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.myhealth.app"
        minSdk = 26
        targetSdk = 34
        versionCode = 2
        versionName = "1.3.3"
        vectorDrawables.useSupportLibrary = true
        resourceConfigurations += listOf("en", "es", "fr", "de", "hi")
        // Sentry DSN — taken from env var or local property at build time.
        // Empty by default so opt-in stays a real toggle.
        buildConfigField(
            "String",
            "SENTRY_DSN",
            "\"${System.getenv("SENTRY_DSN") ?: providers.gradleProperty("SENTRY_DSN").getOrElse("")}\""
        )
        // PostHog API key + host — same opt-in pattern.
        buildConfigField(
            "String",
            "POSTHOG_API_KEY",
            "\"${System.getenv("POSTHOG_API_KEY") ?: providers.gradleProperty("POSTHOG_API_KEY").getOrElse("")}\""
        )
        buildConfigField(
            "String",
            "POSTHOG_HOST",
            "\"${System.getenv("POSTHOG_HOST") ?: providers.gradleProperty("POSTHOG_HOST").getOrElse("https://eu.i.posthog.com")}\""
        )
    }

    buildFeatures {
        compose = true
        buildConfig = true
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
        debug {
            enableUnitTestCoverage = true
            enableAndroidTestCoverage = true
        }
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // Use the upload key when keystore.properties is present (CI / local
            // release builds); otherwise fall back to the debug key so a release
            // build still produces a runnable, locally-signed artefact.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.findByName("debug")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    packaging { resources.excludes += "/META-INF/{AL2.0,LGPL2.1}" }
    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }
}

dependencies {
    implementation(project(":core"))

    // Compose BoM — keeps every Compose artifact at compatible versions.
    val composeBom = platform("androidx.compose:compose-bom:2024.09.02")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.navigation:navigation-compose:2.8.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.5")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.5")
    debugImplementation("androidx.compose.ui:ui-tooling")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.51.1")
    ksp("com.google.dagger:hilt-android-compiler:2.51.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")

    // DataStore
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // WorkManager + Hilt-Work
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    implementation("androidx.hilt:hilt-work:1.2.0")
    ksp("androidx.hilt:hilt-compiler:1.2.0")

    // Health Connect
    implementation("androidx.health.connect:connect-client:1.1.0-alpha07")

    // CameraX (for barcode + meal photo)
    implementation("androidx.camera:camera-core:1.3.4")
    implementation("androidx.camera:camera-camera2:1.3.4")
    implementation("androidx.camera:camera-lifecycle:1.3.4")
    implementation("androidx.camera:camera-view:1.3.4")

    // ML Kit (image labeling + barcode + text)
    implementation("com.google.mlkit:image-labeling:17.0.9")
    implementation("com.google.mlkit:barcode-scanning:17.3.0")
    implementation("com.google.mlkit:text-recognition:16.0.1")

    // Coil for images
    implementation("io.coil-kt:coil-compose:2.7.0")

    // Ktor (HTTP)
    implementation("io.ktor:ktor-client-core:2.3.12")
    implementation("io.ktor:ktor-client-cio:2.3.12")
    implementation("io.ktor:ktor-client-content-negotiation:2.3.12")
    implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.12")

    // Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    // Tests
    testImplementation("junit:junit:4.13.2")
    testImplementation("com.google.truth:truth:1.4.2")
    testImplementation("org.robolectric:robolectric:4.13")
    testImplementation("androidx.test:core:1.6.1")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestImplementation(composeBom)
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")

    // Sentry crash reporting (free Developer tier — 5k errors/month).
    // Wired through CrashReportingService — opt-in via Settings.
    implementation("io.sentry:sentry-android:7.18.0")
    // PostHog product analytics (free tier — 1M events/month, OSS).
    // Wired through AnalyticsService — opt-in via Settings.
    implementation("com.posthog:posthog-android:3.13.0")
}
