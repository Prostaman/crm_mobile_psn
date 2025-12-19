package psn.hotels.app.tests.ios

import io.appium.java_client.ios.options.XCUITestOptions
import org.openqa.selenium.remote.DesiredCapabilities


fun getIOSCapabilities(): XCUITestOptions {

    val options = XCUITestOptions()
        .setDeviceName("00008030-001C05EE1AC2202E")
        .setPlatformName("iOS")
        .setPlatformVersion("17.5")
        .setApp("/Users/trio/development/CompanyPSN/publication/ios/ipa/Runner 2024-08-23 19-20-43 v1.25.8/PSN Hotels.ipa")
        .setAutomationName("XCUITest")

    return options
}

