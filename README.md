# Notes V1

A beautifully designed, premium note-taking application built with Flutter. Notes V1 focuses on delivering a seamless and visually stunning user experience while maintaining robust, offline-first functionality.

## ✨ Features

- **Premium UI/UX:** Clean, modern interface with beautiful typography, subtle shadows, and smooth micro-animations.
- **Dark & Light Mode:** Fully adaptive theming that looks gorgeous in any lighting condition.
- **Robust Storage:** Fast and reliable local persistent storage powered by SQLite (`sqflite`).
- **State Management:** Reactive and performant UI updates using the `provider` package.
- **Real-Time Search:** Instantly filter your notes as you type, with dynamic text highlighting for search queries.
- **Multi-Selection:** Easily select, manage, and bulk-delete multiple notes at once.
- **Advanced Editing:** Full Undo/Redo history support while composing or editing your notes.
- **Custom Dialogs:** Thoughtfully designed, compact confirmation dialogs and floating snackbars for an elevated experience.
- **Responsive Layout:** Adaptive staggered grid layout (`flutter_staggered_grid_view`) that beautifully cascades your notes of varying lengths.

## 🚀 Getting Started

To build and run this application locally, ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

1. **Clone the repository**
```bash
git clone https://github.com/Lamzeez/Notes_V1.git
cd Notes_V1
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

## 🛠️ Tech Stack & Packages

- **Framework:** Flutter / Dart
- **State Management:** `provider`
- **Database:** `sqflite` & `path`
- **UI Components:** `flutter_staggered_grid_view`, `google_fonts`
- **Formatting:** `intl` (for beautiful timestamp rendering)

## 🎨 Design Philosophy

Notes V1 was built with a "Rich Aesthetics" philosophy. It intentionally avoids generic default components in favor of custom-styled widgets, rounded corners, drop shadows, and curated color palettes (like elegant deep blues for dark mode and soft, airy whites for light mode). Everything from the floating action buttons to the unsaved changes dialogs has been scaled and tailored for a premium mobile feel.
