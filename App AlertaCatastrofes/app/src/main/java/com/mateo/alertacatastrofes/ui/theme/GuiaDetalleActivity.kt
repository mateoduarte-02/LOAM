package com.mateo.alertacatastrofes.ui

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.bumptech.glide.Glide
import com.mateo.alertacatastrofes.R
import com.mateo.alertacatastrofes.datos.RepositorioGuia

class GuiaDetalleActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_guia_detalle)

        val indice = intent.getIntExtra("indice", 0)
        val catastrofe = RepositorioGuia.obtenerCatastrofes()[indice]

        val imagen: ImageView = findViewById(R.id.iv_imagen_catastrofe)
        Glide.with(this)
            .load(catastrofe.urlImagen)
            .centerCrop()
            .into(imagen)

        findViewById<TextView>(R.id.tv_nombre_catastrofe).text =
            "${catastrofe.emoji} ${catastrofe.nombre}"

        val textoConsejos = catastrofe.consejos.joinToString("\n\n") { "•  $it" }
        findViewById<TextView>(R.id.tv_consejos).text = textoConsejos

        findViewById<LinearLayout>(R.id.btn_ver_video).setOnClickListener {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(catastrofe.urlVideo))
            startActivity(intent)
        }
    }
}