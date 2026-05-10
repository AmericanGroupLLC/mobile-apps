// Top-level build file
plugins {
    id("com.android.application") version "8.5.0" apply false
    id("org.jetbrains.kotlin.android") version "2.0.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.0" apply false
    id("org.jetbrains.kotlin.kapt") version "2.0.0" apply false
    id("com.google.dagger.hilt.android") version "2.51.1" apply false
    // Google Services plugin (consumed by :app to wire google-services.json
    // into the Firebase Messaging SDK). `apply false` here so the root
    // project doesn't try to apply it itself.
    id("com.google.gms.google-services") version "4.4.2" apply false
}
