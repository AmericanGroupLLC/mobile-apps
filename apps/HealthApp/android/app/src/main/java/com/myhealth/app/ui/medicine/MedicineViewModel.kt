package com.myhealth.app.ui.medicine

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.myhealth.app.data.room.MedicineDao
import com.myhealth.app.data.room.MedicineEntity
import com.myhealth.app.notifications.MedicineReminderScheduler
import com.myhealth.core.models.MedicineSchedule
import com.myhealth.core.models.TimeOfDay
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@HiltViewModel
class MedicineViewModel @Inject constructor(
    private val medicineDao: MedicineDao,
    private val scheduler: MedicineReminderScheduler,
) : ViewModel() {

    val medicines: StateFlow<List<MedicineEntity>> = medicineDao.observeActive()
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    fun add(name: String, dosage: String, hour: Int, minute: Int) {
        viewModelScope.launch {
            val schedule = MedicineSchedule(
                times = listOf(TimeOfDay(hour, minute)),
                weekdays = (1..7).toSet()
            )
            val entity = MedicineEntity(
                name = name,
                dosage = dosage,
                unit = "tablet",
                scheduleJSON = Json.encodeToString(schedule),
            )
            medicineDao.insert(entity)
            scheduler.reschedule(entity)
        }
    }
}
