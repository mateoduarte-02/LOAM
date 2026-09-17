package com.mateo.alertacatastrofes.datos

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager

class AyudanteLinterna(contexto: Context) {

    private val administradorCamara = contexto.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private val idCamara: String? = administradorCamara.cameraIdList.firstOrNull {
        administradorCamara.getCameraCharacteristics(it)
            .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
    }

    var estaEncendida = false
        private set

    fun encender() {
        idCamara?.let {
            administradorCamara.setTorchMode(it, true)
            estaEncendida = true
        }
    }

    fun apagar() {
        idCamara?.let {
            administradorCamara.setTorchMode(it, false)
            estaEncendida = false
        }
    }
}