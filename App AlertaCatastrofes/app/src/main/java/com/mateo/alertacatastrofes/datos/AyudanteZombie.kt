package com.mateo.alertacatastrofes.datos

import android.content.Context
import java.util.concurrent.TimeUnit

class AyudanteZombie(contexto: Context) {

    private val preferencias = contexto.getSharedPreferences("zombie_prefs", Context.MODE_PRIVATE)

    fun obtenerDiasEnBunker(): Int {
        val fechaInicio = preferencias.getLong("fecha_inicio_bunker", -1L)
        val inicio = if (fechaInicio == -1L) {
            val ahora = System.currentTimeMillis()
            preferencias.edit().putLong("fecha_inicio_bunker", ahora).apply()
            ahora
        } else {
            fechaInicio
        }
        val diferenciaMs = System.currentTimeMillis() - inicio
        return TimeUnit.MILLISECONDS.toDays(diferenciaMs).toInt()
    }

    fun obtenerMensajeSegunDias(dias: Int): String {
        return when {
            dias == 0 -> "Día 0: todavía tenés wifi y batería al 100%."
            dias in 1..2 -> "Día $dias: todo tranquilo, pero guardás las pilas por las dudas."
            dias in 3..6 -> "Día $dias: empezaste a hablar solo. Es normal (creo)."
            dias in 7..14 -> "Día $dias: ya extrañás el sol y el wifi de tu casa."
            dias in 15..29 -> "Día $dias: le pusiste nombre a la cucaracha del bunker."
            else -> "Día $dias: sos una leyenda. O estás muy loco. Ambas cosas."
        }
    }

    fun traducirAGruñidos(texto: String): String {
        if (texto.isBlank()) return ""

        val sonidosZombie = listOf("Rrrhaaa", "Uuurgh", "Braaains", "Grrrnn", "Hhnnggh", "Aaargh", "Mmmrrgh")
        val palabras = texto.trim().split(Regex("\\s+"))

        return palabras.joinToString("... ") {
            sonidosZombie.random()
        } + "..."
    }

    // Simula la "transcripción" de un audio grabado a un zombie
    fun generarTraduccionDeAudio(): Pair<String, String> {
        val opciones = listOf(
            "Grrrnn... uuurgh... braaains..." to "Traducción: \"Hola, ¿tenés algo de comer? Preferiblemente cerebros.\"",
            "Rrrhaaa... hhnnggh... mmmrrgh..." to "Traducción: \"La verdad, este apocalipsis me tiene agotado.\"",
            "Aaargh... grrrnn... braaains... uuurgh..." to "Traducción: \"¿Alguien vio mi otro brazo? Lo dejé por acá.\"",
            "Uuurgh... rrrhaaa..." to "Traducción: \"No, gracias, ya comí.\"",
            "Braaains... hhnnggh... mmmrrgh... aaargh..." to "Traducción: \"Che, bajá un cambio, no soy tan rápido corriendo.\"",
            "Grrrnn... uuurgh..." to "Traducción: \"¿Este bunker tiene wifi?\""
        )
        return opciones.random()
    }
}