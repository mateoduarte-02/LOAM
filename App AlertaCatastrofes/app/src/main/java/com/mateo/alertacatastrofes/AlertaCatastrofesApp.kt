package com.mateo.alertacatastrofes

import android.app.Activity
import android.app.Application
import android.os.Bundle
import com.mateo.alertacatastrofes.datos.LinternaSingleton

class AlertaCatastrofesApp : Application() {

    private var actividadesActivas = 0

    override fun onCreate() {
        super.onCreate()
        registerActivityLifecycleCallbacks(object : ActivityLifecycleCallbacks {
            override fun onActivityStarted(activity: Activity) {
                actividadesActivas++
            }

            override fun onActivityStopped(activity: Activity) {
                actividadesActivas--
                if (actividadesActivas <= 0) {
                    // La app entera pasó a segundo plano (no es solo cambio de pantalla interna)
                    val linterna = LinternaSingleton.obtener(applicationContext)
                    if (linterna.estaEncendida) {
                        linterna.apagar()
                    }
                }
            }

            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityResumed(activity: Activity) {}
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        })
    }
}