package com.mateo.alertacatastrofes.modelo

data class EventoCatastrofe(
    val fecha: String = "",
    val hora: String = "",
    val ubicacion: String = "",
    val tipo: String = "",
    val timestamp: Long = 0L
)