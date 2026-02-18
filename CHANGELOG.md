# Changelog hyo_ai

## v1.0.0 – 16 Februari 2026
- Struktur awal aplikasi Flutter: main.dart, halaman utama, profile, about, contact, support.
- UI sederhana, warna default Flutter, font standar.
- Fungsi dasar chat, profile, dan halaman pendukung.

## v2.0.0 – 18 Februari 2026
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

### Hasil Akhir
- Aplikasi berjalan lancar tanpa error sintaksis.
- Visual premium, modern, dan sangat anime.
- Struktur project lebih rapi dan aman untuk portofolio.
