package com.mateo.alertacatastrofes

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.speech.RecognizerIntent
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.mateo.alertacatastrofes.datos.AyudanteBateria
import com.mateo.alertacatastrofes.datos.AyudanteLinterna
import com.mateo.alertacatastrofes.datos.AyudanteMultimedia
import com.mateo.alertacatastrofes.datos.AyudanteVoz
import com.mateo.alertacatastrofes.datos.CatastrofeRepository
import com.mateo.alertacatastrofes.datos.ComandoVoz
import com.mateo.alertacatastrofes.datos.LinternaSingleton
import com.mateo.alertacatastrofes.datos.ServicioClima
import com.mateo.alertacatastrofes.ui.AlarmaActivity
import com.mateo.alertacatastrofes.ui.BrujulaActivity
import com.mateo.alertacatastrofes.ui.ChatActivity
import com.mateo.alertacatastrofes.ui.GrabarAudioActivity
import com.mateo.alertacatastrofes.ui.GuiaDetalleActivity
import com.mateo.alertacatastrofes.ui.NumerosEmergenciaActivity
import com.mateo.alertacatastrofes.ui.QrEmergenciaActivity
import com.mateo.alertacatastrofes.ui.UbicacionActivity
import com.mateo.alertacatastrofes.ui.ZombieActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.Locale

class MainActivity : AppCompatActivity() {

    private val servicioClima = ServicioClima()
    private val ayudanteMultimedia = AyudanteMultimedia(this)
    private lateinit var ayudanteBateria: AyudanteBateria
    private lateinit var catastrofeRepository: CatastrofeRepository
    private lateinit var ayudanteLinterna: AyudanteLinterna
    private lateinit var tarjetaLinterna: android.widget.FrameLayout
    private lateinit var textoEstadoLinterna: TextView
    private lateinit var textoResultadoVoz: TextView
    private lateinit var textoBateriaPorcentaje: TextView
    private lateinit var textoBateriaRestante: TextView
    private lateinit var textoBateriaHora: TextView
    private lateinit var uriVideoActual: Uri

    private val lanzadorCamara = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { resultado ->
        if (resultado.resultCode == RESULT_OK) {
            Toast.makeText(this, "Video guardado correctamente", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(this, "Grabación cancelada", Toast.LENGTH_SHORT).show()
        }
    }

    private val lanzadorReconocimientoVoz = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { resultado ->
        if (resultado.resultCode == RESULT_OK) {
            val resultados = resultado.data
                ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            val textoReconocido = resultados?.firstOrNull() ?: ""

            if (textoReconocido.isNotEmpty()) {
                textoResultadoVoz.text = "Escuché: \"$textoReconocido\""
                procesarComandoVoz(textoReconocido)
            } else {
                textoResultadoVoz.text = "No entendí, probá de nuevo"
            }
        } else {
            textoResultadoVoz.text = ""
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        ayudanteLinterna = LinternaSingleton.obtener(this)
        ayudanteBateria = AyudanteBateria(this)
        catastrofeRepository = CatastrofeRepository(this)

        val tarjetaEmergencias: LinearLayout = findViewById(R.id.btn_emergencias)
        val tarjetaUbicacion: LinearLayout = findViewById(R.id.btn_ubicacion)
        val tarjetaVideo: LinearLayout = findViewById(R.id.btn_video_home)
        val tarjetaAudio: LinearLayout = findViewById(R.id.btn_audio_home)
        val tarjetaChat: LinearLayout = findViewById(R.id.btn_chat)
        val tarjetaVoz: LinearLayout = findViewById(R.id.btn_voz)
        val tarjetaGuiaTerremoto: LinearLayout = findViewById(R.id.btn_guia_terremoto)
        val tarjetaGuiaInundacion: LinearLayout = findViewById(R.id.btn_guia_inundacion)
        val tarjetaGuiaIncendio: LinearLayout = findViewById(R.id.btn_guia_incendio)
        val tarjetaSimular: LinearLayout = findViewById(R.id.btn_simular_catastrofe)
        val tarjetaBrujula: LinearLayout = findViewById(R.id.btn_brujula)
        val tarjetaQr: LinearLayout = findViewById(R.id.btn_qr)
        val textoClima: TextView = findViewById(R.id.tv_clima)

        tarjetaLinterna = findViewById(R.id.btn_linterna)
        textoEstadoLinterna = findViewById(R.id.tv_estado_linterna_home)
        textoResultadoVoz = findViewById(R.id.tv_resultado_voz)
        textoBateriaPorcentaje = findViewById(R.id.tv_bateria_porcentaje)
        textoBateriaRestante = findViewById(R.id.tv_bateria_restante)
        textoBateriaHora = findViewById(R.id.tv_bateria_hora)

        tarjetaLinterna.setOnClickListener {
            if (ayudanteLinterna.estaEncendida) {
                ayudanteLinterna.apagar()
            } else {
                ayudanteLinterna.encender()
            }
            actualizarUILinterna()
        }

        tarjetaEmergencias.setOnClickListener {
            startActivity(Intent(this, NumerosEmergenciaActivity::class.java))
        }

        tarjetaUbicacion.setOnClickListener {
            startActivity(Intent(this, UbicacionActivity::class.java))
        }

        tarjetaVideo.setOnClickListener {
            uriVideoActual = ayudanteMultimedia.crearUriParaVideo()
            val intent = Intent(MediaStore.ACTION_VIDEO_CAPTURE).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, uriVideoActual)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            }
            lanzadorCamara.launch(intent)
        }

        tarjetaAudio.setOnClickListener {
            startActivity(Intent(this, GrabarAudioActivity::class.java))
        }

        tarjetaChat.setOnClickListener {
            startActivity(Intent(this, ChatActivity::class.java))
        }

        tarjetaVoz.setOnClickListener {
            iniciarReconocimientoVoz()
        }

        // Guía de acción: acceso directo a cada catástrofe (índices según RepositorioGuia)
        tarjetaGuiaTerremoto.setOnClickListener {
            abrirGuiaDetalle(0)
        }
        tarjetaGuiaInundacion.setOnClickListener {
            abrirGuiaDetalle(1)
        }
        tarjetaGuiaIncendio.setOnClickListener {
            abrirGuiaDetalle(2)
        }

        tarjetaSimular.setOnClickListener {
            catastrofeRepository.simularEventoDePrueba()
        }

        tarjetaBrujula.setOnClickListener {
            startActivity(Intent(this, BrujulaActivity::class.java))
        }

        tarjetaQr.setOnClickListener {
            startActivity(Intent(this, QrEmergenciaActivity::class.java))
        }

        lifecycleScope.launch {
            val resultado = withContext(Dispatchers.IO) {
                servicioClima.obtenerClimaActual()
            }
            textoClima.text = resultado
        }

        catastrofeRepository.escucharNuevosEventos { evento ->
            val detalle = "${evento.tipo}\n${evento.fecha} - ${evento.hora}\n${evento.ubicacion}"
            val intent = Intent(this, AlarmaActivity::class.java)
            intent.putExtra("detalle", detalle)
            startActivity(intent)
        }

        findViewById<LinearLayout>(R.id.btn_zombie).setOnClickListener {
            startActivity(Intent(this, ZombieActivity::class.java))
        }
    }

