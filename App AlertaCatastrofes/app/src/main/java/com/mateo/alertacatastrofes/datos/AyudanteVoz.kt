package com.mateo.alertacatastrofes.datos

enum class ComandoVoz {
    LINTERNA, EMERGENCIA, BATERIA, UBICACION, CLIMA, CHAT, GUIA, VIDEO, AUDIO, DESCONOCIDO
}

object AyudanteVoz {

    fun interpretar(textoReconocido: String): ComandoVoz {
        val texto = textoReconocido.lowercase()

        return when {
            texto.contains("linterna") || texto.contains("flash") -> ComandoVoz.LINTERNA
            texto.contains("emergencia") || texto.contains("bombero") || texto.contains("policía") -> ComandoVoz.EMERGENCIA
            texto.contains("batería") || texto.contains("bateria") -> ComandoVoz.BATERIA
            texto.contains("ubicación") || texto.contains("ubicacion") || texto.contains("dónde estoy") || texto.contains("donde estoy") -> ComandoVoz.UBICACION
            texto.contains("clima") || texto.contains("tiempo") -> ComandoVoz.CLIMA
            texto.contains("chat") || texto.contains("asistencia") -> ComandoVoz.CHAT
            texto.contains("guía") || texto.contains("guia") || texto.contains("consejo") -> ComandoVoz.GUIA
            texto.contains("video") -> ComandoVoz.VIDEO
            texto.contains("audio") || texto.contains("grabar") -> ComandoVoz.AUDIO
            else -> ComandoVoz.DESCONOCIDO
        }
    }
}