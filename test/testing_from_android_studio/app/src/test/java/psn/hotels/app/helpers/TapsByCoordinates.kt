package psn.hotels.app.helpers

import io.appium.java_client.AppiumDriver
import io.appium.java_client.android.AndroidDriver
import org.openqa.selenium.Point
import org.openqa.selenium.interactions.Pause
import org.openqa.selenium.interactions.PointerInput
import java.time.Duration

internal fun performTap(tapPoint: Point, appiumDriver: AppiumDriver) {
    val finger = PointerInput(PointerInput.Kind.TOUCH, "finger")
    val tap = org.openqa.selenium.interactions.Sequence(finger, 1)
    tap.addAction(
        finger.createPointerMove(
            Duration.ofMillis(300),
            PointerInput.Origin.viewport(), tapPoint.x, tapPoint.y
        )
    )
    tap.addAction(finger.createPointerDown(PointerInput.MouseButton.LEFT.asArg()))
    tap.addAction(Pause(finger, Duration.ofMillis(300)))
    tap.addAction(finger.createPointerUp(PointerInput.MouseButton.LEFT.asArg()))
    appiumDriver.perform(listOf(tap))
}