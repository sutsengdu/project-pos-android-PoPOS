# PoPOS - Open Source Point of Sale Ecosystem

A modern, fast, and beautiful Point of Sale (POS) system. PoPOS is a full-stack ecosystem designed for small businesses, featuring a mobile app, a web dashboard, and a robust API backend.

---

## 🏗️ Project Architecture

This repository contains the complete PoPOS ecosystem:

- **Mobile App (`/`)**: Built with **Flutter**. The primary interface for sales and inventory management.
- **Backend API (`/backend`)**: Built with **Laravel 12**. Handles data persistence, authentication, and business logic.
- **Web Frontend (`/frontend`)**: Built with **React + Vite**. A web-based dashboard for analytics and management.

---

## 🚀 Getting Started

### 1. Backend Setup (Laravel)

The backend provides the API for both mobile and web clients.

**Requirements:**
- PHP ^8.2
- Composer
- SQLite (or MySQL)

**Installation:**
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install PHP dependencies:
   ```bash
   composer install
   ```
3. Set up environment variables:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
4. Configure your database in `.env` (Default is SQLite).
5. Run migrations and seeders:
   ```bash
   php artisan migrate
   ```
6. Start the local server:
   ```bash
   php artisan serve
   ```

---

### 2. Frontend Setup (React)

The web dashboard for managing products and viewing sales reports.

**Requirements:**
- Node.js (v18+)
- npm or yarn

**Installation:**
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure environment variables in `.env`:
   ```env
   VITE_API_BASE_URL=http://localhost:8000/api
   ```
4. Start the development server:
   ```bash
   npm run dev
   ```

---

### 3. Mobile App Setup (Flutter)

The mobile application for barcode scanning and quick sales.

**Requirements:**
- Flutter SDK
- Android Studio / VS Code

**Installation:**
1. Stay in the root directory.
2. Install Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

## 📦 Building for Production

### Android APK
To generate a production-ready `.apk` file:
```bash
flutter build apk --release
```
The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Web Frontend
To build the React dashboard:
```bash
cd frontend
npm run build
```

---

## ✨ Features

- **Dashboard**: Real-time sales insights and performance trends.
- **Product Management**: Easy-to-use inventory management with barcode support.
- **Sales Flow**: Fast barcode scanning and manual search for quick checkouts.
- **Invoices**: Professional PDF invoices with custom shop branding.
- **Myanmar Language Support**: Full Unicode support for Myanmar language.
- **Dark Mode**: Sleek UI designed for comfort in any lighting.
- **Cloud Sync**: Optional backend synchronization for multi-device support.

---

## 🛠️ Built With

- **Flutter** - Mobile UI Framework
- **React + Vite** - Web Dashboard
- **Laravel** - Backend API
- **SQLite/MySQL** - Data persistence
- **Tailwind CSS** - Modern styling

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
