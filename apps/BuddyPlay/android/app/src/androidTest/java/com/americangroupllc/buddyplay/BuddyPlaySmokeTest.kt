package com.americangroupllc.buddyplay

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
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
        composeRule.onAllNodesWithText("Royal Chess").assertCountEquals(1)
        composeRule.onAllNodesWithText("Dice Kingdom").assertCountEquals(1)
        composeRule.onAllNodesWithText("Mini Racer").assertCountEquals(1)
    }

    @Test
    fun navigates_to_settings() {
        composeRule.onNodeWithText("Settings").performClick()
        composeRule.onAllNodesWithText("BuddyPlay does not send any data.")
            .assertCountEquals(1)
    }
}
