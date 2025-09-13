# API Documentation

## WebViewManager

The `WebViewManager` class provides a comprehensive interface for managing WebKit web views with native macOS integration.

### Properties

#### Published Properties
```swift
@Published var isLoading: Bool
@Published var canGoBack: Bool  
@Published var canGoForward: Bool
@Published var title: String
@Published var url: URL?
```

These properties automatically update the UI when the web view state changes.

### Methods

#### Core Navigation
```swift
func load(url: URL)
func reload()
func goBack()
func goForward()
```

#### JavaScript Integration
```swift
func executeJavaScript(_ script: String, completion: @escaping (Any?, Error?) -> Void)
```

Execute JavaScript code in the web view and get the result.

**Example:**
```swift
webViewManager.executeJavaScript("document.title") { result, error in
    if let title = result as? String {
        print("Page title: \(title)")
    }
}
```

#### CSS Injection
```swift
func injectCSS(_ css: String)
```

Inject custom CSS styles into the web page for better macOS integration.

**Example:**
```swift
webViewManager.injectCSS("""
    body {
        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
        background-color: #f5f5f5;
    }
""")
```

#### Configuration
```swift
func updateJavaScriptEnabled(_ enabled: Bool)
func updateAllowPopups(_ allow: Bool)
func clearWebData()
```

#### WebView Creation
```swift
func createWebView() -> WKWebView
```

Creates and configures a new WKWebView instance with proper delegates and settings.

### JavaScript Bridge

The WebViewManager automatically injects a JavaScript bridge that allows web content to communicate with the native app.

#### Available Methods
```javascript
// Send messages to native app
window.nativeApp.postMessage(message);

// Platform information
window.nativeApp.platform; // "macOS"
window.nativeApp.version;  // App version
```

#### Message Types

##### Console Logging
```javascript
// Automatically captured by native app
console.log("This will appear in native app logs");
```

##### Page Ready Notification
```javascript
// Automatically sent when page loads
// No manual action needed
```

##### Custom Notifications
```javascript
window.nativeApp.postMessage({
    type: 'notification',
    title: 'Hello from Web',
    body: 'This shows as a native macOS notification'
});
```

### Delegates

#### WKNavigationDelegate
Handles navigation events, security policies, and error handling.

#### WKUIDelegate  
Manages JavaScript dialogs, popup windows, and UI interactions.

#### WKScriptMessageHandler
Processes messages from JavaScript bridge.

### Configuration

#### Default Settings
- JavaScript: Enabled
- Pop-ups: Disabled
- Website Data Store: Default
- Automatic graphics switching: Enabled

#### Security
- External links open in default browser
- JavaScript alerts show as native dialogs
- Network requests follow App Transport Security

## MainContentView

SwiftUI view providing the main application interface.

### Components

#### Sidebar Navigation
- Web Content tab with WebKit integration
- Native Features tab with system integrations  
- Settings tab with configuration options

#### Toolbar
- Navigation controls (back, forward, reload)
- Context-sensitive buttons
- Loading indicators

### State Management
Uses `@StateObject` and `@ObservedObject` for reactive UI updates.

## AppDelegate

Manages application lifecycle and native macOS integrations.

### Key Features

#### Window Management
```swift
private func setupWindow()
```
- Creates main window with proper styling
- Configures title bar appearance
- Sets up window state persistence

#### Menu Bar Integration
```swift
private func setupMenuBar()
```
- Standard macOS menu structure
- Keyboard shortcuts
- Context-appropriate menu items

#### Status Bar Item
```swift
private func setupStatusBarItem()
```
- System menu bar integration
- Quick access menu
- App visibility controls

### Menu Actions
- File operations (New, Open, Close)
- Window management (Minimize, Zoom)
- Application controls (About, Preferences, Quit)

## Native Features Integration

### Notifications
```swift
func sendNotification()
func requestNotificationPermission()
```

Uses `UserNotifications` framework for native notification support.

### System Integration
- Finder integration
- Window management
- Alert dialogs
- File system access

### Settings Persistence
Uses `@AppStorage` for automatic UserDefaults integration:
```swift
@AppStorage("defaultURL") private var defaultURL = "https://example.com"
@AppStorage("enableJavaScript") private var enableJavaScript = true
```

## Testing API

### Unit Tests
```swift
XCTAssertNotNil(webViewManager)
XCTAssertFalse(webViewManager.isLoading)
```

### Integration Tests
Full app functionality testing including:
- WebView creation and configuration
- JavaScript execution
- CSS injection
- Navigation functionality

### Performance Tests
Benchmarking critical operations:
- WebView creation time
- JavaScript execution performance
- Memory usage patterns

## Error Handling

### WebKit Errors
- Navigation failures
- JavaScript execution errors
- Network connectivity issues

### Native Errors
- Notification permission failures
- File system access errors
- Window management issues

### Logging
Comprehensive logging throughout the application:
- WebKit navigation events
- JavaScript console output
- Native app state changes
- Error conditions and recovery

## Security Considerations

### Web Content
- External link handling
- JavaScript sandboxing
- Network security policies

### Native Integration
- Entitlements configuration
- Sandbox compatibility
- Code signing requirements

### Data Protection
- Web data clearing
- Cache management
- User privacy considerations