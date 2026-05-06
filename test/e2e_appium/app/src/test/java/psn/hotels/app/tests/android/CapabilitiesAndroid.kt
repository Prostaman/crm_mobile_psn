package psn.hotels.app.tests.android

import io.appium.java_client.android.options.UiAutomator2Options
import org.openqa.selenium.remote.DesiredCapabilities


fun getAndroidCapabilities(): UiAutomator2Options {
    val options = UiAutomator2Options()
        .setDeviceName("deb444ce59ee")
        .setPlatformName("Android")
        .setPlatformVersion("11")
        .setApp("/Users/trio/development/CompanyPSN/publication/android/apk/crm_mobile_debug_1.26.0.apk")
        .setAutomationName("UiAutomator2")
    return options
}

