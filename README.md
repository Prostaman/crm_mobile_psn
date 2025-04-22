# PSN Hotels

**PSN Hotels** is a mobile app developed specifically for travel agents working with the "Поехали с нами" (Let’s Go Together) travel network. It helps organize, edit, and send hotel media files directly to a CRM system with precise location binding.

---

## 🎯 Project Purpose

The main goal of the app is to provide travel managers with a convenient tool for **creating, editing, and transferring media files** linked to hotel locations directly into the company's CRM system.  
The app supports **offline mode**, utilizes a built-in database with information on over **100,000 hotels**, and performs **background synchronization** as soon as the device regains internet access — even if the app is closed.

---

## 📱 Key Features

- **Upload photos and videos** directly from the device
- **Image editing**: crop, rotate, apply filters
- **Attach media to hotels** based on geolocation or selection from a list
- **Offline functionality** with a local hotel database
- **Automatic background sync to CRM** upon network availability (even when the app is terminated)
- **Quick sharing** to messengers and social networks
- **Secure data storage**, accessible only by authorized employees

---

## 🧱 Tech Stack

- **Flutter** (iOS & Android)
- **Architecture**: BLoC
- **Background tasks**: `workmanager`
- **Local database**: `sqflite`
- **Networking**: `dio`
- **Geolocation**: `geolocator`, `location`
- **Camera & video**: `camera`, `video_compress`, `video_player`, `chewie`
- **Image editing**: `image_cropper` with filter support
- **Sharing**: `share_plus`
- **Analytics & crash reporting**: Firebase Analytics + Crashlytics

---

## 📸 Demo

▶️ [Watch Video Demo](https://youtube.com/shorts/r1_G6hLlPxk?si=uURKm0ymg0rfk2aM)  

---

## 🚫 Note

This app is designed for internal use by the "Поехали с нами" network and may not function without appropriate backend access.

