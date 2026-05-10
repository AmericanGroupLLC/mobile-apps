package com.myhealth.wear

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.wear.compose.material.MaterialTheme
import com.myhealth.wear.screens.AnatomyPage
import com.myhealth.wear.screens.QuickLogPage
import org.junit.Rule
import org.junit.Test

/** Wear Compose UI tests — exercise enough of the page surface that we'd
 *  catch a hard render failure without needing a watch face. */
class WearScreensInstrumentedTest {

    @get:Rule val composeRule = createComposeRule()

    @Test fun quickLogPageRenders() {
        composeRule.setContent {
            MaterialTheme { QuickLogPage() }
        }
        composeRule.onNodeWithText("Quick Log").assertIsDisplayed()
    }

    @Test fun anatomyPageShowsHeader() {
        composeRule.setContent {
            MaterialTheme { AnatomyPage() }
        }
        composeRule.onNodeWithText("Anatomy").assertIsDisplayed()
    }
}
