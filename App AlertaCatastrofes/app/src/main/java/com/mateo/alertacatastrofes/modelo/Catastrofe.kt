package com.mateo.alertacatastrofes.modelo

data class Catastrofe(
    val nombre: String,
    val emoji: String,
    val urlImagen: String,
    val consejos: List<String>,
    val urlVideo: String
)