package com.mateo.alertacatastrofes.datos

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

class AyudanteAlarma(private val contexto: Context) {

    private var toneGenerator: ToneGenerator? = null
    private var sonando = false
    private val handler = Handler(Looper.getMainLooper())

    fun activarAlarma() {
        vibrar()
        iniciarSirena()
    }

    fun detenerAlarma() {
        sonando = false
        toneGenerator?.release()
        toneGenerator = null

        val vibrator = obtenerVibrator()
        vibrator.cancel()
    }

    private fun vibrar() {
        val vibrator = obtenerVibrator()
        val patron = longArrayOf(0, 500, 300, 500, 300, 500)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(patron, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(patron, 0)
        }
    }

    private fun obtenerVibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = contexto.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            contexto.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    // Genera un sonido tipo sirena, alternando dos tonos, en bucle, sin usar ningún archivo de audio
    private fun iniciarSirena() {
        sonando = true
        toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
        reproducirCicloSirena(agudo = true)
    }

    private fun reproducirCicloSirena(agudo: Boolean) {
        if (!sonando) return

        val tono = if (agudo) ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD else ToneGenerator.TONE_CDMA_ABBR_ALERT
        toneGenerator?.startTone(tono, 400)

        handler.postDelayed({
            reproducirCicloSirena(!agudo)
        }, 450)
    }
}