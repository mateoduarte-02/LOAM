package com.mateo.alertacatastrofes.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.mateo.alertacatastrofes.R
import com.mateo.alertacatastrofes.datos.EmergencyRepository
import com.mateo.alertacatastrofes.modelo.NumeroEmergencia

class NumerosEmergenciaActivity : AppCompatActivity() {

    private val repository = EmergencyRepository()
    private lateinit var contenedor: LinearLayout
    private var numeroPendienteDeLlamar: String? = null

    private val pedirPermisoLlamar = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { concedido ->
        if (concedido) {
            numeroPendienteDeLlamar?.let { realizarLlamada(it) }
        } else {
            Toast.makeText(this, "Se necesita permiso para llamar", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_numeros_emergencia)

        contenedor = findViewById(R.id.contenedor)

        repository.escucharNumeros { lista ->
            mostrarNumeros(lista)
        }
    }

    private fun mostrarNumeros(lista: List<NumeroEmergencia>) {
        contenedor.removeAllViews()

        val paddingPx = (16 * resources.displayMetrics.density).toInt()
        val margenPx = (8 * resources.displayMetrics.density).toInt()

        for (item in lista) {
            val tarjeta = LinearLayout(this)
            tarjeta.orientation = LinearLayout.HORIZONTAL
            tarjeta.setPadding(paddingPx, paddingPx, paddingPx, paddingPx)
            tarjeta.setBackgroundResource(R.drawable.fondo_tarjeta)
            tarjeta.elevation = 2f

            val parametrosTarjeta = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            parametrosTarjeta.setMargins(0, 0, 0, margenPx)
            tarjeta.layoutParams = parametrosTarjeta

            val columnaTexto = LinearLayout(this)
            columnaTexto.orientation = LinearLayout.VERTICAL
            columnaTexto.layoutParams = LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f
            )

            val nombre = TextView(this)
            nombre.text = item.name
            nombre.textSize = 16f
            nombre.setTextColor(ContextCompat.getColor(this, R.color.texto_principal))
            nombre.setTypeface(nombre.typeface, android.graphics.Typeface.BOLD)

            val numero = TextView(this)
            numero.text = item.number
            numero.textSize = 14f
            numero.setTextColor(ContextCompat.getColor(this, R.color.texto_secundario))

            columnaTexto.addView(nombre)
            columnaTexto.addView(numero)

            val botonLlamar = Button(this)
            botonLlamar.text = "Llamar"
            botonLlamar.setBackgroundColor(ContextCompat.getColor(this, R.color.primario))
            botonLlamar.setTextColor(ContextCompat.getColor(this, android.R.color.white))
            botonLlamar.setOnClickListener { intentarLlamar(item.number) }

            tarjeta.addView(columnaTexto)
            tarjeta.addView(botonLlamar)
            contenedor.addView(tarjeta)
        }
    }

    private fun intentarLlamar(numero: String) {
        numeroPendienteDeLlamar = numero
        val tienePermiso = ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) ==
                PackageManager.PERMISSION_GRANTED

        if (tienePermiso) {
            realizarLlamada(numero)
        } else {
            pedirPermisoLlamar.launch(Manifest.permission.CALL_PHONE)
        }
    }

    private fun realizarLlamada(numero: String) {
        val intent = Intent(Intent.ACTION_CALL)
        intent.data = Uri.parse("tel:$numero")
        startActivity(intent)
    }
}