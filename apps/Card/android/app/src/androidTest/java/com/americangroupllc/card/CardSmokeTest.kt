package com.americangroupllc.card

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onFirst
import androidx.test.ext.junit.runners.AndroidJUnit4
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Ignore
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class CardSmokeTest {

    @get:Rule(order = 0) val hiltRule = HiltAndroidRule(this)
    @get:Rule(order = 1) val composeRule = createAndroidComposeRule<MainActivity>()

    @Test
    @Ignore(
        "Pending test-only activity entrypoint: createAndroidComposeRule<MainActivity> " +
            "launches the production activity before HiltAndroidRule.inject(), so the " +
            "Compose hierarchy never attaches. Re-enable once a HiltTestActivity is added.",
    )
    fun composerSavesAndShowsRow() {
        hiltRule.inject()
        composeRule.onAllNodesWithTag("composer.field").onFirst().performTextInput("Buy milk")
        composeRule.onAllNodesWithTag("composer.send").onFirst().performClick()
        composeRule.onNodeWithText("Buy milk").assertExists()
    }
}
