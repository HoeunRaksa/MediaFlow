# iPhone presentation

The application uses its existing AppState, repositories, calculation services,
and calculator controllers. Phone presentation is implemented by
`lib/core/ios/iphone_design.dart` and `iphone_controls.dart`. Native Windows
keeps the desktop shell, palette, and Material controls, including narrow windows.

## Screen audit and implementation

| Workflow | Phone presentation |
| --- | --- |
| Ceiling calculator | Full-width Room / Products / Results steps; retained input controllers and selected products |
| PVC calculator | Full-width quantity workspace with existing product and pricing controls |
| Measurement / insulation / LED / wire / decoration / custom | Shared full-width workspace steps |
| Product catalog | Search, filter strips, lazy lists, wrapping cards, visible edit actions |
| Prices, packaging, product kinds, formulas | Existing data and edit workflows inside phone-width cards |
| Units and categories | Vertical panels instead of side-by-side columns |
| Current sale | Vertical cards containing the original table's values; existing invoice workflow |
| Settings | Adaptive switches and existing persistent preferences |
| Product / price / packaging / override / customer-document editors | Cupertino drag-dismiss sheets, constrained scrollable forms, keyboard-aware layout |
| Photos | Full-screen pinch-to-zoom viewer; long-press action sheet |
| Secondary destinations | Independent Cupertino navigation stack per bottom tab, horizontal transitions, edge-back gesture |

Navigation is translucent; content surfaces are opaque for contrast and lower
compositing cost. Semantic dark colors are resolved only on phone presentation
and cached. Khmer typography includes an explicitly bundled Latin font fallback.
The More screen uses a collapsing large title. Inputs preserve formatters,
callbacks, validation text, and their existing controllers. Buttons and compact
controls use at least 44 logical pixels where the surrounding layout permits.

## Home Screen and viewport

`web/index.html` configures viewport-fit, dynamic viewport height, an actual app
launch placeholder, automatic appearance metadata, and the Apple touch icon.
The manifest uses standalone display and allows both orientations. Icons are
derived from the existing brand logo. Flutter safe areas handle actual system
insets; the app does not draw a simulated status bar or Dynamic Island.

Local test URL: http://192.168.1.6:8765/

The server serves only `build/web` and remains running independently of the
chat. The existing firewall rule restricts access to the local Wi-Fi subnet.
Keep the PC awake and connected to the same Wi-Fi while using this local URL.

## Verification and limits

Automated widget tests exercise 375×667, 393×852, 430×932, and 932×430 layouts in
both appearances, calculator steps, tab changes, catalog editor keyboard insets,
secondary navigation, and edge-back gestures. Existing business and desktop tests
continue to run. Rendered previews are stored in `.tool-state/web-setup/`.

Physical Safari, standalone Home Screen launch, Safari chrome resizing, actual
Dynamic Island/home-indicator insets, VoiceOver, and device frame rate have not
been verified. Browser automation was disabled during this task. No 60/120 FPS
measurement is claimed. Flutter/Cupertino approximates iOS UI; it does not use
UIKit's native Liquid Glass rendering engine.

The local HTTP origin is not a secure context. Offline service-worker
installation, some clipboard/share APIs, and other secure-context features may
be unavailable. Standalone metadata does not make the local app independently
available when the PC server is offline. This task does not publish a hosted app.

The existing browser limitations remain: native C++ cut-layout optimization is
unavailable in the web build, Safari stores its data separately from Windows,
and desktop filesystem dialogs are replaced by browser-supported operations.
No video workflow existed in the current application; photo presentation does
not add a new media backend.
