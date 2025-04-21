package psn.hotels.app.helpers

import java.time.LocalDate
import java.time.format.DateTimeFormatter

internal fun getCurrentDate(): String {
    val currentDate = LocalDate.now()
    val formatter = DateTimeFormatter.ofPattern("dd.MM.yyyy")
    return currentDate.format(formatter)
}