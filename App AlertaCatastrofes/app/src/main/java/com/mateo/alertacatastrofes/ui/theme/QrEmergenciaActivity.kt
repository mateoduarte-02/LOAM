package com.mateo.alertacatastrofes.ui

import android.graphics.Bitmap
import android.graphics.Color
import android.os.Bundle
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import com.mateo.alertacatastrofes.R

class QrEmergenciaActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_qr_emergencia)

        val etNombre: EditText = findViewById(R.id.et_nombre)
        val etTipoSangre: EditText = findViewById(R.id.et_tipo_sangre)
        val etContacto: EditText = findViewById(R.id.et_contacto)
        val etAlergias: EditText = findViewById(R.id.et_alergias)
        val ivQr: ImageView = findViewById(R.id.iv_qr)

        findViewById<LinearLayout>(R.id.btn_generar_qr).setOnClickListener {
            val nombre = etNombre.text.toString().trim()
            val tipoSangre = etTipoSangre.text.toString().trim()
            val contacto = etContacto.text.toString().trim()
            val alergias = etAlergias.text.toString().trim()

            if (nombre.isEmpty() || contacto.isEmpty()) {
                Toast.makeText(this, "Completá al menos nombre y contacto", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val textoQr = buildString {
                append("INFO DE EMERGENCIA\n")
                append("Nombre: $nombre\n")
                append("Tipo de sangre: ${tipoSangre.ifEmpty { "No especificado" }}\n")
                append("Contacto de emergencia: $contacto\n")
                if (alergias.isNotEmpty()) append("Alergias/condiciones: $alergias")
            }

            val bitmap = generarBitmapQr(textoQr)
            if (bitmap != null) {
                ivQr.setImageBitmap(bitmap)
                ivQr.visibility = android.view.View.VISIBLE
            }
        }
    }

    private fun generarBitmapQr(texto: String): Bitmap? {
        return try {
            val tamano = 512
            val writer = QRCodeWriter()
            val matrizBits = writer.encode(texto, BarcodeFormat.QR_CODE, tamano, tamano)

            val bitmap = Bitmap.createBitmap(tamano, tamano, Bitmap.Config.RGB_565)
            for (x in 0 until tamano) {
                for (y in 0 until tamano) {
                    bitmap.setPixel(x, y, if (matrizBits[x, y]) Color.BLACK else Color.WHITE)
                }
            }
            bitmap
        } catch (e: Exception) {
            Toast.makeText(this, "Error al generar el código QR", Toast.LENGTH_SHORT).show()
            null
        }
    }
}