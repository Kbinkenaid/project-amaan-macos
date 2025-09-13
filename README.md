# Project Amaan - Native macOS Application

A professional cybersecurity toolkit for macOS, converted from the original web application to provide native performance and integration.

## 🛡️ Features

### 🔍 Breach Detection
- **Email Breach Checking**: Integration with HaveIBeenPwned API
- **Domain Breach Analysis**: Comprehensive domain security assessment
- **Real-time Results**: Live breach data with detailed reporting

### 🌐 Network Security Tools
- **Port Scanner**: TCP port scanning with service detection
- **WHOIS Lookup**: Domain registration information retrieval
- **DNS Analysis**: Comprehensive DNS record resolution

### 🔧 Encoding & Cryptography Suite
- **Base64 Encoding/Decoding**
- **URL Encoding/Decoding** 
- **HTML Entity Encoding/Decoding**
- **Cryptographic Hashing**: MD5, SHA-256
- **Hexadecimal Conversion**
- **Text Extraction**: HTML tag removal with entity decoding

## 🚀 Quick Start

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/kbinkenaid/project-amaan-macos.git
cd project-amaan-macos
```

2. **Build and run:**
```bash
swift build
swift run ProjectAmaan
```

### Alternative: Xcode
```bash
swift package generate-xcodeproj
open ProjectAmaan.xcodeproj
```

## 🏗️ Architecture

### Project Structure
```
Sources/
├── ProjectAmaan/          # Main SwiftUI application
│   ├── WorkingApp.swift          # App entry point
│   ├── WorkingBreachView.swift   # Breach detection UI
│   ├── WorkingNetworkView.swift  # Network tools UI
│   └── WorkingEncodingView.swift # Encoding suite UI
└── SecurityTools/         # Core security framework
    ├── BreachDetectionManager.swift
    ├── NetworkToolsManager.swift
    ├── EncodingToolsManager.swift
    └── SecurityTypes.swift
```

### Technology Stack
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with ObservableObject
- **Networking**: URLSession, Network.framework
- **Cryptography**: CryptoKit
- **Concurrency**: Swift async/await
- **Package Management**: Swift Package Manager

## 🔧 Configuration

### HaveIBeenPwned API (Optional)
For enhanced breach detection functionality:
1. Get an API key from [HaveIBeenPwned](https://haveibeenpwned.com/API/Key)
2. The app will prompt for the API key on first use, or you can set it in macOS System Preferences

### Network Tools
All network tools use native macOS APIs:
- Port scanning via Network.framework
- WHOIS via system `/usr/bin/whois` command
- DNS resolution via Core Foundation

## 🧪 Testing

Run the comprehensive test suite:
```bash
swift test
```

## 📦 Dependencies

- **Swift NIO**: High-performance networking
- **Swift Crypto**: Cryptographic operations
- **SwiftUI**: Native macOS user interface

## 🔒 Security & Privacy

- **Local Processing**: All operations performed locally where possible
- **Secure Storage**: API keys stored in macOS Keychain
- **Network Security**: HTTPS-only connections with certificate validation
- **Sandboxing**: Runs within macOS security sandbox

## 📱 System Requirements

- **macOS**: 14.0 (Sonoma) or later
- **Architecture**: Universal (Intel & Apple Silicon)
- **Memory**: 256MB RAM minimum
- **Storage**: 50MB available space

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- **Web Version**: [project-amaan-webapp](https://github.com/kbinkenaid/project-amaan-webapp)
- **Original Concept**: Professional cybersecurity toolkit

## 🛠️ Development

### Build Configuration
```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests
swift test

# Generate documentation
swift package generate-documentation
```

### Code Style
This project follows Swift best practices:
- SwiftLint for code style
- Swift Package Manager for dependencies
- Modern async/await concurrency
- MVVM architecture pattern

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/kbinkenaid/project-amaan-macos/issues)
- **Security**: Please report security vulnerabilities privately

## 🎯 Roadmap

- [ ] macOS App Store distribution
- [ ] Additional network tools
- [ ] Enhanced breach detection features
- [ ] Dark mode support
- [ ] Accessibility improvements

---

**Project Amaan macOS** - Professional cybersecurity toolkit for macOS developers and security researchers.