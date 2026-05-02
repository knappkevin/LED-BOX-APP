# LED Box App

A Flutter app that connects to ESP32/microcontrollers over BLE and sends predefined string commands.

## Project Overview

- **Purpose**: Control LED cubes or other BLE-enabled devices via predefined commands
- **Framework**: Flutter 3.41.2, Dart 3.11.4
- **State Management**: Provider
- **BLE Library**: flutter_blue_plus

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

### Prerequisites

| Dependency | Version | Notes |
|---|---|---|
| Flutter | 3.41.2+ | Available via AUR (`yay -S flutter`) |
| JDK | 21 | JDK 26 causes Kotlin compilation errors. Set with `archlinux-java set java-21-openjdk` |

### Known Arch Linux Gotchas

- **Kotlin sessions directory**: The AUR Flutter package doesn't create it, causing build failures:
  ```
  sudo mkdir -p /usr/lib/flutter/packages/flutter_tools/gradle/.kotlin/sessions
  sudo chmod -R 777 /usr/lib/flutter/packages/flutter_tools/gradle/.kotlin/
  ```

### Install Dependencies

```bash
flutter pub get
```

## Running the App

### Linux Desktop (Recommended for development)

```bash
flutter run -d linux
```

Requires BlueZ running (`systemctl is-active bluetooth` should return `active`).

### Android (APK)

```bash
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

#### Install to Waydroid

```bash
# Start Waydroid session first
waydroid session start

# Copy and install APK (requires root for shell access)
cat > /tmp/install.sh << 'SCRIPT'
#!/bin/bash
waydroid shell -- mkdir -p /data/local/tmp
cat ~/Projects/LED-BOX-APP/build/app/outputs/flutter-apk/app-release.apk | waydroid shell -- sh -c 'cat > /data/local/tmp/app-release.apk'
waydroid shell -- pm install -r /data/local/tmp/app-release.apk
SCRIPT
chmod +x /tmp/install.sh && pkexec /tmp/install.sh
```

**Note**: Waydroid has **no Bluetooth support**. BLE will not work inside Waydroid. Use Linux desktop or a physical Android device for BLE testing.

## Features

- BLE device scanning and connection
- Auto-reconnect to last connected device
- Send predefined commands via BLE characteristic write
- Connection status display

## Default Commands

| Name | Value |
|---|---|
| LED On | LED_ON |
| LED Off | LED_OFF |
| Blink | BLINK |
| Pulse | PULSE |
| Rainbow | RAINBOW |
| Clear | CLEAR |
| Pattern 1 | PATTERN_1 |
| Pattern 2 | PATTERN_2 |
| Speed Up | SPEED_UP |
| Speed Down | SPEED_DOWN |

Add/remove commands in `lib/models/command.dart`.

## Troubleshooting

### No devices appearing on scan

1. Verify BlueZ is running: `systemctl status bluetooth`
2. Verify adapter is not blocked: `rfkill list`
3. Ensure your BLE device is powered on and advertising
4. Restart Bluetooth service: `sudo systemctl restart bluetooth`

### Build fails with Kotlin error

See "Known Arch Linux Gotchas" above — create the `.kotlin/sessions` directory.

### Build fails with `26.0.1` error

Switch to JDK 21: `archlinux-java set java-21-openjdk`
