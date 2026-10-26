# OfficeConnect Mobile (Flutter for Android & iOS)

> Enterprise Employee Self-Service (ESS) & Manager Self-Service (MSS) mobile application built with **Flutter 3.x** and **Dart 3.x**.

---

## 📱 Features Included

1. **Authentication & Biometrics**:
   - Corporate login with Employee Code & Password
   - Face ID & Fingerprint authentication (`local_auth`)
   - JWT token auto-refresh with Dio interceptors
   - Secure KeyStore / Keychain credentials caching

2. **Smart Attendance**:
   - **One-tap Clock In / Clock Out** with live work hours timer
   - **GPS Geofence Validation** (Office coordinates & allowed radius)
   - **Live Selfie Punching** via camera
   - Shift information & grace period display
   - Monthly punch history & regularization requests

3. **Leave Management**:
   - Real-time leave balance cards (CL, SL, EL)
   - Apply for single day, half day, or date-range leaves
   - Comprehensive leave application history with live status badges

4. **Expense Claims & Invoices**:
   - Create claims under **Claim Category** (`GENERAL`, `PROJECT`, `SALES`)
   - **Camera Receipt Scanner**: Snap and attach invoice photos
   - Automatic claim total calculation from uploaded bills
   - Header locking rules (once bills are uploaded, claim details are protected)
   - Own vehicle mileage calculation
   - Real-time finance tracking (`APPLIED`, `APPROVED`, `SETTLED`)

5. **Payroll & Compensation**:
   - Latest net payout highlight card with gross vs deduction breakdown
   - Monthly salary slips browser
   - In-app encrypted PDF download & sharing

6. **Manager Approvals (To-Do Hub)**:
   - Dedicated review inbox for reporting managers
   - 1-click Approve or Reject for team leaves and expense claims

7. **Colleague Directory & Digital ID Badge**:
   - Searchable company directory by name, role, department
   - 1-tap Phone Call or Email
   - Digital Employee ID badge with QR code

---

## 🛠 Prerequisites & Installation

### 1. Install Flutter SDK
If Flutter SDK is not yet configured on your workstation:
1. Download Flutter SDK (Windows) from [flutter.dev](https://docs.flutter.dev/get-started/install/windows/mobile).
2. Extract to `C:\src\flutter` (or `C:\flutter`).
3. Add `C:\src\flutter\bin` to your Windows User `PATH` environment variable.
4. Verify by opening a terminal and running:
   ```bash
   flutter doctor
   ```

### 2. Configure Backend Server
The app points by default to:
- Android Emulator: `http://10.0.2.2:8099`
- Physical Android/iOS Device on local WiFi: `http://<your-lan-ip>:8099` (e.g. `http://192.168.100.133:8099`)

You can modify the default host in:
[`lib/core/constants/api_endpoints.dart`](lib/core/constants/api_endpoints.dart)

### 3. Run the App

```bash
cd D:\PROJECTS\office_mobile

# Install packages
flutter pub get

# Run on connected Android device or emulator
flutter run

# Build Android Release APK
flutter build apk --release

# Build Android App Bundle (for Google Play Store)
flutter build appbundle --release

# Build iOS Archive (on macOS)
flutter build ipa --release
```

---

## 📁 Architecture Directory Layout

```
lib/
├── app.dart                   # MaterialApp, routing & global themes
├── main.dart                  # App bootstrap & session verification
├── core/
│   ├── constants/             # AppColors, ApiEndpoints
│   ├── network/               # ApiClient (Dio + JWT refresh interceptor)
│   ├── storage/               # SecureStorageService (Tokens & Biometrics)
│   ├── theme/                 # OfficeConnect Material 3 theme
│   └── utils/                 # GeofenceHelper (GPS validation)
├── features/
│   ├── approvals/             # Manager To-Do approval queue
│   ├── attendance/            # Punch in/out, Geofence, Selfie
│   ├── auth/                  # Login, Biometrics, UserModel
│   ├── dashboard/             # Central employee dashboard
│   ├── directory/             # Colleague search & 1-tap call/email
│   ├── expenses/              # Expense claims & invoice receipts
│   ├── leaves/                # Leave balances & apply leave form
│   ├── payroll/               # Payslips & encrypted PDF download
│   └── profile/               # Digital ID badge QR & settings
└── shared/
    └── widgets/               # AppCard, PrimaryButton, StatusBadge
```
