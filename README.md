# PoPOS - Open Source Flutter Point of Sale

A modern, fast, and beautiful Point of Sale (POS) system built with Flutter. Designed for small businesses and retail shops, it supports local database management, barcode scanning, and beautifully rendered invoices.

---

## Features

- **Dashboard**: Real-time sales insights and performance trends.
- **Product Management**: Easy-to-use inventory management with barcode support.
- **Sales Flow**: Fast barcode scanning and manual search for quick checkouts.
- **Invoices**: Professional PDF invoices with custom shop branding.
- **Myanmar Language Support**: Full Unicode support for Myanmar language.
- **Dark Mode**: Sleek UI designed for comfort in any lighting.
- **Backup & Restore**: Secure local database backup to keep your data safe.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) or VS Code

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/sutsengdu/project-pos.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

---

## Building the APK

To generate a production-ready `.apk` file for Android:

1. Open your terminal in the project root.
2. Run the following command:
   ```bash
   flutter build apk --release
   ```
3. The generated APK will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`

*Tip: For a smaller APK size, you can use `flutter build apk --split-per-abi`.*

---

## Built With

- **Flutter** - UI Framework
- **SQLite** - Local data persistence
- **Provider** - State management
- **Printing** - PDF generation and printing

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to help improve this project.

- Fork the project
- Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
- Commit your changes (`git commit -m 'Add some AmazingFeature'`)
- Push to the Branch (`git push origin feature/AmazingFeature`)
- Open a Pull Request
