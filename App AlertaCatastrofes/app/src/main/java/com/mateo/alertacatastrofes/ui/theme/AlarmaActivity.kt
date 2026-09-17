package com.mateo.alertacatastrofes.ui

import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.graphics.Color
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.mateo.alertacatastrofes.R
import com.mateo.alertacatastrofes.datos.AyudanteAlarma

class AlarmaActivity : AppCompatActivity() {

    private val ayudanteAlarma = AyudanteAlarma(this)
    private var animadorLuces: ObjectAnimator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_alarma)

        val detalle = intent.getStringExtra("detalle") ?: ""
        findViewById<TextView>(R.id.tv_detalle_evento).text = detalle

        val fondo: LinearLayout = findViewById(R.id.fondo_alarma)
        iniciarEfectoLuces(fondo)

        ayudanteAlarma.activarAlarma()

        findViewById<LinearLayout>(R.id.btn_detener_alarma).setOnClickListener {
            finish()
        }
    }

    private fun iniciarEfectoLuces(vista: LinearLayout) {
        val colorInicial = resources.getColor(R.color.peligro, theme)
        val colorFinal = Color.parseColor("#FFC107")

        animadorLuces = ObjectAnimator.ofArgb(vista, "backgroundColor", colorInicial, colorFinal).apply {
            duration = 400
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
            start()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        animadorLuces?.cancel()
        ayudanteAlarma.detenerAlarma()
    }
}