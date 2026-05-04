# LED Box App

A Flutter app that connects to ESP32/microcontrollers over BLE and sends predefined string commands.

## Project Overview

- **Purpose**: Control LED cubes or other BLE-enabled devices via predefined commands
- **Framework**: Flutter 3.41.2, Dart 3.11.4

## Project Structure

```
lib/
├── main.dart              # Entry point (launches HomeScreen's MyApp)
├── home_screen.dart       # UI: connection status, scan dialog, command list
├── ble_manager.dart       # BLE singleton: scan, connect, send, reconnect
└── models/
    └── command.dart       # Command model + default command list
```

## Setup

### Linux Desktop (Recommended for development)

```bash
flutter run -d linux
```

`systemctl is-active bluetooth` should return `active`

### APK

```bash
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

