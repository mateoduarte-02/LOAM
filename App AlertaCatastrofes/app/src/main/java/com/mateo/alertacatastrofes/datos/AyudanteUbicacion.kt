package com.mateo.alertacatastrofes.datos

import android.content.Context
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import java.util.Locale

class AyudanteUbicacion(private val contexto: Context) {

    private val locationManager = contexto.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    fun ubicacionEstaActivada(): Boolean {
        val gpsActivado = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val redActivada = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        return gpsActivado || redActivada
    }

    fun obtenerUltimaUbicacionConocida(): Location? {
        return try {
            val gpsLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            val networkLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)

            if (gpsLocation != null && networkLocation != null) {
                if (gpsLocation.time > networkLocation.time) gpsLocation else networkLocation
            } else {
                gpsLocation ?: networkLocation
            }
        } catch (e: SecurityException) {
            null
        }
    }

    fun obtenerUbicacionActual(onUbicacionObtenida: (Location) -> Unit, onError: () -> Unit) {
        if (!ubicacionEstaActivada()) {
            onError()
            return
        }

        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                onUbicacionObtenida(location)
                locationManager.removeUpdates(this)
            }

            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
            override fun onProviderEnabled(provider: String) {}
            override fun onProviderDisabled(provider: String) {}
        }

        try {
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 0L, 0f, listener)
            }
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0L, 0f, listener)
            }
        } catch (e: SecurityException) {
            onError()
        }
    }

    fun obtenerDireccion(latitud: Double, longitud: Double): String {
        return try {
            val geocoder = Geocoder(contexto, Locale.getDefault())
            @Suppress("DEPRECATION")
            val resultados = geocoder.getFromLocation(latitud, longitud, 1)
            if (!resultados.isNullOrEmpty()) {
                resultados[0].getAddressLine(0) ?: "Dirección no disponible"
            } else {
                "Dirección no disponible"
            }
        } catch (e: Exception) {
            "No se pudo obtener la dirección"
        }
    }
}