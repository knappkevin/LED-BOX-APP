# LED Box App

Built for this [LED project](https://github.com/knappkevin/RGB-LED-BOX)

Cross platform app built with Flutter that connects to ESP32/microcontrollers over BLE and sends editable string commands.

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

User command save file: ~/.local/share/com.example.LED-BOX-APP/

### APK

```bash
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