    private fun abrirGuiaDetalle(indice: Int) {
        val intent = Intent(this, GuiaDetalleActivity::class.java)
        intent.putExtra("indice", indice)
        startActivity(intent)
    }

    private fun iniciarReconocimientoVoz() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale("es", "AR"))
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Decí un comando...")
        }

        try {
            lanzadorReconocimientoVoz.launch(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "El reconocimiento de voz no está disponible en este dispositivo", Toast.LENGTH_SHORT).show()
        }
    }

    private fun procesarComandoVoz(texto: String) {
        when (AyudanteVoz.interpretar(texto)) {
            ComandoVoz.LINTERNA -> {
                if (ayudanteLinterna.estaEncendida) ayudanteLinterna.apagar() else ayudanteLinterna.encender()
                actualizarUILinterna()
            }
            ComandoVoz.EMERGENCIA -> startActivity(Intent(this, NumerosEmergenciaActivity::class.java))
            ComandoVoz.BATERIA -> Toast.makeText(this, "El estado de la batería ya se muestra en el inicio", Toast.LENGTH_SHORT).show()
            ComandoVoz.UBICACION -> startActivity(Intent(this, UbicacionActivity::class.java))
            ComandoVoz.CHAT -> startActivity(Intent(this, ChatActivity::class.java))
            ComandoVoz.GUIA -> abrirGuiaDetalle(0)
            ComandoVoz.CLIMA -> Toast.makeText(this, "El clima ya se muestra arriba de todo", Toast.LENGTH_SHORT).show()
            ComandoVoz.VIDEO -> {
                uriVideoActual = ayudanteMultimedia.crearUriParaVideo()
                val intent = Intent(MediaStore.ACTION_VIDEO_CAPTURE).apply {
                    putExtra(MediaStore.EXTRA_OUTPUT, uriVideoActual)
                    addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                }
                lanzadorCamara.launch(intent)
            }
            ComandoVoz.AUDIO -> startActivity(Intent(this, GrabarAudioActivity::class.java))
            ComandoVoz.DESCONOCIDO -> Toast.makeText(this, "No reconocí ese comando", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onResume() {
        super.onResume()
        actualizarUILinterna()
        actualizarBateria()
    }

    private fun actualizarUILinterna() {
        if (ayudanteLinterna.estaEncendida) {
            tarjetaLinterna.setBackgroundResource(R.drawable.circulo_linterna_encendida)
            textoEstadoLinterna.text = "Encendida — tocá para apagar"
            textoEstadoLinterna.setTextColor(0xFFF5A623.toInt())
        } else {
            tarjetaLinterna.setBackgroundResource(R.drawable.circulo_linterna_apagada)
            textoEstadoLinterna.text = "Tocá para activar el flash"
            textoEstadoLinterna.setTextColor(0xFF5F6E78.toInt())
        }
    }

    private fun actualizarBateria() {
        val porcentaje = ayudanteBateria.obtenerPorcentaje()
        val minutosRestantes = ayudanteBateria.estimarTiempoRestanteMinutos(porcentaje)
        val horaSinBateria = ayudanteBateria.calcularHoraSinBateria(minutosRestantes)

        val horas = minutosRestantes / 60
        val minutos = minutosRestantes % 60

        textoBateriaPorcentaje.text = "$porcentaje%"
        textoBateriaRestante.text = "Tiempo estimado restante: ${horas}h ${minutos}min"
        textoBateriaHora.text = "Te quedarías sin batería aprox. a las $horaSinBateria"
    }
}