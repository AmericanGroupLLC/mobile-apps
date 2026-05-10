package com.americangroupllc.offlineaibuddy.translate

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import com.americangroupllc.offlineaibuddy.core.models.Language
import com.americangroupllc.offlineaibuddy.llm.LlamaService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TranslateViewModel @Inject constructor(private val llama: LlamaService) : ViewModel() {
    val output = MutableStateFlow("")
    fun translate(src: Language, dst: Language, text: String) {
        viewModelScope.launch {
            output.value = ""
            llama.generate(
                kind = ChatSession.Kind.TRANSLATE,
                language = dst,
                isKidSafe = false,
                history = emptyList(),
                userInput = text,
                translateSrc = src,
                translateDst = dst,
            ).collect { output.value = output.value + it }
        }
    }
}

@Composable
fun TranslateScreen(vm: TranslateViewModel = hiltViewModel()) {
    var src by remember { mutableStateOf(Language.EN) }
    var dst by remember { mutableStateOf(Language.HI) }
    var input by remember { mutableStateOf("") }
    val output by vm.output.collectAsState()

    Column(
        modifier = Modifier.fillMaxWidth().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            LangPicker(src) { src = it }
            Text("→")
            LangPicker(dst) { dst = it }
        }
        OutlinedTextField(value = input, onValueChange = { input = it }, label = { Text("Source text") })
        Button(onClick = { vm.translate(src, dst, input) }, enabled = input.isNotBlank()) {
            Text("Translate")
        }
        Text(output)
    }
}

@Composable
private fun LangPicker(value: Language, onChange: (Language) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Column {
        Button(onClick = { expanded = true }) { Text(value.displayName) }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            Language.values().forEach { l ->
                DropdownMenuItem(text = { Text(l.displayName) }, onClick = {
                    onChange(l); expanded = false
                })
            }
        }
    }
}
