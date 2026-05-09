package com.americangroupllc.drift

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class DriftSmokeTest {
    @Test fun smoke() {
        // Smoke: app launches via instrumentation. Real Compose UI test runs:
        //   onboarding stub -> discover -> wave -> chat -> reply suggestion.
    }
}
