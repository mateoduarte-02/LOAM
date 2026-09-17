package com.mateo.alertacatastrofes.ui

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.mateo.alertacatastrofes.R
import com.mateo.alertacatastrofes.datos.AyudanteMultimedia

class GrabarAudioActivity : AppCompatActivity() {

    private val ayudante = AyudanteMultimedia(this)
    private var grabador: MediaRecorder? = null
    private var estaGrabando = false
    private lateinit var rutaArchivoActual: String

    private val pedirPermisoMic = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { concedido ->
        if (concedido) {
            comenzarGrabacion()
        } else {
            Toast.makeText(this, "Se necesita permiso de micrófono", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_grabar_audio)

        val boton: LinearLayout = findViewById(R.id.btn_audio)
        boton.setOnClickListener {
            if (estaGrabando) {
                detenerGrabacion()
            } else {
                verificarPermisoYGrabar()
            }
        }
    }

    private fun verificarPermisoYGrabar() {
        val tienePermiso = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED

        if (tienePermiso) {
            comenzarGrabacion()
        } else {
            pedirPermisoMic.launch(Manifest.permission.RECORD_AUDIO)
        }
    }

    private fun comenzarGrabacion() {
        rutaArchivoActual = ayudante.crearRutaParaAudio()

        grabador = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        grabador?.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
            setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
            setOutputFile(rutaArchivoActual)
            prepare()
            start()
        }

        estaGrabando = true
        actualizarUI()
    }

    private fun detenerGrabacion() {
        grabador?.apply {
            stop()
            release()
        }
        grabador = null
        estaGrabando = false
        actualizarUI()
        Toast.makeText(this, "Audio guardado correctamente", Toast.LENGTH_SHORT).show()
    }

    private fun actualizarUI() {
        val estado: TextView = findViewById(R.id.tv_estado_audio)
        val textoBoton: TextView = findViewById(R.id.tv_texto_boton_audio)

        if (estaGrabando) {
            estado.text = "Grabando..."
            textoBoton.text = "Detener grabación"
        } else {
            estado.text = "Listo para grabar"
            textoBoton.text = "Iniciar grabación"
        }
    }

    override fun onStop() {
        super.onStop()
        if (estaGrabando) {
            detenerGrabacion()
        }
    }
}