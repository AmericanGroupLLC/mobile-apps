package com.americangroupllc.card.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.americangroupllc.card.core.obs.AnalyticsEvent
import com.americangroupllc.card.core.obs.AnalyticsService
import com.americangroupllc.card.core.obs.CrashReportingService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

data class SettingsState(
    val use24Hour: Boolean = false,
    val theme: ThemeChoice = ThemeChoice.SYSTEM,
    val analyticsOptedIn: Boolean = false,
    val crashOptedIn: Boolean = false,
)

enum class ThemeChoice { SYSTEM, LIGHT, DARK }

@HiltViewModel
class SettingsViewModel @Inject constructor() : ViewModel() {
    private val _state = MutableStateFlow(SettingsState())
    val state: StateFlow<SettingsState> = _state.asStateFlow()

    fun setUse24Hour(v: Boolean) {
        _state.value = _state.value.copy(use24Hour = v)
        AnalyticsService.shared.track(AnalyticsEvent.SettingsToggled("use_24_hour", v))
    }

    fun setTheme(t: ThemeChoice) {
        _state.value = _state.value.copy(theme = t)
    }

    fun setAnalyticsOptedIn(v: Boolean) {
        _state.value = _state.value.copy(analyticsOptedIn = v)
        AnalyticsService.shared.optedIn = v
        AnalyticsService.shared.track(AnalyticsEvent.SettingsToggled("analytics_opt_in", v))
    }

    fun setCrashOptedIn(v: Boolean) {
        _state.value = _state.value.copy(crashOptedIn = v)
        CrashReportingService.shared.optedIn = v
    }
}
