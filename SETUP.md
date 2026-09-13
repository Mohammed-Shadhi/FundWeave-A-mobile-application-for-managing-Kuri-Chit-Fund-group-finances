# Kuri App — Setup Guide

## 1. Firebase Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Connect to your Firebase project
flutterfire configure
```

This generates `lib/firebase_options.dart` automatically.

## 2. Firebase Console — Enable Services

| Service | Steps |
|---|---|
| Authentication | Auth → Sign-in method → Email/Password → Enable |
| Firestore | Firestore Database → Create Database → Start in test mode |

## 3. Firestore Security Rules

Go to **Firebase Console → Firestore → Rules**, paste contents of `firestore.rules`, click **Publish**.

## 4. Razorpay Setup

1. Create account at [razorpay.com](https://razorpay.com)
2. Get your API Key from Dashboard → Settings → API Keys
3. Open `lib/utils/app_helpers.dart` and replace:

```dart
static const String razorpayKeyId = 'rzp_test_YOUR_KEY_HERE';
```

## 5. Backend Payment Verification (IMPORTANT)

In `lib/screens/auth/become_admin_screen.dart`, the `_simulateBackendVerification` method
is a placeholder. In production, replace it with a real backend call:

```dart
// Your backend must verify:
// HMAC_SHA256(orderId + "|" + paymentId, razorpaySecretKey) == signature
Future<bool> _simulateBackendVerification({...}) async {
  final response = await http.post(
    Uri.parse(AppConstants.backendVerifyUrl),
    body: {'orderId': orderId, 'paymentId': paymentId, 'signature': signature},
  );
  return response.statusCode == 200;
}
```

## 6. Android Permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
```

Inside `<application>` tag:

```xml
<activity
    android:name="com.razorpay.CheckoutActivity"
    android:configChanges="keyboard|keyboardHidden|orientation|screenSize"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

## 7. android/app/build.gradle

Make sure `minSdkVersion` is at least 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

## 8. Run

```bash
flutter pub get
flutter run
```

## User Roles & Flow

```
Register → user role (basic)
         → "Become Admin" → Pay ₹199 via Razorpay
         → role = admin, shop created

Admin creates members → member gets login credentials
Member logs in → sees their kuri groups & payments

Platform Admin → approves/rejects shops, views stats
```

## Firestore Collections

```
users/          → all user accounts
shops/          → shop details + subscription
members/        → member records with search keywords
kuris/          → kuri groups
payments/       → payment records (immutable)
receipts/       → receipt records (immutable)
```

## First Time Setup Order

1. Register as **Platform Admin** (you, the developer)
   - Use a secret code stored in `lib/utils/app_helpers.dart`
   - Or manually set role = 'platform_admin' in Firestore

2. Register as **Admin** (shop owner)
   - Completes Razorpay payment
   - Platform admin approves (or auto-approved after payment)

3. Admin creates **Members**
   - Admin logs in, goes to Members, taps + Add Member
   - Shares email/password with member

4. Member logs in with credentials admin gave them
