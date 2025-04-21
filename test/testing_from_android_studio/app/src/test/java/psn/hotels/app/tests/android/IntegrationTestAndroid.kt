package psn.hotels.app.tests.android

import io.appium.java_client.AppiumBy
import io.appium.java_client.android.AndroidDriver
import io.appium.java_client.remote.MobileCapabilityType
import org.junit.After
import org.junit.Before
import org.junit.FixMethodOrder
import org.junit.Test
import org.junit.runners.MethodSorters
import org.openqa.selenium.Point
import org.openqa.selenium.remote.DesiredCapabilities
import psn.hotels.app.helpers.getCurrentDate
import psn.hotels.app.helpers.performTap
import java.net.URL
import java.time.Duration

@FixMethodOrder(MethodSorters.NAME_ASCENDING)
class IntegrationTestAndroid {

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
            "/Users/trio/development/CompanyPSN/publication/android/apk/crm_mobile_1.25.9+49.apk"
        )
        driver = AndroidDriver(URL("http://127.0.0.1:4723/"), capabilities)
        driver.manage()?.timeouts()?.implicitlyWait(Duration.ofSeconds(30))
    }

    private fun addingMediaFiles(title:String, description:String){
        //поиск отеля и добавление отеля
        var el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().className(\"android.widget.ImageView\").instance(2)"))
        el1.click()
        performTap(Point(293, 339),driver)
        el1 = driver.findElement(AppiumBy.className("android.widget.EditText"))
        el1.sendKeys("росс")
        //Thread.sleep(1500)
        el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().description(\"Россия санаторий\nУкраина, Одесса\")"))
        el1.click()
        el1 = driver.findElement(AppiumBy.accessibilityId("Выбрать"))
        el1.click()
        //создание и заполнение локации
        el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().className(\"android.widget.ImageView\").instance(2)"))
        el1.click()
        el1 = driver.findElement(AppiumBy.accessibilityId("Выберите категорию *"))
        el1.click()
        el1 = driver.findElement(AppiumBy.accessibilityId("Море, пляж"))
        el1.click()
        el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().className(\"android.widget.EditText\").instance(0)"))
        el1.click()
        el1.sendKeys(title)
        el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().className(\"android.widget.EditText\").instance(1)"))
        el1.click()
        el1.sendKeys(description)
        driver.executeScript("mobile: pressKey", mapOf("keycode" to 4))
        //добавление из галереи 3 медиафайла
        el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().className(\"android.widget.ImageView\").instance(3)"))
        el1.click()
        el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().resourceId(\"com.google.android.documentsui:id/icon\").instance(2)"))
        el1.click()
        el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().resourceId(\"com.google.android.documentsui:id/icon\").instance(3)"))
        el1.click()
        el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().resourceId(\"com.google.android.documentsui:id/icon\").instance(4)"))
        el1.click()
        el1 = driver.findElement(AppiumBy.id("com.google.android.documentsui:id/action_menu_select"))
        el1.click()
        Thread.sleep(1000)
        //добавление из камеры 1 фото и 1 видео
        performTap(Point(606, 1106),driver)
        el1 = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().className(\"android.view.View\").instance(6)"))
        el1.click()
        Thread.sleep(3000)
        el1 = driver.findElement(AppiumBy.accessibilityId("ВИДЕО"))
        el1.click()
        Thread.sleep(4000)
        val startVideoButton = driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().className(\"android.view.View\").instance(7)"))
        startVideoButton.click()
        Thread.sleep(10000)
        startVideoButton.click()
        el1 = driver.findElement(AppiumBy.accessibilityId("Добавить (2)"))
        el1.click()
        driver.executeScript("mobile: pressKey", mapOf("keycode" to 4))
        Thread.sleep(1000)
        val el18 = driver.findElement(AppiumBy.accessibilityId("Сохранить"))
        el18.click()
        Thread.sleep(5000)
    }



    @Test
    fun test1_WithSwitchingOffWifi() {
        //авторизация
        auth(driver)
        //добавление медиафайлов
        addingMediaFiles("Тестовая локация ","Тестовое описание")
        //имитация обрыва связи( выключение WiFi)

        driver.toggleWifi()
        Thread.sleep(10000)
        driver.toggleWifi()
        Thread.sleep(15000)

        //проверка что всё отправилось
        driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().description(\"100%, Создано: ${getCurrentDate()}\n Море, пляж\nТестовая локация \n 5 медиафайлов\n100%\n загружено\")"))
    }

    @Test
    fun test2_WithoutInternet(){
        auth(driver)
        driver.toggleWifi()
        addingMediaFiles("Тестовая локация без интернета","Тестовая локация без интернета")
        driver.findElement(AppiumBy.androidUIAutomator("new UiSelector().description(\"Создано: ${getCurrentDate()}\n Море, пляж\nТестовая локация без интернета\n 5 медиафайлов\")"))
    }

    @After
    fun tearDown() {
        driver.quit()
    }
}