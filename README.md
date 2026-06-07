# InSync Mac V1

Native macOS SwiftUI app plus a WidgetKit extension for tiny paired drawings.

## What is in this scaffold

- `InSync.xcodeproj` with two targets:
  - `InSync` macOS app
  - `InSyncWidgetExtension` WidgetKit extension
- Pairing flow:
  - welcome screen
  - create code
  - join code
  - waiting/polling state
- Drawing flow:
  - 512 x 384 canvas
  - black, pink, red, blue, green, yellow
  - pen, eraser, clear
  - PNG export
  - send and refresh buttons
- Widget flow:
  - reads `latest_partner_drawing.png` from local widget cache for testing
  - reads `latest_partner_updated_at` from local widget metadata for testing
  - opens `insync://open`
- Local testing backend:
  - file-backed pair records
  - automatic demo partner connection after creating a code
  - demo partner drawing for Refresh/widget testing
- Firebase-ready service layer:
  - anonymous auth
  - Firestore pair records
  - Storage uploads/downloads at `drawings/{pairCode}/{userId}/latest.png`
- Starter Firestore and Storage rules in `Rules/`.

## Setup checklist

1. Open `InSync.xcodeproj` in Xcode.
2. Change these placeholder identifiers to your real identifiers:
   - app bundle id: `com.yourname.insync`
   - widget bundle id: `com.yourname.insync.InSyncWidgetExtension`
   - app group id: `group.com.yourname.insync`
3. For local testing without an Apple development certificate, the project is set to "Sign to Run Locally" and the App Group entitlement is disabled.
4. For real widget sharing, sign in to Xcode, select your development team, enable the same App Group capability on both targets, and add `group.com.yourname.insync` back to both entitlements files.
5. The default project runs locally without Firebase packages. To enable the real backend later, add `https://github.com/firebase/firebase-ios-sdk.git` in Xcode and link:
   - FirebaseAuth
   - FirebaseCore
   - FirebaseFirestore
   - FirebaseStorage
6. Add Firebase to your Firebase project:
   - Anonymous Authentication
   - Firestore
   - Storage
7. Download the macOS app `GoogleService-Info.plist` from Firebase.
8. Add that plist to `InSync/Resources/` and include it in the `InSync` app target.
9. Deploy or paste the rules from `Rules/firestore.rules` and `Rules/storage.rules`.
10. Build and run the app target.

The app intentionally does not perform live sync. Refresh is manual in V1. Local widget testing uses `/tmp/InSyncWidgetCache`; production widget sharing should use the App Group entitlement.

## Important V1 limitations

- No account UI.
- No multiple partners.
- No live drawing.
- No drawing inside the widget.
- No notifications.
- No drawing history.

## Useful files

- App entry: `InSync/InSyncApp.swift`
- App state: `InSync/AppState.swift`
- Firebase service: `InSync/Services/FirebaseService.swift`
- Local backend: `InSync/Services/LocalBackendService.swift`
- Widget storage: `InSync/Services/WidgetStorageService.swift`
- Canvas: `InSync/Drawing/DrawingCanvasView.swift`
- PNG export: `InSync/Drawing/CanvasRenderer.swift`
- Widget: `InSyncWidgetExtension/InSyncWidget.swift`
