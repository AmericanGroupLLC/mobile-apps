package com.americangroupllc.pocket.calculator

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.americangroupllc.pocket.core.calculator.CalcResult
import com.americangroupllc.pocket.core.calculator.CalculatorEngine

private data class Key(val label: String, val emit: String? = null, val action: String? = null)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalculatorScreen() {
    var expression by remember { mutableStateOf("") }
    var display by remember { mutableStateOf("0") }

    fun recompute() {
        if (expression.isEmpty()) { display = "0"; return }
        when (val r = CalculatorEngine.evaluate(expression)) {
            is CalcResult.Number -> display = formatNumber(r.value)
            is CalcResult.Error  -> display = expression
        }
    }
    fun appendKey(s: String) { expression += s; recompute() }
    fun clearAll() { expression = ""; display = "0" }
    fun backspace() { if (expression.isNotEmpty()) { expression = expression.dropLast(1); recompute() } }
    fun equals() {
        when (val r = CalculatorEngine.evaluate(expression)) {
            is CalcResult.Number -> { display = formatNumber(r.value); expression = formatNumber(r.value) }
            is CalcResult.Error  -> { display = r.message }
        }
    }

    val keys = listOf(
        Key("AC", action = "clear"), Key("(", "("), Key(")", ")"), Key("÷", "÷"),
        Key("7", "7"), Key("8", "8"), Key("9", "9"), Key("×", "×"),
        Key("4", "4"), Key("5", "5"), Key("6", "6"), Key("−", "-"),
        Key("1", "1"), Key("2", "2"), Key("3", "3"), Key("+", "+"),
        Key("0", "0"), Key(".", "."), Key("⌫", action = "back"), Key("=", action = "eq"),
    )

    Scaffold(topBar = { TopAppBar(title = { Text("Calculator") }) }) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().padding(16.dp)) {
            Text(
                text = expression.ifEmpty { " " },
                modifier = Modifier.fillMaxWidth(),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.End
            )
            Text(
                text = display,
                modifier = Modifier.fillMaxWidth(),
                fontSize = 48.sp,
                textAlign = TextAlign.End
            )
            Spacer(Modifier.height(16.dp))
            LazyVerticalGrid(columns = GridCells.Fixed(4), modifier = Modifier.fillMaxSize()) {
                items(keys) { k ->
                    Button(
                        onClick = {
                            when {
                                k.action == "clear" -> clearAll()
                                k.action == "back"  -> backspace()
                                k.action == "eq"    -> equals()
                                k.emit != null      -> appendKey(k.emit)
                            }
                        },
                        modifier = Modifier.padding(4.dp).fillMaxWidth().height(64.dp)
                    ) { Text(k.label, fontSize = 22.sp) }
                }
            }
        }
    }
}

private fun formatNumber(d: Double): String {
    if (d == d.toLong().toDouble()) return d.toLong().toString()
    return d.toString()
}
