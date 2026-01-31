# Calc Mobile (Flutter)

A minimal text-based calculator (Numi-like) for mobile, built with Flutter. Type a one-line expression like `1*2` and, when you add `=`, it computes immediately. Press Enter (Done) to commit the line to history. Each line is a separate equation.

## Features
- Single-line input; `=` triggers evaluation
- Enter/Done commits to history
- Shows result or an error inline
- Supports common operators: `+ - * / ^ ( )`

## Getting Started

### Prerequisites
- Flutter SDK (3.3+ recommended)
- Xcode + iOS Simulator (for iPhone 15 testing)

### Project setup
If you don't see platform folders (ios/android), initialize them once:

```bash
cd /Users/ardiantonugroho/calc-mobile
flutter create .
flutter pub get
```

### Run on iPhone 15 simulator
Start the iOS Simulator and select iPhone 15, then run:

```bash
open -a Simulator
# If needed, choose iPhone 15 in Simulator's Window > Device
flutter devices
flutter run -d "iPhone 15"
```

If `"iPhone 15"` doesn't resolve, pick the UDID from `flutter devices` and run `flutter run -d <UDID>`.

## Project Structure
- `lib/main.dart`: App UI and evaluation logic
- `pubspec.yaml`: Dependencies (uses `math_expressions`)
- `test/`: Optional unit tests

## Notes
- Only one-line equations are supported.
- Evaluation occurs only when `=` is present in the input.
- History shows `expression` on the left and `result` (or error) on the right.
