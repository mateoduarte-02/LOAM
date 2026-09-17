package com.mateo.alertacatastrofes.datos

import android.content.Context
import android.os.BatteryManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AyudanteBateria(private val contexto: Context) {

    fun obtenerPorcentaje(): Int {
        val batteryManager = contexto.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    fun estimarTiempoRestanteMinutos(porcentaje: Int): Int {
        val minutosPorPorcentaje = 3
        return porcentaje * minutosPorPorcentaje
    }

    fun calcularHoraSinBateria(minutosRestantes: Int): String {
        val ahora = Date()
        val horaFutura = Date(ahora.time + minutosRestantes * 60_000L)
        val formato = SimpleDateFormat("HH:mm", Locale.getDefault())
        return formato.format(horaFutura)
    }
}