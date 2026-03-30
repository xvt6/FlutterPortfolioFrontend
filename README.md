# Audio Library App Frontend

A Flutter-based frontend for managing and exploring an audio library and posts.

## Getting Started

To get the project up and running in a development environment, follow these steps:

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
- A running instance of the backend.

### Setup and Installation

1. **Install Dependencies:**
   Run the following command in the project root to fetch all required packages:
   ```bash
   flutter pub get
   ```

2. **Run in Development Mode:**
   To start the app, use the `flutter run` command. By default, it connects to the backend at `http://localhost:5000`.
   ```bash
   flutter run
   ```

   **Custom Backend URL:**
   If your backend is running at a different address, you can specify it using `--dart-define`:
   ```bash
   flutter run --dart-define=BACKEND_URL=http://localhost:5023 --web-port=5173
   ```

### Project Features

- **Posts View:** Browse through recent posts.
- **Audio Library:** Explore and play uploaded audio tracks.
- **Admin Authentication:** Secure login for admin users.
- **Admin Dashboard:** Upload WAV files and manage posts (requires login).

### Running Tests

To ensure everything is working correctly, you can run the existing widget tests:
```bash
flutter test
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [GoRouter Package](https://pub.dev/packages/go_router)
