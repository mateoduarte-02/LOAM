package com.mateo.alertacatastrofes.datos

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.mateo.alertacatastrofes.modelo.ChatMensaje

class ChatRepository {

    private val db = FirebaseFirestore.getInstance()

    fun escucharMensajes(onDataChanged: (List<ChatMensaje>) -> Unit) {
        db.collection("chat")
            .orderBy("fecha", Query.Direction.ASCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null || snapshot == null) {
                    onDataChanged(emptyList())
                    return@addSnapshotListener
                }
                val lista = snapshot.documents.mapNotNull { it.toObject(ChatMensaje::class.java) }
                onDataChanged(lista)
            }
    }

    fun enviarMensaje(texto: String) {
        val mensaje = ChatMensaje(
            autor = "usuario",
            texto = texto,
            fecha = System.currentTimeMillis()
        )
        db.collection("chat").add(mensaje)
    }
}