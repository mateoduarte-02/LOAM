package com.mateo.alertacatastrofes.datos

import com.mateo.alertacatastrofes.modelo.Catastrofe

object RepositorioGuia {

    fun obtenerCatastrofes(): List<Catastrofe> {
        return listOf(
            Catastrofe(
                nombre = "Terremoto",
                emoji = "🌍",
                urlImagen = "https://commons.wikimedia.org/wiki/Special:FilePath/Haiti_earthquake_damage.jpg",
                consejos = listOf(
                    "Agachate, cubrite la cabeza y sostenete de algo firme (técnica 'Agacharse, Cubrirse, Sujetarse').",
                    "Alejate de ventanas, espejos y objetos que puedan caerse.",
                    "Si estás en la calle, alejate de edificios, postes y cables.",
                    "No uses ascensores. Una vez que termine el movimiento, salí por las escaleras.",
                    "Después del sismo, revisá si hay olor a gas o daños estructurales antes de volver a entrar."
                ),
                urlVideo = "https://youtu.be/6Im9ezEwFdw"
            ),
            Catastrofe(
                nombre = "Inundación",
                emoji = "🌊",
                urlImagen = "https://commons.wikimedia.org/wiki/Special:FilePath/TS_Allison_Texas_flooding.jpg",
                consejos = listOf(
                    "Dirigite a un lugar alto, lejos del agua en movimiento.",
                    "No camines ni conduzcas a través de aguas de inundación, ni siquiera con poca profundidad.",
                    "Desconectá la electricidad si el agua puede llegar a tomacorrientes o aparatos.",
                    "Evitá el contacto con el agua de la inundación, puede estar contaminada.",
                    "Escuchá la radio o alertas oficiales para conocer rutas de evacuación seguras."
                ),
                urlVideo = "https://youtu.be/mFFRzIuD2Nw"
            ),
            Catastrofe(
                nombre = "Incendio",
                emoji = "🔥",
                urlImagen = "https://commons.wikimedia.org/wiki/Special:FilePath/Deerfire.jpg",
                consejos = listOf(
                    "Si hay humo, mantenete agachado cerca del piso donde el aire es más limpio.",
                    "Tocá las puertas antes de abrirlas: si están calientes, no las abras, buscá otra salida.",
                    "Nunca uses ascensores durante un incendio.",
                    "Una vez afuera, alejate del lugar y no vuelvas a entrar por ningún motivo.",
                    "Si tu ropa se prende fuego: detenete, tirate al piso y rodá."
                ),
                urlVideo = "https://youtu.be/8MUN8ILlBE8"
            )
        )
    }
}