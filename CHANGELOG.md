# Changelog hyo_ai

## v1.0.0 – 16 Februari 2026
- Struktur awal aplikasi Flutter: main.dart, halaman utama, profile, about, contact, support.
- UI sederhana, warna default Flutter, font standar.
- Fungsi dasar chat, profile, dan halaman pendukung.

### Build & Fix (16 Februari 2026)
- hyo-ai.apk: Build awal.
- hyo-ai-fix.apk, hyo-ai-fix-2.apk: Perbaikan bug minor, typo, dan error kompilasi.

## v1.2.0 – 17 Februari 2026
- hyo-ai 1.2.0.apk: Penambahan fitur minor, perbaikan UI, dan peningkatan stabilitas.

## v2.0.0 – 18 Februari 2026
### Build 2.0.1+3, 2.0.2+4, 2.0.3+5
- hyo-ai 2.0.1+3.apk, 2.0.2+4.apk, 2.0.3+5.apk: Iterasi pengembangan fitur baru, perbaikan bug, dan penyesuaian UI.

### Transformasi Estetika & UI
- Palet warna pastel: Sakura Pink (#FFB7C5), Lavender (#E0BBE4), Soft Blush (#FFF5F7).
- Font Itim (Google Fonts) untuk nuansa anime playful.
- Efek glassmorphism pada sidebar/drawer.
- GlowBlobs sebagai elemen visual latar.
- Semua komponen UI (chat bubble, mic button, send button) lebih rounded dan pastel.

### Konsistensi & Penyempurnaan Halaman
- Profile: avatar picker & input field lebih lembut dan konsisten.
- About, Contact, Support: ikon, teks, warna AppBar seragam di seluruh aplikasi.

### Perbaikan Bug & Sintaksis
- main.dart: bracket, koma, hex color diperbaiki.
- about_page.dart: kurung kurawal ekstra dihapus.
- Semua error kompilasi & typo widget/import sudah diperbaiki.

### Refactor Struktur & Pengamanan
- File konfigurasi (prompts.json, context.json) dipindah ke assets/config/.
- server.js dipindah ke folder server/.
- scripts/ dibuat untuk otomatisasi (misal: start_voicevox.ps1).
- .env dan file sensitif diamankan, .gitignore diupdate agar tidak ikut push.

## v2.1.0 (build 6) – 18 Februari 2026
- hyo-ai 2.1.0 (build 6).apk: Build stabil, siap rilis portofolio. Semua fitur utama, UI, dan keamanan sudah optimal.

## v2.1.1 (micfix) – 20 Februari 2026
- Perbaikan dan peningkatan animasi tombol mic (MicButton).
- UI lebih smooth dan responsif saat menekan/menahan mic.
- Build: hyo-ai-2.1.1-micfix.apk