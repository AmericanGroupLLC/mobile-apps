package com.americangroupllc.buddyplay

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class BuddyPlaySmokeTest {

    @get:Rule(order = 0) val hiltRule = HiltAndroidRule(this)
    @get:Rule(order = 1) val composeRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun home_screen_renders_all_three_games() {
        composeRule.onNodeWithText("BuddyPlay").assertIsDisplayed()
        composeRule.onNodeWithText("Royal Chess").assertIsDisplayed()
        composeRule.onNodeWithText("Dice Kingdom").assertIsDisplayed()
        composeRule.onNodeWithText("Mini Racer").assertIsDisplayed()
    }

    @Test
    fun navigates_to_settings() {
        composeRule.onNodeWithText("Settings").performClick()
        composeRule.onNodeWithText("BuddyPlay does not send any data.")
            .assertIsDisplayed()
    }
}
