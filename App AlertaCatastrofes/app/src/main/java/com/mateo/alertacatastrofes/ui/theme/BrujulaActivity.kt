package com.mateo.alertacatastrofes.ui

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.mateo.alertacatastrofes.R

class BrujulaActivity : AppCompatActivity(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var sensorAcelerometro: Sensor? = null
    private var sensorMagnetico: Sensor? = null

    private val valoresAcelerometro = FloatArray(3)
    private val valoresMagneticos = FloatArray(3)
    private var anguloActual = 0f

    private lateinit var aguja: ImageView
    private lateinit var textoGrados: TextView
    private lateinit var textoDireccion: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_brujula)

        aguja = findViewById(R.id.iv_aguja)
        textoGrados = findViewById(R.id.tv_grados)
        textoDireccion = findViewById(R.id.tv_direccion_cardinal)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensorAcelerometro = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        sensorMagnetico = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

        if (sensorAcelerometro == null || sensorMagnetico == null) {
            textoDireccion.text = "Este dispositivo no tiene sensor de brújula"
        }
    }

    override fun onResume() {
        super.onResume()
        sensorAcelerometro?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }
        sensorMagnetico?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI) }
    }

    override fun onPause() {
        super.onPause()
        sensorManager.unregisterListener(this)
    }

    override fun onSensorChanged(evento: SensorEvent?) {
        if (evento == null) return

        when (evento.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> System.arraycopy(evento.values, 0, valoresAcelerometro, 0, 3)
            Sensor.TYPE_MAGNETIC_FIELD -> System.arraycopy(evento.values, 0, valoresMagneticos, 0, 3)
        }

        val matrizRotacion = FloatArray(9)
        val exito = SensorManager.getRotationMatrix(matrizRotacion, null, valoresAcelerometro, valoresMagneticos)

        if (exito) {
            val orientacion = FloatArray(3)
            SensorManager.getOrientation(matrizRotacion, orientacion)

            var grados = Math.toDegrees(orientacion[0].toDouble()).toFloat()
            grados = (grados + 360) % 360

            // Rotamos la aguja suavemente hacia el ángulo nuevo (en sentido contrario para que apunte al norte real)
            aguja.rotation = -grados
            anguloActual = grados

            textoGrados.text = "${grados.toInt()}°"
            textoDireccion.text = obtenerDireccionCardinal(grados)
        }
    }

    private fun obtenerDireccionCardinal(grados: Float): String {
        return when {
            grados >= 337.5 || grados < 22.5 -> "Norte"
            grados < 67.5 -> "Noreste"
            grados < 112.5 -> "Este"
            grados < 157.5 -> "Sudeste"
            grados < 202.5 -> "Sur"
            grados < 247.5 -> "Sudoeste"
            grados < 292.5 -> "Oeste"
            else -> "Noroeste"
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}