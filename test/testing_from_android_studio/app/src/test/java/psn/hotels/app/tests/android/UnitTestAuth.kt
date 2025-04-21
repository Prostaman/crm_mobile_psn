package psn.hotels.app.tests.android

import io.appium.java_client.AppiumBy
import io.appium.java_client.android.AndroidDriver
import io.appium.java_client.remote.MobileCapabilityType
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.openqa.selenium.remote.DesiredCapabilities
import java.net.URL
import java.time.Duration
import java.util.Properties


class UnitTestAuth {

    //für Appium Session
//    {
//        "appium:automationName": "UiAutomator2",
//        "appium:platformName": "Android",
//        "appium:platformVersion": "11",
//        "appium:deviceName": "deb444ce59ee",
//        "appium:app": "/Users/trio/development/CompanyPSN/publication/android/apk/crm_mobile_1.25.6+46.apk"
//    }
    private lateinit var driver: AndroidDriver
//AppiumDriver

    @Before
    fun setUp() {
        val capabilities = DesiredCapabilities()
        capabilities.setCapability(MobileCapabilityType.AUTOMATION_NAME, "UiAutomator2")
        capabilities.setCapability(MobileCapabilityType.PLATFORM_NAME, "Android")
        capabilities.setCapability(MobileCapabilityType.PLATFORM_VERSION, "11")
        capabilities.setCapability(MobileCapabilityType.DEVICE_NAME, "deb444ce59ee")
        capabilities.setCapability(
            MobileCapabilityType.APP,
            "/Users/trio/development/CompanyPSN/publication/android/apk/app-release.apk"
        )
        driver = AndroidDriver(URL("http://127.0.0.1:4723/"), capabilities)
        driver.manage()?.timeouts()?.implicitlyWait(Duration.ofSeconds(30))
    }


    @Test
    fun test() {
        auth(driver)
    }


    @After
    fun tearDown() {
        driver.quit()
    }

}

fun auth(driver: AndroidDriver) {
    var el1 =
        driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().className(\"android.widget.EditText\").instance(0)"))
    el1.click()
    Thread.sleep(300)
    //init Propeties
    val props = Properties()
    val inputStream = Thread.currentThread().contextClassLoader?.getResourceAsStream("auth.properties")
        ?: throw IllegalArgumentException("auth.properties not found")
    props.load(inputStream)
    val login = props.getProperty("login") ?: throw IllegalArgumentException("login not found")
    val password = props.getProperty("password") ?: throw IllegalArgumentException("password not found")
//Auth
    el1.sendKeys(login)
    driver.executeScript("mobile: pressKey", mapOf("keycode" to 4))
    el1 =
        driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().className(\"android.widget.EditText\").instance(1)"))
    el1.click()
    el1.sendKeys(password)
    driver.executeScript("mobile: pressKey", mapOf("keycode" to 4))
    el1 = driver.findElement(AppiumBy.accessibilityId("Войти в систему"))
    el1.click()
    el1 = driver.findElement(AppiumBy.accessibilityId("Далее"))
    el1.click()
    Thread.sleep(300)
    el1 =
        driver.findElement(AppiumBy.id("com.android.permissioncontroller:id/permission_allow_foreground_only_button"))
    el1.click()
    Thread.sleep(300)
    el1 =
        driver.findElement(AppiumBy.id("com.android.permissioncontroller:id/permission_allow_foreground_only_button"))
    el1.click()
    Thread.sleep(300)
    el1 =
        driver.findElement(AppiumBy.id("com.android.permissioncontroller:id/permission_allow_foreground_only_button"))
    el1.click()
    Thread.sleep(300)
    el1 =
        driver.findElement(AppiumBy.id("com.android.permissioncontroller:id/permission_allow_button"))
    el1.click()
    Thread.sleep(45000)
}