# macOS Native Application

A modern native macOS application built with Swift and SwiftUI, featuring web content integration through WebKit and native macOS system integration.

## Features

### 🖥️ Native macOS Experience
- **SwiftUI Interface**: Modern, responsive UI following macOS design guidelines
- **Menu Bar Integration**: Full native menu bar with standard macOS shortcuts
- **Status Bar Item**: Quick access from the menu bar
- **Window Management**: Proper window state persistence and management
- **Notifications**: Native macOS notification support

### 🌐 Web Content Integration
- **WebKit Integration**: Seamless web content rendering
- **JavaScript Bridge**: Communication between web content and native app
- **Custom CSS Injection**: Enhanced styling for better macOS integration
- **Navigation Controls**: Back, forward, reload functionality
- **External Link Handling**: Smart handling of external links

### ⚙️ Advanced Features
- **Multi-tab Interface**: Sidebar navigation between different sections
- **Settings Management**: Persistent user preferences
- **Web Data Management**: Clear cache and cookies functionality
- **Security**: Proper handling of web security and permissions

## Architecture

### Project Structure
```
macOS-App/
├── Sources/MacOSApp/          # Main application source code
│   ├── main.swift            # Application entry point and delegate
│   ├── MainContentView.swift # Main SwiftUI interface
│   └── WebViewManager.swift  # WebKit integration and management
├── Tests/MacOSAppTests/       # Unit and integration tests
├── Scripts/                  # Build and utility scripts
├── Documentation/            # Project documentation
└── Package.swift            # Swift Package Manager configuration
```

### Core Components

#### AppDelegate
- Application lifecycle management
- Window setup and configuration
- Menu bar and status item setup
- Native macOS integrations

#### MainContentView
- SwiftUI-based user interface
- Multi-section sidebar navigation
- Toolbar and navigation controls
- Settings and preferences UI

#### WebViewManager
- WebKit configuration and management
- JavaScript bridge implementation
- Navigation and loading state management
- CSS injection and customization
- Web data and cache management

## Building and Running

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Build from Source
```bash
# Clone and navigate to project
cd macOS-App

# Build using Swift Package Manager
swift build --configuration release

# Or use the build script
./Scripts/build.sh
```

### Run Tests
```bash
# Run all tests
swift test

# Or use the test script with coverage
./Scripts/test.sh
```

### Create App Bundle
The build script automatically creates a proper macOS app bundle:
```bash
./Scripts/build.sh
# Creates: dist/MacOSApp.app
# Symlink: MacOSApp.app (in project root)
```

### Running the App
```bash
# Run directly
swift run

# Or run the app bundle
open MacOSApp.app
```

## Development

### Key Technologies
- **Swift 5.9**: Modern Swift with async/await support
- **SwiftUI**: Declarative UI framework
- **WebKit**: Web content rendering and JavaScript integration
- **UserNotifications**: Native notification support
- **Swift Package Manager**: Dependency management and building

### Code Quality
- **Unit Tests**: Comprehensive test coverage
- **Integration Tests**: Full app functionality testing
- **Performance Tests**: Benchmarking critical paths
- **Static Analysis**: SwiftLint integration
- **Memory Management**: Proper ARC and resource cleanup

### WebKit Integration
The app provides a sophisticated WebKit integration:

```swift
// JavaScript Bridge Example
window.nativeApp.postMessage({
    type: 'notification',
    title: 'Hello from Web',
    body: 'This will show as a native notification'
});
```

### Customization
The app can be easily customized:
- **Branding**: Update `Info.plist` and app icons
- **URL Handling**: Modify default URLs and navigation behavior
- **Native Features**: Add new native integrations
- **UI Themes**: Customize SwiftUI appearance

## Distribution

### Code Signing
For distribution, the app needs to be code signed:
```bash
# The build script will automatically sign if certificates are available
./Scripts/build.sh

# Manual signing
codesign --force --options runtime \
  --entitlements build/entitlements.plist \
  --sign "Developer ID Application: Your Name" \
  MacOSApp.app
```

### Notarization (for public distribution)
```bash
# Create a ZIP archive
ditto -c -k --keepParent MacOSApp.app MacOSApp.zip

# Submit for notarization
xcrun notarytool submit MacOSApp.zip \
  --apple-id "your-apple-id@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password"
```

### App Store Distribution
The app can be prepared for App Store distribution by:
1. Enabling sandboxing in entitlements
2. Adding required App Store metadata
3. Following App Store Review Guidelines

## Configuration

### Info.plist Settings
Key configuration options in `Info.plist`:
- `CFBundleIdentifier`: Unique app identifier
- `LSMinimumSystemVersion`: Minimum macOS version
- `NSAppTransportSecurity`: Network security settings
- `NSUserNotificationAlertStyle`: Notification appearance

### Entitlements
Security and capability settings:
- Network access permissions
- File system access
- Notification permissions
- Sandbox configuration (optional)

## Troubleshooting

### Common Issues
1. **Build Errors**: Ensure Xcode and Swift versions meet requirements
2. **Code Signing**: Check that valid certificates are installed
3. **Permissions**: Grant necessary permissions for notifications and network access
4. **WebView Loading**: Check network connectivity and URL validity

### Debug Mode
Enable debug output by setting environment variable:
```bash
SWIFT_DEBUG=1 ./MacOSApp.app/Contents/MacOS/MacOSApp
```

## Contributing

### Development Setup
1. Clone the repository
2. Open in Xcode or use command line tools
3. Run tests to ensure everything works
4. Make changes and test thoroughly
5. Update documentation as needed

### Testing
- Write unit tests for new functionality
- Test on multiple macOS versions
- Verify memory usage and performance
- Test web content integration scenarios

## License

This project is available under the MIT License. See the LICENSE file for more information.

## Support

For questions, issues, or contributions:
- Open an issue on the project repository
- Check the documentation in the `Documentation/` folder
- Review test cases for usage examples