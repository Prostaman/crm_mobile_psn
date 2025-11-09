# Зберегти класи uCrop
-keep class com.yalantis.ucrop.** { *; }

# Зберегти OkHttp
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Не обфускувати моделі, якщо вони використовуються у reflection
-dontwarn okhttp3.**
-dontwarn okio.**
