package com.myhealth.app.ui.diary

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.myhealth.app.data.room.MealEntity

@Composable
fun DiaryScreen(nav: NavController, vm: DiaryViewModel = hiltViewModel()) {
    val meals by vm.meals.collectAsStateWithLifecycle(emptyList())
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Food Diary", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("Today + 14-day history", color = MaterialTheme.colorScheme.onSurfaceVariant)

        LazyColumn(Modifier.padding(top = 8.dp)) {
            items(meals, key = { it.id }) { meal -> MealRow(meal) }
        }
    }
}

@Composable
private fun MealRow(meal: MealEntity) {
    Column(Modifier.padding(vertical = 8.dp)) {
        Text(meal.name, fontWeight = FontWeight.SemiBold)
        Text("${meal.kcal.toInt()} kcal · P${meal.protein.toInt()} C${meal.carbs.toInt()} F${meal.fat.toInt()}",
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
    }
}
