# Chat Encryption Viewer

**Open-source proof-of-concept demonstrating encrypted chat storage in chuk_chat**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)

## 🔒 What is This?

This is a **transparency tool** that demonstrates how chats are encrypted in the [chuk_chat](https://github.com/yourusername/chuk_chat) application. It allows users to:

1. **Login** with their chuk_chat credentials
2. **See encrypted** chat data (as it's stored on your device)
3. **Toggle** between encrypted and decrypted views
4. **Verify** that encryption is working properly

## 🎯 Purpose

This app exists to prove to users that:
- ✅ Their chats are **encrypted client-side**
- ✅ The server **never sees** plaintext messages
- ✅ Only the user's password can decrypt their chats
- ✅ Encryption uses **industry-standard algorithms**

## 🔐 Encryption Details

### Algorithms Used

| Component | Algorithm | Details |
|-----------|-----------|---------|
| **Encryption** | AES-256-GCM | Advanced Encryption Standard with 256-bit keys |
| **Key Derivation** | PBKDF2-HMAC-SHA256 | 600,000 iterations (very secure!) |
| **Nonce Generation** | Cryptographically Secure Random | 12-byte nonces for GCM mode |
| **MAC** | GCM built-in authentication | Ensures data integrity |

### How It Works

```
1. User enters password
   ↓
2. PBKDF2 derives encryption key (600,000 iterations)
   ↓
3. Key is stored locally (never sent to server)
   ↓
4. Messages are encrypted with AES-256-GCM before storage
   ↓
5. Encrypted payload includes:
   - Version number
   - Nonce (random)
   - Ciphertext (encrypted message)
   - MAC (authentication tag)
```

### Example Encrypted Message

When you toggle to "Encrypted" view, you'll see something like this:

```json
{
  "v": "1",
  "nonce": "8Kx2mPqR3nF5tLwZ",
  "ciphertext": "5YzN8pQr2hK9xM3vB7wL...",
  "mac": "1FgT4hJ6kN9pR2sV5yB8..."
}
```

This is **exactly** how your chats are stored on your device!

## 🚀 Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) 3.0 or higher
- An account on chuk_chat (or the demo Supabase instance)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/chat_encryption_viewer.git
cd chat_encryption_viewer

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Usage

1. **Sign in** with your chuk_chat email and password
2. **View demo chats** with sensitive information
3. **Toggle** between "Encrypted" and "Decrypted" views
4. **Inspect** the encryption format

## 📸 Screenshots

### Login Screen
Clean, simple authentication interface.

### Encrypted View
Shows the raw encrypted JSON as it's stored on your device.

### Decrypted View
Shows the plaintext message (only visible with your password).

## 🔬 Code Structure

```
lib/
├── main.dart                    # Main app with login and viewer UI
├── encryption_demo_service.dart # Simplified encryption service
└── supabase_config.dart         # Backend configuration
```

### Key Files

#### `encryption_demo_service.dart`
Demonstrates the same encryption used in chuk_chat:
- PBKDF2 key derivation (600,000 iterations)
- AES-256-GCM encryption/decryption
- Secure random nonce generation

#### `main.dart`
Simple Flutter app that:
- Authenticates users
- Creates demo chats
- Shows encrypted vs decrypted views

## 🛡️ Security Features

### ✅ Client-Side Encryption
- All encryption happens **on your device**
- Server only stores encrypted data
- Your password **never leaves your device**

### ✅ Key Derivation
- PBKDF2 with 600,000 iterations
- Makes brute-force attacks impractical
- Salt is unique per user

### ✅ Authentication
- GCM mode provides built-in authentication
- Detects any tampering with encrypted data
- Prevents bit-flipping attacks

### ✅ Random Nonces
- Each message uses a unique random nonce
- Prevents pattern analysis
- Ensures same message encrypts differently each time

## 🤝 Contributing

This is an open-source transparency tool! Contributions are welcome:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This is a **demonstration tool** to show how encryption works. It uses simplified key storage (SharedPreferences) for demo purposes. The main chuk_chat app uses more secure storage (flutter_secure_storage).

## 🔗 Related Projects

- [chuk_chat](https://github.com/yourusername/chuk_chat) - The main chat application

## ❓ FAQ

### Q: Is this the same encryption as chuk_chat?
**A:** Yes! Same algorithms (AES-256-GCM, PBKDF2), same parameters (600k iterations), same format.

### Q: Can the server read my messages?
**A:** No! Encryption happens on your device. The server only sees encrypted blobs.

### Q: What if I forget my password?
**A:** Your data cannot be decrypted without your password. This is by design for security.

### Q: Why 600,000 PBKDF2 iterations?
**A:** This makes brute-force attacks very expensive. Each password guess takes ~0.5 seconds on modern hardware.

### Q: Can I verify the encryption myself?
**A:** Yes! That's the whole point of this app. You can see the encrypted data and verify it matches the encrypted view.

## 📞 Support

If you have questions or concerns about encryption in chuk_chat:
- Open an issue on this repository
- Review the source code (it's open source!)
- Test it yourself with this viewer app

## 🙏 Acknowledgments

- [Supabase](https://supabase.com) - Backend infrastructure
- [Cryptography Package](https://pub.dev/packages/cryptography) - Dart cryptography library
- [Flutter](https://flutter.dev) - UI framework

---

**Made with ❤️ for transparency and privacy**
