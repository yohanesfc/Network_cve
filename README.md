# Network + CVE Tools - Flutter App

Gabungan antara **Network Tools** dan **CVE Search** (powered by NIST NVD API).

---

## 📱 Fitur

### Network Tools
- Ping IPv4 / IPv6 / TCP
- DNS Lookup & Reverse DNS
- HTTP Headers
- Port Range Scan (common ports)
- Network Info (public IP, geolocation)
- Subnet Calculator & Subnet Scan
- Hex Calculator (BARU)
- Random Password Generator (BARU)
- SSL Scan, Secure DNS, Dig, Is it up?, IDN ↔ ACE, Spam Check
- Whois / RDAP
- Dan lainnya...

### CVE Search (BARU - Terintegrasi)
- **News Feed**: Latest HIGH/CRITICAL CVEs dari NVD (real-time)
- **Search**: Cari by keyword (e.g. "Apache", "Log4J2") atau CVE-ID langsung
- **Detail View**: Score, CWE, CVSS v3 breakdown (Attack Vector, Complexity, dll)
- **Share & Copy**: Share CVE info ke apps lain
- Powered by **NIST National Vulnerability Database API v2.0**

---

## 🚀 Setup & Run

### Prerequisites
```bash
flutter --version  # Minimal Flutter 3.10+
```

### 1. Install dependencies & Generate Env
```bash
cd pingnet_cve
flutter pub get
# Create .env file for API Key (Opsional)
echo "NVD_API_KEY=" > .env
# Run build_runner to generate Env class
dart run build_runner build -d
```

### 2. Download fonts (SpaceMono)
Buat folder `fonts/` di root project, download dari Google Fonts:
```bash
mkdir fonts
# Download SpaceMono-Regular.ttf dan SpaceMono-Bold.ttf
# dari https://fonts.google.com/specimen/Space+Mono
# Taruh di folder fonts/
```

Atau ganti font di `main.dart` ke font bawaan Flutter:
```dart
fontFamily: 'monospace',  // fallback tanpa custom font
```

### 3. Run di device/emulator
```bash
flutter run
```

### 4. Build APK
```bash
flutter build apk --release
# APK ada di build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔑 NVD API Key (Opsional tapi Dianjurkan)

Tanpa API key, NVD membatasi request ke ~5 req/30 detik.
Dengan API key gratis: unlimited.

1. Daftar di: https://nvd.nist.gov/developers/request-an-api-key
2. Buat file `.env` di root folder project.
3. Tambahkan key Anda:
```env
NVD_API_KEY=YOUR_KEY_HERE
```
4. Jalankan `dart run build_runner build -d` untuk meng-generate konfigurasi `envied`. API Key akan diobfuscate secara otomatis untuk keamanan.

---

## 📁 Struktur Project

```
lib/
├── main.dart                  # App entry, themes
├── screens/
│   ├── home_screen.dart       # Main screen (Network + tombol CVE)
│   ├── cve_search_screen.dart # CVE Search + News Feed
│   ├── cve_detail_screen.dart # Detail CVE dengan CVSS breakdown
│   ├── ping_result_screen.dart
│   ├── dns_screen.dart        # DNS, Traceroute, PortScan, HTTP, Whois, Geo
│   └── network_info_screen.dart
├── models/
│   └── cve_model.dart         # CVE data model + NVD JSON parser
├── services/
│   └── nvd_service.dart       # NVD API calls
└── widgets/
    ├── tool_button.dart       # Reusable tool button
    └── host_input.dart        # Host input dengan dropdown
```

---

## 🎨 Design

- **UI Style**: Modern Glassmorphism Dashboard, Soft Gradients, Premium Aesthetics
- **Font**: Space Mono (monospace, tech aesthetic)
- **Color scheme**: Teal (#006B7A) untuk Ping tools, Orange (#FF6B35) untuk CVE
- **Dark mode**: Full support, deep contrast colors
- **Navigasi**: Grouped features (Network Tests, Analysis, Info, Utils, dll)
- Tombol CVE Search: Highlighted dengan gradient + pulse animation

---

## ⚠️ Catatan

- Fitur ping ICMP mungkin membutuhkan root di beberapa device Android
- Port scan via TCP connect (bukan raw socket)
- Traceroute tidak tersedia di mobile (platform limitation)
- NVD API bisa lambat kadang-kadang (server NIST busy)
