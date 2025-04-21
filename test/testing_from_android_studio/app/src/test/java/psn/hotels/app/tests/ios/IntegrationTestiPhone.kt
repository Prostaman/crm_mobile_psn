package psn.hotels.app.tests.ios

import io.appium.java_client.AppiumBy
import io.appium.java_client.AppiumDriver
import io.appium.java_client.remote.MobileCapabilityType
import org.junit.Before
import org.junit.Test
import org.openqa.selenium.Point
import org.openqa.selenium.remote.DesiredCapabilities
import psn.hotels.app.helpers.getCurrentDate
import psn.hotels.app.helpers.performTap
import java.net.URL
import java.time.Duration

class IntegrationTestiPhone {

    private lateinit var driver: AppiumDriver

    //AppiumDriver
    private val title: String = "Тестовое название"
    private val description: String = "Тестовое описание"

    @Before
    fun setUp() {
        val capabilities = DesiredCapabilities()
        capabilities.setCapability(MobileCapabilityType.AUTOMATION_NAME, "xcuitest")
        capabilities.setCapability(MobileCapabilityType.PLATFORM_NAME, "iOS")
        capabilities.setCapability(MobileCapabilityType.PLATFORM_VERSION, "17.5")
        capabilities.setCapability(MobileCapabilityType.UDID, "00008030-001C05EE1AC2202E")
        capabilities.setCapability(
            MobileCapabilityType.APP,
            "/Users/trio/development/CompanyPSN/publication/ios/ipa/Runner 2024-08-23 19-20-43 v1.25.8/PSN Hotels.ipa"
        )
        driver = AppiumDriver(URL("http://127.0.0.1:4723/"), capabilities)
        driver.manage()?.timeouts()?.implicitlyWait(Duration.ofSeconds(30))
    }


    private fun auth() {
        performTap(Point(204, 579), driver)
        var el = driver.findElement(AppiumBy.accessibilityId("Логин"))
        el.click()
        el.sendKeys("Ростислав Триодял") //TEST HOTEL
        el = driver.findElement(AppiumBy.accessibilityId("Пароль"))
        el.click()
        el.sendKeys("parol777") //TESTHOTEL
        el = driver.findElement(AppiumBy.accessibilityId("Done"))
        el.click()
        el = driver.findElement(AppiumBy.accessibilityId("Войти в систему"))
        el.click()
        el = driver.findElement(AppiumBy.accessibilityId("Далее"))
        el.click()
        Thread.sleep(500)
        performTap(Point(192, 553), driver)
        el.click()
        Thread.sleep(500)
        el.click()
        performTap(Point(209, 544), driver)
        el.click()
        Thread.sleep(500)
        performTap(Point(195, 617), driver)
        el.click()
        Thread.sleep(500)
        performTap(Point(187, 664), driver)
        Thread.sleep(40000)
    }

    private fun addFiles() {
        var el =
            driver.findElement(AppiumBy.iOSClassChain("**/XCUIElementTypeWindow[1]/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeButton"))
        el.click()
        performTap(Point(130, 186), driver)
        el = driver.findElement(AppiumBy.className("XCUIElementTypeTextField"))
        el.sendKeys("росс")
        el =
            driver.findElement(AppiumBy.xpath("//XCUIElementTypeStaticText[@name=\"Россия санаторий\nУкраина, Одесса\"]"))
        el.click()
        el = driver.findElement(AppiumBy.accessibilityId("Выбрать"))
        el.click()
        el =
            driver.findElement(AppiumBy.iOSClassChain("**/XCUIElementTypeWindow[1]/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeButton"))
        el.click()
        el = driver.findElement(AppiumBy.accessibilityId("Выберите категорию *"))
        el.click()
        el = driver.findElement(AppiumBy.accessibilityId("Море, пляж"))
        el.click()
        el = driver.findElement(AppiumBy.accessibilityId("Название локации"))
        el.click()
        el.sendKeys(title)
        el = driver.findElement(AppiumBy.accessibilityId("Описание"))
        el.click()
        el.sendKeys(description)
        el =
            driver.findElement(AppiumBy.iOSClassChain("**/XCUIElementTypeWindow[1]/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeButton[1]"))
        el.click()
        el =
            driver.findElement(AppiumBy.iOSClassChain("**/XCUIElementTypeWindow[1]/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[3]/XCUIElementTypeOther[3]"))
        el.click()
        Thread.sleep(2000)
        el = driver.findElement(AppiumBy.accessibilityId("ВИДЕО"))
        el.click()
        Thread.sleep(2000)
        val videoButton =
            driver.findElement(AppiumBy.iOSClassChain("**/XCUIElementTypeWindow[1]/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[3]/XCUIElementTypeOther[3]"))
        videoButton.click()
        Thread.sleep(8000)
        videoButton.click()
        Thread.sleep(5000)
        el = driver.findElement(AppiumBy.accessibilityId("Добавить (2)"))
        el.click()
        el =
            driver.findElement(AppiumBy.iOSClassChain("**/XCUIElementTypeWindow[1]/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeOther[2]/XCUIElementTypeButton[2]"))
        el.click()
        Thread.sleep(2000)
        performTap(Point(63, 504), driver)
        Thread.sleep(2000)
        performTap(Point(204, 504), driver)
        Thread.sleep(2000)
        performTap(Point(337, 504), driver)
        Thread.sleep(2000)
        el = driver.findElement(AppiumBy.accessibilityId("Добавить"))
        el.click()
        el = driver.findElement(AppiumBy.accessibilityId("Сохранить"))
        el.click()

    }


    @Test
    fun unitTest() {
        auth()
        addFiles()
        Thread.sleep(40000)
        driver.findElement(AppiumBy.xpath("//XCUIElementTypeOther[@name=\"Создано: ${getCurrentDate()}\n Море, пляж\n$title\n 5 медиафайлов\n100%\n загружено\"]"))
    }

}
