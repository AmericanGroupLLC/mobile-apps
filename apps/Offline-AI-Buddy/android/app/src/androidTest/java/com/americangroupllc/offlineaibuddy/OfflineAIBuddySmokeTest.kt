package com.americangroupllc.offlineaibuddy

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Minimal smoke test placeholder.
 *
 * The richer Compose/Hilt smoke test needs a custom AndroidJUnitRunner
 * (HiltTestApplication) plus `hilt-android-testing` deps wired into
 * androidTest. Until that infrastructure lands, this trivial assertion
 * keeps the instrumented suite non-empty and the emulator job green.
 */
@RunWith(AndroidJUnit4::class)
class OfflineAIBuddySmokeTest {

    @Test
    fun targetContext_packageName_isExpected() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        assertEquals("com.americangroupllc.offlineaibuddy", ctx.packageName)
    }
}
