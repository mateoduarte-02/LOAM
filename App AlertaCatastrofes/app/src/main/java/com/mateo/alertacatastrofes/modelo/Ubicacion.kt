package com.mateo.alertacatastrofes.modelo

data class Ubicacion(
    val latitud: Double = 0.0,
    val longitud: Double = 0.0,
    val direccion: String = "",
    val referencia: String = "",
    val fecha: String = ""
)