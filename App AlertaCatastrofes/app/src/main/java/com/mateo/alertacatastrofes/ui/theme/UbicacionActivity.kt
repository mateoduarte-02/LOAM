package com.mateo.alertacatastrofes.ui

import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.os.Bundle
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.mateo.alertacatastrofes.R
import com.mateo.alertacatastrofes.datos.AyudanteUbicacion
import com.mateo.alertacatastrofes.datos.UbicacionRepository
import com.mateo.alertacatastrofes.modelo.Ubicacion
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class UbicacionActivity : AppCompatActivity() {

    private lateinit var mapView: MapView
    private lateinit var ayudanteUbicacion: AyudanteUbicacion
    private val repository = UbicacionRepository()

    private var latitudActual: Double = 0.0
    private var longitudActual: Double = 0.0
    private var direccionActual: String = ""

    private val pedirPermisoUbicacion = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { concedido ->
        if (concedido) {
            buscarUbicacion()
        } else {
            mostrarError("Se necesita permiso de ubicación para continuar")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val preferencias = getSharedPreferences("osmdroid", MODE_PRIVATE)
        Configuration.getInstance().load(this, preferencias)
        Configuration.getInstance().userAgentValue = "AlertaCatastrofes/1.0 (mateo@example.com)"

        setContentView(R.layout.activity_ubicacion)

        ayudanteUbicacion = AyudanteUbicacion(this)

        mapView = findViewById(R.id.mapView)
        mapView.setTileSource(TileSourceFactory.MAPNIK)
        mapView.setMultiTouchControls(true)
        mapView.controller.setZoom(16.0)

        val botonRegistrar: LinearLayout = findViewById(R.id.btn_registrar)
        botonRegistrar.setOnClickListener { registrarUbicacion() }

        verificarPermisoYBuscar()
    }

    private fun verificarPermisoYBuscar() {
        val tienePermiso = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED

        if (tienePermiso) {
            buscarUbicacion()
        } else {
            pedirPermisoUbicacion.launch(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    private fun buscarUbicacion() {
        if (!ayudanteUbicacion.ubicacionEstaActivada()) {
            mostrarError("La ubicación está desactivada. Activala para continuar.")
            return
        }

        ocultarError()

        // Intentar mostrar la última ubicación conocida de inmediato
        ayudanteUbicacion.obtenerUltimaUbicacionConocida()?.let {
            mostrarUbicacionEnMapa(it)
        }

        ayudanteUbicacion.obtenerUbicacionActual(
            onUbicacionObtenida = { location -> mostrarUbicacionEnMapa(location) },
            onError = { 
                if (latitudActual == 0.0) {
                    mostrarError("No se pudo obtener la ubicación")
                }
            }
        )
    }

    private fun mostrarUbicacionEnMapa(location: Location) {
        latitudActual = location.latitude
        longitudActual = location.longitude

        val punto = GeoPoint(latitudActual, longitudActual)
        mapView.controller.setCenter(punto)

        mapView.overlays.clear()
        val marcador = Marker(mapView)
        marcador.position = punto
        marcador.setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
        marcador.title = "Estás acá"
        mapView.overlays.add(marcador)
        mapView.invalidate()

        direccionActual = ayudanteUbicacion.obtenerDireccion(latitudActual, longitudActual)
        findViewById<TextView>(R.id.tv_direccion).text = direccionActual
    }

    private fun mostrarError(mensaje: String) {
        val textoError: TextView = findViewById(R.id.tv_error)
        textoError.text = mensaje
        textoError.visibility = android.view.View.VISIBLE
        findViewById<TextView>(R.id.tv_direccion).text = "Ubicación no disponible"
    }

    private fun ocultarError() {
        findViewById<TextView>(R.id.tv_error).visibility = android.view.View.GONE
    }

    private fun registrarUbicacion() {
        if (latitudActual == 0.0 && longitudActual == 0.0) {
            Toast.makeText(this, "Todavía no se obtuvo tu ubicación", Toast.LENGTH_SHORT).show()
            return
        }

        val referencia = findViewById<EditText>(R.id.et_referencia).text.toString()
        val fecha = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault()).format(Date())

        val ubicacion = Ubicacion(
            latitud = latitudActual,
            longitud = longitudActual,
            direccion = direccionActual,
            referencia = referencia,
            fecha = fecha
        )

        repository.guardarUbicacion(
            ubicacion,
            onExito = { Toast.makeText(this, "Ubicación registrada correctamente", Toast.LENGTH_SHORT).show() },
            onError = { Toast.makeText(this, "Error al guardar la ubicación", Toast.LENGTH_SHORT).show() }
        )
    }

    override fun onResume() {
        super.onResume()
        mapView.onResume()
    }

    override fun onPause() {
        super.onPause()
        mapView.onPause()
    }
}