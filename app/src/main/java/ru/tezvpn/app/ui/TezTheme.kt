package ru.tezvpn.app.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val Navy = Color(0xFF0C2438)
private val Gold = Color(0xFFF5C518)
private val Card = Color(0xFF16324F)
private val Mute = Color(0xFF9DB0C3)

@Composable
fun TezTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = Gold,
            onPrimary = Color(0xFF111111),
            background = Navy,
            surface = Card,
            onBackground = Color.White,
            onSurface = Color.White,
            secondary = Mute,
            error = Color(0xFFFF6B6B),
        ),
        content = content,
    )
}
