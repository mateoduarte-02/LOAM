package com.mateo.alertacatastrofes.datos

import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.mateo.alertacatastrofes.modelo.NumeroEmergencia

class EmergencyRepository {

    private val db = FirebaseFirestore.getInstance()

    fun escucharNumeros(onDataChanged: (List<NumeroEmergencia>) -> Unit) {
        db.collection("emergency_numbers")
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.e("EmergencyRepository", "Error al escuchar Firestore", error)
                    onDataChanged(emptyList())
                    return@addSnapshotListener
                }
                if (snapshot == null) {
                    Log.d("EmergencyRepository", "Snapshot nulo")
                    onDataChanged(emptyList())
                    return@addSnapshotListener
                }

                Log.d("EmergencyRepository", "Documentos recibidos: ${snapshot.documents.size}")

                val lista = snapshot.documents.mapNotNull { documento ->
                    documento.toObject(NumeroEmergencia::class.java)
                }
                Log.d("EmergencyRepository", "Lista final: $lista")
                onDataChanged(lista)
            }
    }
}