package com.myhealth.app.ui.diary

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.myhealth.app.data.room.MealDao
import com.myhealth.app.data.room.MealEntity
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

@HiltViewModel
class DiaryViewModel @Inject constructor(mealDao: MealDao) : ViewModel() {
    val meals: StateFlow<List<MealEntity>> = mealDao.observeRecent(200)
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())
}
