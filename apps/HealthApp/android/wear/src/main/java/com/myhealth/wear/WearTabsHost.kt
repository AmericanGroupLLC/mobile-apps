package com.myhealth.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Text
import com.myhealth.wear.screens.AnatomyPage
import com.myhealth.wear.screens.HistoryPage
import com.myhealth.wear.screens.LiveWorkoutPage
import com.myhealth.wear.screens.MoodPage
import com.myhealth.wear.screens.QuickLogPage
import com.myhealth.wear.screens.RunPage
import com.myhealth.wear.screens.SettingsPage
import com.myhealth.wear.screens.WaterPage
import com.myhealth.wear.screens.WeightPage

/**
 * Vertically-paged tab host — mirrors the watchOS `MainTabsView` layout.
 * 9 panes, swipe up/down to switch.
 */
@Composable
fun WearTabsHost() {
    val pagerState = rememberPagerState(pageCount = { 9 })
    Box(Modifier.fillMaxSize()) {
        VerticalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
            when (page) {
                0 -> QuickLogPage()
                1 -> LiveWorkoutPage()
                2 -> RunPage()
                3 -> AnatomyPage()
                4 -> WaterPage()
                5 -> WeightPage()
                6 -> MoodPage()
                7 -> HistoryPage()
                else -> SettingsPage()
            }
        }
    }
}
