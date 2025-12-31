# 📱 Split Tracker - Mobile App

> The native Android interface for the Split Tracker Microservices ecosystem. Built with **Flutter** and **Material Design 3**.

## 📖 Overview

This application serves as the user interface for the Split Tracker system. It allows users to register, create groups, split expenses, and receive **real-time push notifications** when they are added to an expense.

It connects to the backend API Gateway via REST and handles asynchronous events (notifications) via Firebase Cloud Messaging (FCM).

---

## ✨ Key Features

### 1. User Authentication & Session Management

* **Seamless Login:** Users can log in via email/name.
* **Auto-Login:** The app remembers the session using `SharedPreferences`, so users don't need to log in every time they open the app.
* **Device Registration:** Automatically syncs the device's **FCM Token** with the backend upon login to ensure notifications reach the correct device.

### 2. Expense Management

* **Add Expense:** A clean UI to enter descriptions, amounts, and select friends to split with.
* **Dynamic Splitting:** Automatically calculates the split amount based on the number of users involved.
* **Real-time Updates:** Pull-to-refresh functionality to see the latest expenses added by other users.

### 3. Smart Notifications (Firebase)

* **Push Notifications:** Receives instant alerts when someone adds you to an expense (triggered by Kafka on the backend).
* **Foreground Handling:** Custom **In-App SnackBar** notifications appear if the user is currently using the app, ensuring they never miss an update.
* **Background Handling:** Standard system tray notifications when the app is minimized.

### 4. Modern UI/UX (Material 3)

* **Adaptive Theming:** Supports both **Light Mode** and **Dark Mode** (syncs with system settings).
* **Responsive Design:** Custom input fields, floating action buttons, and list tiles designed for touch targets.
* **Loading States:** Elegant circular progress indicators during API calls.

---

## 🛠️ Tech Stack

* **Framework:** Flutter (SDK > 3.0)
* **Language:** Dart
* **Networking:** `dio` (for robust HTTP requests with interceptors)
* **Local Storage:** `shared_preferences`
* **Notifications:** `firebase_messaging`, `flutter_local_notifications`
* **UI Components:** Material Design 3

---

## 🚀 Installation & Setup

### Prerequisites

* Flutter SDK installed.
* An Android Emulator or Physical Device.
* Backend services running (see Backend README).

### 1. Configuration

Open `lib/main.dart` or `lib/utils/api_client.dart` and update the `baseUrl`:

```dart
// For Emulator
final String baseUrl = "http://10.0.2.2:8080/api"; 

// For Physical Device (Ensure phone and PC are on same WiFi)
final String baseUrl = "http://192.168.1.X:8080/api"; 

```

### 2. Install Dependencies

```bash
flutter pub get

```

### 3. Run the App

```bash
flutter run

```

---

## 📂 Project Structure

```
lib/
├── main.dart             # App Entry Point & Theme Config
├── firebase_options.dart # Firebase Configuration (Generated)
├── screens/
│   ├── login_screen.dart # Login logic & Token Registration
│   ├── home_screen.dart  # Dashboard & Expense List
│   └── add_expense_screen.dart # Form to create splits
├── utils/
│   └── api_client.dart   # Dio HTTP Client Wrapper
└── widgets/
    └── expense_tile.dart # Reusable UI component for list items

```

---

## 🐛 Troubleshooting

* **"Connection Refused":**
* Ensure your backend Docker containers are running.
* Check if your phone/emulator can reach the IP address.


* **"Notification not received":**
* Check `docker logs notification-service`.
* Ensure you logged in *after* restarting the backend (Token must be in the DB).
* Check if the app has Notification Permissions enabled in Android Settings.



---

## 👤 Author

**Rupesh**

* [GitHub](https://github.com/RupeshKankrej)