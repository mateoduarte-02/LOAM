package com.mateo.alertacatastrofes.datos

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class ServicioClima {

    // Por ahora, coordenadas fijas (más adelante las reemplazamos por el GPS real)
    private val latitud = -35.66
    private val longitud = -63.75

    // Esta función hace la conexión a internet, por eso NO se puede llamar
    // directamente desde la pantalla (bloquearía la app). Se llama desde una coroutine.
    fun obtenerClimaActual(): String {
        val url = "https://api.open-meteo.com/v1/forecast?latitude=$latitud&longitude=$longitud&current=temperature_2m,weather_code"

        val conexion = URL(url).openConnection() as HttpURLConnection
        conexion.requestMethod = "GET"

        return try {
            val respuestaTexto = conexion.inputStream.bufferedReader().use { it.readText() }
            val json = JSONObject(respuestaTexto)
            val actual = json.getJSONObject("current")
            val temperatura = actual.getDouble("temperature_2m")
            "Temperatura actual: ${temperatura}°C"
        } catch (e: Exception) {
            "No se pudo obtener el clima"
        } finally {
            conexion.disconnect()
        }
    }
}