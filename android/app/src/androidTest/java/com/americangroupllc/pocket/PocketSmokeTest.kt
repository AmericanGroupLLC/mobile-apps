package com.americangroupllc.pocket

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test

class PocketSmokeTest {
    @get:Rule val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test fun launcher_shows_all_five_tools() {
        composeTestRule.onNodeWithText("Pocket").assertIsDisplayed()
        composeTestRule.onNodeWithText("Clock").assertIsDisplayed()
        composeTestRule.onNodeWithText("Calculator").assertIsDisplayed()
        composeTestRule.onNodeWithText("Measure").assertIsDisplayed()
        composeTestRule.onNodeWithText("Compass").assertIsDisplayed()
        composeTestRule.onNodeWithText("Level").assertIsDisplayed()
    }

    @Test fun calculator_opens_from_launcher() {
        composeTestRule.onNodeWithText("Calculator").performClick()
        composeTestRule.onNodeWithText("Calculator").assertIsDisplayed()
    }
}
