# TypeCal Mobile (Flutter)

TypeCal Mobile is a notes-style calculator where you can type naturally and get inline results per line.

## Features
- Multi-line editor with inline result chips
- Arithmetic expressions with variables (for example `price = 120*4`)
- Currency conversion (for example `120 usd to idr`)
- Unit conversion (for example `10 km to mi`)
- Template menu for quick insertion:
  - Math example
  - Currency conversion
  - Unit conversion
  - Variable assignment

## Prerequisites
- Flutter SDK (3.38+ recommended)
- Xcode (for iOS build/install)

## Setup
```bash
flutter pub get
```

## Run
```bash
flutter run
```

## Run on specific device
```bash
flutter devices
flutter run -d <DEVICE_ID>
```

## Install release build to iPhone (USB attached)
```bash
flutter clean
flutter pub get
flutter build ios --release
flutter install -d <IPHONE_DEVICE_ID> --release --device-connection attached
```

## Quality checks
```bash
flutter analyze
flutter test
flutter test integration_test
```

## Project Structure
- `lib/main.dart`: App UI and calculator/domain logic
- `test/`: Unit and widget tests
- `integration_test/`: End-to-end flows
