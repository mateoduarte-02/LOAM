package com.mateo.alertacatastrofes.ui

import android.os.Bundle
import android.view.Gravity
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.mateo.alertacatastrofes.R
import com.mateo.alertacatastrofes.datos.ChatRepository
import com.mateo.alertacatastrofes.modelo.ChatMensaje

class ChatActivity : AppCompatActivity() {

    private val repository = ChatRepository()
    private lateinit var contenedorMensajes: LinearLayout
    private lateinit var scrollChat: ScrollView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_chat)

        contenedorMensajes = findViewById(R.id.contenedor_mensajes)
        scrollChat = findViewById(R.id.scroll_chat)
        val inputMensaje: EditText = findViewById(R.id.et_mensaje)
        val botonEnviar: LinearLayout = findViewById(R.id.btn_enviar)

        botonEnviar.setOnClickListener {
            val texto = inputMensaje.text.toString().trim()
            if (texto.isNotEmpty()) {
                repository.enviarMensaje(texto)
                inputMensaje.text.clear()
            }
        }

        repository.escucharMensajes { lista ->
            mostrarMensajes(lista)
        }
    }

    private fun mostrarMensajes(lista: List<ChatMensaje>) {
        contenedorMensajes.removeAllViews()

        for (mensaje in lista) {
            val esUsuario = mensaje.autor == "usuario"

            val fila = LinearLayout(this)
            fila.orientation = LinearLayout.HORIZONTAL
            fila.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = (8 * resources.displayMetrics.density).toInt() }
            fila.gravity = if (esUsuario) Gravity.END else Gravity.START

            val burbuja = TextView(this)
            burbuja.text = mensaje.texto
            burbuja.setPadding(32, 24, 32, 24)
            burbuja.setBackgroundResource(
                if (esUsuario) R.drawable.burbuja_usuario else R.drawable.burbuja_asistente
            )
            burbuja.setTextColor(
                ContextCompat.getColor(
                    this,
                    if (esUsuario) android.R.color.white else R.color.texto_principal
                )
            )

            val parametrosBurbuja = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            burbuja.layoutParams = parametrosBurbuja

            fila.addView(burbuja)
            contenedorMensajes.addView(fila)
        }

        // Bajar el scroll automáticamente al último mensaje
        scrollChat.post { scrollChat.fullScroll(ScrollView.FOCUS_DOWN) }
    }
}