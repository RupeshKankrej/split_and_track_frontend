# Split & Track - Mobile App

   

**Split & Track Mobile** is the frontend client for the Distributed Expense Splitting System. Built with **Flutter**, it provides a modern, responsive interface for users to manage groups, track expenses, and visualize spending habits.

It communicates with the backend via a unified **API Gateway**, utilizing JWT for secure, stateless authentication.

## 📱 Features

  * **Secure Authentication:** User Login & Registration with JWT storage.
  * **Group Management:** Create groups and invite members via email (Lazy Registration support).
  * **Expense Tracking:**
      * Add expenses with descriptions and categories.
      * **Smart Splitting:** Support for Equal and Unequal split distribution.
  * **Interactive Dashboard:**
      * View "Who owes whom" balances in real-time.
      * Settle debts with a single tap.
      * Visual "Spend Analysis" using interactive Pie Charts.
  * **Modern UI/UX:**
      * **Material You (Material 3)** design system.
      * **Dark Mode & Light Mode** support (System adaptive).
      * Swipe-to-delete gestures and modal bottom sheets for details.

## 🛠️ Tech Stack

  * **Framework:** Flutter (Dart)
  * **State Management:** `setState` (Clean Architecture approach)
  * **Networking:** `Dio` (with Interceptors for JWT injection)
  * **Charts:** `fl_chart`
  * **Local Storage:** `shared_preferences`
  * **Design:** Material 3 (Themed Widgets)

## ⚙️ Setup & Installation

### Prerequisites

  * [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
  * Android Studio or VS Code with Flutter extensions.
  * The **Split & Track Backend** running (via Docker or locally).

### Installation Steps

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/split-and-track-mobile.git
    cd split-and-track-mobile
    ```

2.  **Install Dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Configure API Endpoint:**
    Open `lib/main.dart` (or `lib/utils/api_client.dart`) and update the `baseUrl` to point to your **API Gateway**.

      * **If running on Emulator:** Use `10.0.2.2:8080`
      * **If running on Real Device:** Use your LAN IP, e.g., `192.168.1.5:8080`

    <!-- end list -->

    ```dart
    // Example in main.dart
    final String baseUrl = "http://192.168.1.5:8080/api"; 
    ```

4.  **Run the App:**

    ```bash
    flutter run
    ```

## 📂 Project Structure

```text
lib/
├── main.dart              # Entry point & Theme Config
├── screens/               # UI Pages
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── group_detail_screen.dart
│   ├── add_expense_screen.dart
│   └── analysis_screen.dart
├── widgets/               # Reusable UI components
├── utils/                 # Helpers
│   └── api_client.dart    # Dio Setup & Interceptors
└── models/                # Data Models (Optional)
```

## 🚀 Key Implementation Details

  * **JWT Handling:** The `ApiClient` class uses a Dio Interceptor to automatically attach the `Bearer` token to every outgoing request, ensuring seamless security.
  * **Dynamic Theming:** The app uses `ColorScheme.fromSeed` to generate a cohesive color palette that adapts automatically to the user's device theme (Light/Dark).
  * **Optimized Lists:** Uses `ListView.builder` and `CustomScrollView` (Slivers) for performant scrolling even with large transaction histories.

## 🤝 Contributing

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

-----

*Built by Rupesh | 2025*