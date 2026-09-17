package com.mateo.alertacatastrofes.ui

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.CheckBox
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.mateo.alertacatastrofes.R
import com.mateo.alertacatastrofes.datos.AyudanteMultimedia
import com.mateo.alertacatastrofes.datos.AyudanteZombie
import com.mateo.alertacatastrofes.datos.PlanDeEscape

class ZombieActivity : AppCompatActivity() {

    private lateinit var ayudanteZombie: AyudanteZombie
    private val ayudanteMultimedia = AyudanteMultimedia(this)
    private var grabador: MediaRecorder? = null
    private var grabando = false

    private val pedirPermisoMic = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { concedido ->
        if (concedido) {
            iniciarGrabacionZombie()
        } else {
            Toast.makeText(this, "Se necesita el micrófono para escuchar al zombie", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_zombie)

        ayudanteZombie = AyudanteZombie(this)

        val dias = ayudanteZombie.obtenerDiasEnBunker()
        findViewById<TextView>(R.id.tv_dias_bunker).text = "Día $dias"
        findViewById<TextView>(R.id.tv_mensaje_bunker).text = ayudanteZombie.obtenerMensajeSegunDias(dias)

        val contenedorChecklist: LinearLayout = findViewById(R.id.contenedor_checklist)
        for (item in PlanDeEscape.obtenerItems()) {
            val checkbox = CheckBox(this)
            checkbox.text = item
            checkbox.textSize = 14f
            contenedorChecklist.addView(checkbox)
        }

        val etTexto: EditText = findViewById(R.id.et_texto_traducir)
        val tvResultado: TextView = findViewById(R.id.tv_resultado_traduccion)
        findViewById<LinearLayout>(R.id.btn_traducir).setOnClickListener {
            val texto = etTexto.text.toString()
            tvResultado.text = ayudanteZombie.traducirAGruñidos(texto)
            findViewById<TextView>(R.id.tv_traduccion_final).text = ""
        }

        findViewById<LinearLayout>(R.id.btn_grabar_zombie).setOnClickListener {
            if (grabando) {
                detenerYTraducir()
            } else {
                verificarPermisoYGrabar()
            }
        }
    }

    private fun verificarPermisoYGrabar() {
        val tienePermiso = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED

        if (tienePermiso) {
            iniciarGrabacionZombie()
        } else {
            pedirPermisoMic.launch(Manifest.permission.RECORD_AUDIO)
        }
    }

    private fun iniciarGrabacionZombie() {
        val ruta = ayudanteMultimedia.crearRutaParaAudio()

        grabador = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        try {
            grabador?.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
                setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
                setOutputFile(ruta)
                prepare()
                start()
            }
            grabando = true
            findViewById<TextView>(R.id.tv_texto_boton_zombie).text = "🔴  Escuchando al zombie... (tocá para detener)"
            findViewById<TextView>(R.id.tv_resultado_traduccion).text = ""
            findViewById<TextView>(R.id.tv_traduccion_final).text = ""
        } catch (e: Exception) {
            Toast.makeText(this, "No se pudo grabar", Toast.LENGTH_SHORT).show()
            grabando = false
        }
    }

    private fun detenerYTraducir() {
        try {
            grabador?.stop()
        } catch (e: Exception) { }
        grabador?.release()
        grabador = null
        grabando = false

        findViewById<TextView>(R.id.tv_texto_boton_zombie).text = "🎙️  Grabar al zombie"
        findViewById<TextView>(R.id.tv_resultado_traduccion).text = "Analizando gruñidos..."

        Handler(Looper.getMainLooper()).postDelayed({
            val (gruñido, traduccion) = ayudanteZombie.generarTraduccionDeAudio()
            findViewById<TextView>(R.id.tv_resultado_traduccion).text = gruñido
            findViewById<TextView>(R.id.tv_traduccion_final).text = traduccion
        }, 1200)
    }

    override fun onStop() {
        super.onStop()
        if (grabando) {
            try {
                grabador?.stop()
            } catch (e: Exception) { }
            grabador?.release()
            grabador = null
            grabando = false
        }
    }
}