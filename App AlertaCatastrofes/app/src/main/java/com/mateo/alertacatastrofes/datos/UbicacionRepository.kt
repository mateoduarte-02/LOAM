package com.mateo.alertacatastrofes.datos

import com.google.firebase.firestore.FirebaseFirestore
import com.mateo.alertacatastrofes.modelo.Ubicacion

class UbicacionRepository {

    private val db = FirebaseFirestore.getInstance()

    fun guardarUbicacion(ubicacion: Ubicacion, onExito: () -> Unit, onError: () -> Unit) {
        db.collection("ubicaciones")
            .add(ubicacion)
            .addOnSuccessListener { onExito() }
            .addOnFailureListener { onError() }
    }
}