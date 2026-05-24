# Network + CVE Tools - Flutter App

A comprehensive integration of **Network Tools** and **CVE Search** (powered by the NIST NVD API).

---

## 📱 Features

### Network Tools
- Ping IPv4 / IPv6 / TCP
- DNS Lookup & Reverse DNS
- HTTP Headers
- Port Range Scan (common ports)
- Network Info (public IP, geolocation)
- Subnet Calculator & Subnet Scan
- Hex Calculator (NEW)
- Random Password Generator (NEW)
- SSL Scan, Secure DNS, Dig, Is it up?, IDN ↔ ACE, Spam Check
- Whois / RDAP
- And more...

### CVE Search (NEW - Integrated)
- **News Feed**: Real-time latest HIGH/CRITICAL CVEs from NVD
- **Search**: Search by keyword (e.g., "Apache", "Log4J2") or direct CVE-ID
- **Detail View**: Score, CWE, CVSS v3 breakdown (Attack Vector, Complexity, etc.)
- **Share & Copy**: Quickly share CVE info to other apps
- Powered by the **NIST National Vulnerability Database API v2.0**

---

## 🚀 Setup & Run

### Prerequisites
```bash
flutter --version  # Minimum Flutter 3.10+
```

### 1. Install Dependencies & Generate Env
```bash
cd Pingnet_cve
flutter pub get
# Create a .env file for the API Key (Optional)
echo "NVD_API_KEY=" > .env
# Run build_runner to generate the Env class
dart run build_runner build -d
```

### 2. Download Fonts (SpaceMono)
Create a `fonts/` folder in the project root and download it from Google Fonts:
```bash
mkdir fonts
# Download SpaceMono-Regular.ttf and SpaceMono-Bold.ttf
# from https://fonts.google.com/specimen/Space+Mono
# Place them in the fonts/ folder
```

Or change the font in `main.dart` to Flutter's default fallback font:
```dart
fontFamily: 'monospace',  // fallback without custom font
```

### 3. Run on Device/Emulator
```bash
flutter run
```

### 4. Build APK
```bash
flutter build apk --release
# The APK is located at build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔑 NVD API Key (Optional but Recommended)

Without an API key, the NVD limits requests to ~5 requests per 30 seconds.
With a free API key, you get a much higher rate limit for faster and uninterrupted requests.

1. Register at: https://nvd.nist.gov/developers/request-an-api-key
2. Create a `.env` file in the root folder of the project.
3. Add your key:
```env
NVD_API_KEY=YOUR_KEY_HERE
```
4. Run `dart run build_runner build -d` to generate the `envied` configuration. The API Key will be obfuscated automatically for maximum security.

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry point, themes
├── screens/
│   ├── home_screen.dart       # Main screen (Network + CVE buttons)
│   ├── cve_search_screen.dart # CVE Search + News Feed
│   ├── cve_detail_screen.dart # CVE Detail with CVSS breakdown
│   ├── ping_result_screen.dart
│   ├── dns_screen.dart        # DNS, Traceroute, PortScan, HTTP, Whois, Geo
│   └── network_info_screen.dart
│   └── speed_test_screen.dart # Speed Test tool
├── models/
│   └── cve_model.dart         # CVE data model + NVD JSON parser
├── services/
│   └── nvd_service.dart       # NVD API calls
└── widgets/
    ├── tool_button.dart       # Reusable tool button
    └── host_input.dart        # Host input with dropdown
```

---

## 🎨 Design

- **UI Style**: Modern Glassmorphism Dashboard, Soft Gradients, Premium Aesthetics
- **Font**: Space Mono (monospace, tech aesthetic)
- **Color Scheme**: Teal (#006B7A) for Ping tools, Orange (#FF6B35) for CVE
- **Dark Mode**: Full support, deep contrast colors
- **Navigation**: Grouped features (Network Tests, Analysis, Info, Utils, etc.)
- **CVE Search Button**: Highlighted with a gradient + pulse animation

---

## ⚠️ Notes

- The ICMP Ping feature might require root access on some Android devices.
- Port scan is done via TCP connect (not raw sockets).
- Traceroute is not fully supported on mobile platforms due to operating system limitations.
- The NVD API can occasionally be slow or unresponsive when the NIST servers are busy.
