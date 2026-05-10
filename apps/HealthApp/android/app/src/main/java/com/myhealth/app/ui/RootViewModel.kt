package com.myhealth.app.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.myhealth.app.data.prefs.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class RootViewModel @Inject constructor(
    private val settings: SettingsRepository,
) : ViewModel() {

    val didOnboard = settings.didOnboard
        .stateIn(viewModelScope, SharingStarted.Eagerly, initialValue = false)

    fun completeOnboarding() {
        viewModelScope.launch { settings.setDidOnboard(true) }
    }
}
