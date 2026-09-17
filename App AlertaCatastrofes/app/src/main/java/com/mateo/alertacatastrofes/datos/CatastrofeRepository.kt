package com.mateo.alertacatastrofes.datos

import android.content.Context
import com.google.firebase.firestore.DocumentChange
import com.google.firebase.firestore.FirebaseFirestore
import com.mateo.alertacatastrofes.modelo.EventoCatastrofe

class CatastrofeRepository(contexto: Context) {

    private val db = FirebaseFirestore.getInstance()
    private val preferencias = contexto.getSharedPreferences("alertas_prefs", Context.MODE_PRIVATE)

    private fun obtenerUltimoVisto(): Long {
        // La primera vez que se usa, se marca "ahora" como punto de partida
        val guardado = preferencias.getLong("ultimo_timestamp_visto", -1L)
        return if (guardado == -1L) {
            val ahora = System.currentTimeMillis()
            preferencias.edit().putLong("ultimo_timestamp_visto", ahora).apply()
            ahora
        } else {
            guardado
        }
    }

    private fun guardarUltimoVisto(timestamp: Long) {
        preferencias.edit().putLong("ultimo_timestamp_visto", timestamp).apply()
    }

    fun escucharNuevosEventos(onEventoNuevo: (EventoCatastrofe) -> Unit) {
        val ultimoVisto = obtenerUltimoVisto()

        db.collection("catastrofes")
            .addSnapshotListener { snapshot, error ->
                if (error != null || snapshot == null) return@addSnapshotListener

                for (cambio in snapshot.documentChanges) {
                    if (cambio.type == DocumentChange.Type.ADDED) {
                        val evento = cambio.document.toObject(EventoCatastrofe::class.java)
                        if (evento.timestamp > ultimoVisto) {
                            guardarUltimoVisto(evento.timestamp)
                            onEventoNuevo(evento)
                        }
                    }
                }
            }
    }

    fun simularEventoDePrueba() {
        val evento = EventoCatastrofe(
            tipo = "Terremoto (simulado)",
            fecha = "04/09/2026",
            hora = "Ahora",
            ubicacion = "Prueba desde la app",
            timestamp = System.currentTimeMillis()
        )
        db.collection("catastrofes").add(evento)
    }
}