package com.americangroupllc.pocketwear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.material.*
import com.americangroupllc.pocket.core.calculator.CalcResult
import com.americangroupllc.pocket.core.calculator.CalculatorEngine
import com.americangroupllc.pocketwear.compass.WearCompass
import com.americangroupllc.pocketwear.level.WearLevel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { PocketWearRoot() }
    }
}

@Composable
fun PocketWearRoot() {
    var page by remember { mutableStateOf(0) }
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        when (page) {
            0 -> WearClock(onSwipe = { page = (page + 1) % 4 })
            1 -> WearCalculator(onSwipe = { page = (page + 1) % 4 })
            2 -> WearCompass(onSwipe = { page = (page + 1) % 4 })
            3 -> WearLevel(onSwipe = { page = (page + 1) % 4 })
        }
    }
}

@Composable
fun WearClock(onSwipe: () -> Unit) {
    var now by remember { mutableStateOf(Date()) }
    LaunchedEffect(Unit) {
        while (true) { now = Date(); kotlinx.coroutines.delay(1000) }
    }
    val fmt = remember { SimpleDateFormat("HH:mm:ss", Locale.getDefault()) }
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(fmt.format(now), style = MaterialTheme.typography.display1)
        Spacer(Modifier.height(8.dp))
        Button(onClick = onSwipe) { Text("Next") }
    }
}

@Composable
fun WearCalculator(onSwipe: () -> Unit) {
    var expr by remember { mutableStateOf("") }
    var disp by remember { mutableStateOf("0") }
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(disp, style = MaterialTheme.typography.title2)
        ScalingLazyColumn {
            items(listOf("7","8","9","÷","4","5","6","×","1","2","3","-","0",".","=","+")) { k ->
                Chip(onClick = {
                    if (k == "=") {
                        when (val r = CalculatorEngine.evaluate(expr)) {
                            is CalcResult.Number -> { disp = r.value.toString(); expr = disp }
                            is CalcResult.Error  -> { disp = r.message }
                        }
                    } else {
                        expr += k
                        when (val r = CalculatorEngine.evaluate(expr)) {
                            is CalcResult.Number -> disp = r.value.toString()
                            is CalcResult.Error  -> disp = expr
                        }
                    }
                }, label = { Text(k) })
            }
        }
        Button(onClick = onSwipe) { Text("Next") }
    }
}
