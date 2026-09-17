package com.mateo.alertacatastrofes.datos

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Locale

class AyudanteMultimedia(private val contexto: Context) {

    fun crearUriParaVideo(): Uri {
        val carpeta = File(contexto.getExternalFilesDir("Movies"), "")
        if (!carpeta.exists()) carpeta.mkdirs()

        val nombreArchivo = "VIDEO_${timestamp()}.mp4"
        val archivo = File(carpeta, nombreArchivo)

        return FileProvider.getUriForFile(
            contexto,
            "${contexto.packageName}.fileprovider",
            archivo
        )
    }

    fun crearRutaParaAudio(): String {
        val carpeta = contexto.getExternalFilesDir("Music")
        if (carpeta != null && !carpeta.exists()) carpeta.mkdirs()

        val nombreArchivo = "AUDIO_${timestamp()}.3gp"
        return File(carpeta, nombreArchivo).absolutePath
    }

    private fun timestamp(): String {
        return SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(java.util.Date())
    }
}