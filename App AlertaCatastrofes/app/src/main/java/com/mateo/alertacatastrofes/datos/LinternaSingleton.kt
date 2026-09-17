package com.mateo.alertacatastrofes.datos

import android.content.Context

object LinternaSingleton {
    private var instancia: AyudanteLinterna? = null

    fun obtener(contexto: Context): AyudanteLinterna {
        if (instancia == null) {
            instancia = AyudanteLinterna(contexto.applicationContext)
        }
        return instancia!!
    }
}