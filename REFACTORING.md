# GPT Computer Refactoring Plan

## Current State Analysis

### Project Structure
```
agent-webkit/
├── Sources/GPT Computer/          # 62 Swift files, ~26,808 lines, single flat directory
├── Icon/icon.swift                # App icon generator
├── Installer/                     # DMG installer assets
│   ├── background.swift
│   └── dmg.py
├── skill/agent-webkit-bench/      # Bench skill definition
│   └── SKILL.md
├── bench                          # Python bench script (~298 lines)
├── build.sh                       # Release build script (~241 lines)
├── build-fast.sh                  # Fast debug build script (~73 lines)
├── fresh.sh                       # Test world launcher
├── ideas                          # Python ideas/roadmap tool (~388 lines)
├── publish.sh                     # Release publishing
├── tap.sh                         # Homebrew tap updater
├── Package.swift                  # Swift Package Manager config
├── GPT Computer.entitlements      # Base entitlements
├── GPT Computer.passkeys.entitlements # Passkeys entitlements
├── VERSION                        # Version string
├── README.md / ROADMAP.md / SECURITY.md / CONTRIBUTING.md / NOTES.md
└── .github/screenshot.png
```

### Key Metrics
- **62 Swift files** in a single flat directory
- **~26,808 total lines** of Swift code
- **Largest files**: ExtensionShims.swift (3,291), Browser.swift (2,304), Tab.swift (1,670), Bench.swift (1,626)
- **0 test files** — no test coverage at all
- **15+ import frameworks** (SwiftUI, AppKit, WebKit, Foundation, Combine, Security, CryptoKit, etc.)

### Architectural Issues Identified

#### 1. Flat Source Directory (Critical)
All 62 files live directly in `Sources/GPT Computer/` with no logical grouping. Files with related functionality are scattered:
- **UI**: App.swift, Settings.swift, Welcome.swift, Omnibox.swift, TabBar.swift, Side.swift, Fold.swift, Little.swift, Float.swift, Plate.swift, Peek.swift, SiteCard.swift, ImageMenu.swift, StatusLine.swift, FrameRate.swift, Lights.swift, Inspector.swift, Reader.swift, Dialogs.swift, Forms.swift, AutoScroll.swift, Swipe.swift, SpaceSwipe.swift, Spaces.swift, Sleep.swift, Hidden.swift, Curtain.swift, Shield.swift, Vault.swift, Passwords.swift, Passkeys.swift, History.swift, Bookmarks.swift, BookmarksBar.swift, Loot.swift, Import.swift, Sharing.swift, Registrable.swift, Recall.swift, Session.swift, Address.swift, Engine.swift, Links.swift, Icons.swift, StoreRelay.swift, ExtensionNative.swift, ExtensionSocket.swift, ExtensionsUI.swift, Extensions.swift, ExtensionShims.swift, ExtensionPopup.swift, Crx.swift, Find.swift, Stage.swift, Store.swift, Updater.swift, Bench.swift, Browser.swift, Tab.swift, Design.swift, Prefs.swift

#### 2. Mixed Concerns
- `Bench.swift` (1,626 lines) contains testing infrastructure mixed with business logic
- `Store.swift` handles persistence, settings, test worlds, and migration
- `Browser.swift` (2,304 lines) is a massive god object managing tabs, UI state, extensions, passkeys, history, bookmarks
- `Tab.swift` (1,670 lines) handles web view lifecycle, content scripts, extension interaction, context menus
- `ExtensionShims.swift` (3,291 lines) is the largest file — Chrome API shims, permissions, passkeys, browsing data

#### 3. No Test Suite
Zero unit tests, integration tests, or UI tests. The `bench` script is the only testing mechanism.

#### 4. Hardcoded Identifiers
- `com.khulnasoft.gptcomputer` still referenced in Store.swift (line 61)
- `com.khulnasoft.gptcomputer.test` still referenced in Store.swift (line 122)
- `GPTCOMPUTER_PROBE` / `GPTCOMPUTER_MEASURE` environment variables still use old name
- `"gptcomputer"` window frame name still in App.swift (line 722)

#### 5. Missing Structure
- No `Tests/` directory
- No `Resources/` directory for assets
- No `Protocols/` or `Models/` directories
- No `Services/` directory for networking/persistence
- No `Extensions/` directory for Swift extensions
- No `Utilities/` directory for helpers

#### 6. Build Script Debt
- `build.sh` is 241 lines with inline plist generation, signing, notarization, DMG creation
- `build-fast.sh` duplicates much of build.sh logic
- No CI/CD configuration (no `.github/workflows/`)

## Refactoring Plan

### Phase 1: Project Structure Reorganization (Week 1)

#### 1.1 Create Module Subdirectories
```
Sources/GPT Computer/
├── Application/          # App lifecycle, scene management
│   ├── AgentWebKitApp.swift      (moved from App.swift)
│   ├── WindowSetup.swift         (extracted from App.swift)
│   └── Commands.swift            (extracted from App.swift)
├── Browser/            # Core browser logic
│   ├── Browser.swift
│   ├── Browser+Actions.swift     # Extracted from Browser.swift
│   ├── Browser+Extensions.swift  # Extracted from Browser.swift
│   └── Browser+Shortcuts.swift   # Extracted from Browser.swift
├── Tabs/               # Tab management
│   ├── Tab.swift
│   ├── Tab+Content.swift        # Extracted from Tab.swift
│   ├── Tab+Events.swift         # Extracted from Tab.swift
│   └── WebView.swift            # Extracted from Tab.swift
├── UI/                 # User interface components
│   ├── Panels/
│   │   ├── SettingsPanel.swift
│   │   ├── WelcomePanel.swift
│   │   ├── PasswordsPanel.swift
│   │   ├── BookmarksPanel.swift
│   │   ├── HistoryPanel.swift
│   │   ├── DownloadsPanel.swift
│   │   ├── HiddenPanel.swift
│   │   └── FindBar.swift
│   ├── Chrome/
│   │   ├── TabBar.swift
│   │   ├── SideBar.swift
│   │   ├── Omnibox.swift
│   │   ├── StatusLine.swift
│   │   ├── Lights.swift
│   │   └── Fold.swift
│   ├── Content/
│   │   ├── Page.swift
│   │   ├── Reader.swift
│   │   ├── Float.swift
│   │   ├── Plate.swift
│   │   ├── Peek.swift
│   │   └── SiteCard.swift
│   └── Shared/
│       ├── Design.swift
│       ├── Palette.swift
│       ├── Metrics.swift
│       ├── Motion.swift
│       └── CursorGround.swift
├── Services/           # Backend services
│   ├── Store.swift
│   ├── Updater.swift
│   ├── Session.swift
│   ├── History.swift
│   ├── Bookmarks.swift
│   ├── Vault.swift
│   ├── Passwords.swift
│   ├── Passkeys.swift
│   ├── Shield.swift
│   └── Curtain.swift
├── Extensions/         # Browser extensions
│   ├── Extensions.swift
│   ├── ExtensionShims.swift
│   ├── ExtensionNative.swift
│   ├── ExtensionSocket.swift
│   ├── ExtensionPopup.swift
│   ├── ExtensionsUI.swift
│   ├── Crx.swift
│   └── ExtensionShims+Permissions.swift  # Extracted from ExtensionShims.swift
├── Networking/         # Network layer
│   ├── Engine.swift
│   ├── Address.swift
│   └── Links.swift
├── Utilities/          # Helpers and tools
│   ├── Bench.swift
│   ├── Inspectable.swift
│   ├── Registrable.swift
│   └── StoreRelay.swift
└── Models/             # Data models
    ├── Preferences.swift
    ├── TabModel.swift
    ├── BookmarkModel.swift
    ├── HistoryItem.swift
    └── ExtensionManifest.swift
```

#### 1.2 Create Test Structure
```
Tests/
├── AgentWebKitTests/
│   ├── Models/
│   │   ├── PreferencesTests.swift
│   │   └── BookmarkTests.swift
│   ├── Services/
│   │   ├── StoreTests.swift
│   │   ├── HistoryTests.swift
│   │   └── BookmarksServiceTests.swift
│   ├── Utilities/
│   │   ├── BenchTests.swift
│   │   └── StoreRelayTests.swift
│   └── Helpers/
│       └── TestFixture.swift
├── AgentWebKitUITests/
│   ├── TabTests.swift
│   ├── NavigationTests.swift
│   └── ExtensionTests.swift
└── TestSupport/
    ├── MockBrowser.swift
    ├── MockTab.swift
    └── MockWebPage.swift
```

### Phase 2: Code Quality & Architecture (Week 2-3)

#### 2.1 Extract Browser God Object
**Current**: `Browser.swift` — 2,304 lines, manages everything
**Target**: Split into focused extensions:
- `Browser+Tabs.swift` — tab creation, switching, closing, pinning
- `Browser+Navigation.swift` — back/forward, reload, address editing
- `Browser+Extensions.swift` — extension management, permissions
- `Browser+Passkeys.swift` — passkey handling
- `Browser+Search.swift` — search/omnibox logic
- `Browser+Shortcuts.swift` — keyboard shortcut handling (currently 200+ lines in App.swift)

#### 2.2 Extract Tab Complexity
**Current**: `Tab.swift` — 1,670 lines
**Target**:
- `Tab+Lifecycle.swift` — web view creation, loading, destruction
- `Tab+ContentScripts.swift` — script injection, message handlers
- `Tab+Extensions.swift` — extension interaction, "Add to Search" flow
- `Tab+ContextMenu.swift` — context menu handling

#### 2.3 Break Up ExtensionShims
**Current**: `ExtensionShims.swift` — 3,291 lines (largest file)
**Target**: Split by Chrome API area:
- `ExtensionShims+Core.swift` — marker, ender, basic shim infrastructure
- `ExtensionShims+Permissions.swift` — permissions API shim
- `ExtensionShims+BrowsingData.swift` — browsingData API shim
- `ExtensionShims+Sessions.swift` — sessions API shim
- `ExtensionShims+Passkeys.swift` — passkey-related shims
- `ExtensionShims+Windows.swift` — window management shims
- `ExtensionShims+Tabs.swift` — tab management shims
- `ExtensionShims+Runtime.swift` — runtime/ messaging shims

#### 2.4 Fix Hardcoded Identifiers
```swift
// Store.swift — fix these:
Bundle.main.bundleIdentifier != "com.KhulnaSoft.agent-webkit"
"com.KhulnaSoft.agent-webkit.test"
Environment variable: AGENT_WEBKIT_PROBE (replace GPTCOMPUTER_PROBE)
Environment variable: AGENT_WEBKIT_MEASURE (replace GPTCOMPUTER_MEASURE)
Window frame name: "agent-webkit" (replace "gptcomputer")
```

### Phase 3: Build & CI/CD (Week 3-4)

#### 3.1 Unified Build System
```bash
# Replace build.sh + build-fast.sh with a single script
./build.sh [debug|release] [app|dmg|ship] [clean]

# Examples:
./build.sh debug          # Fast debug build, opens app
./build.sh release app    # Release app bundle
./build.sh release dmg    # Release + DMG
./build.sh release ship   # Release + DMG + notarization
./build.sh clean          # Clean build folder
```

#### 3.2 GitHub Actions CI/CD
```yaml
# .github/workflows/
├── build.yml           # Build on push/PR
├── test.yml            # Run tests
├── lint.yml            # Swift linting
└── release.yml         # Automated releases
```

#### 3.3 Swift Package Manager Enhancement
```swift
// Package.swift — add test targets, resource bundles
targets: [
    .executableTarget(
        name: "AgentWebKit",
        path: "Sources/GPT Computer",
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .testTarget(
        name: "AgentWebKitTests",
        dependencies: ["AgentWebKit"],
        path: "Tests/AgentWebKitTests"
    ),
    .testTarget(
        name: "AgentWebKitUITests",
        dependencies: ["AgentWebKit"],
        path: "Tests/AgentWebKitUITests"
    )
]
```

### Phase 4: Documentation & Tooling (Week 4)

#### 4.1 Documentation Structure
```
docs/
├── ARCHITECTURE.md      # Architecture overview
├── GETTING_STARTED.md   # Build & run instructions
├── API_REFERENCE.md     # Public API documentation
├── EXTENSIONS.md        # Extension development guide
├── BENCHMARKING.md      # Bench script usage
└── CONTRIBUTING.md      # Development guide
```

#### 4.2 Code Generation
- Add Swift documentation comments to all public APIs
- Generate documentation with `swift doc` or Swift-DocC
- Add `@unknown default` patterns for future-proof enum handling

### Phase 5: Quality Assurance (Week 5-6)

#### 5.1 Test Coverage Goals
| Component | Target Coverage |
|-----------|----------------|
| Models | 90%+ |
| Services | 80%+ |
| Utilities | 70%+ |
| UI | 40%+ (integration) |
| Overall | 60%+ |

#### 5.2 Static Analysis
- Enable Swift strict concurrency checking
- Add `swift lint` with custom rules
- Add `swift format` pre-commit hook
- Enable Swift 6 strict isolation mode

#### 5.3 Performance Benchmarks
- Add benchmark targets for critical paths
- Profile startup time, memory usage, tab switching
- Set performance budgets per feature

## Implementation Priority

### High Priority (Must Do)
1. **Fix hardcoded identifiers** — `com.khulnasoft.search` → `com.khulnasoft.gptcomputer` (completed)
2. **Rename environment variables** — `GPTCOMPUTER_PROBE` → `AGENT_WEBKIT_PROBE`
3. **Create Tests/ directory** — start with StoreTests, BrowserTests
4. **Extract Browser extensions** — reduce 2,304-line god object

### Medium Priority (Should Do)
5. **Organize source files** into subdirectories (Application, Browser, Tabs, UI, Services, etc.)
6. **Break up ExtensionShims.swift** — 3,291 lines is unmaintainable
7. **Add CI/CD** — GitHub Actions for build, test, lint
8. **Unify build scripts** — single `build.sh` with modes

### Lower Priority (Nice to Have)
9. **Create Models/ directory** — separate data models from logic
10. **Add Swift-DocC documentation** — auto-generated API docs
11. **Add performance benchmarks** — track regressions
12. **Create extension templates** — scaffold for custom extensions

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking changes to App.swift | High | Incremental refactoring, keep compiled state |
| ExtensionShims split breaks message handlers | High | Comprehensive bench tests before/after |
| Bundle identifier change breaks existing users | Medium | Migration path in Store.swift (already has Office Browser migration) |
| Test suite incompatibility with WebKit | Medium | Use test worlds (GPTCOMPUTER_PROBE) for isolation |
| Build script changes break releases | High | Keep old build.sh as fallback until new one verified |

## Success Metrics

- [ ] All 62 source files organized into logical subdirectories
- [ ] No file exceeds 1,000 lines (currently ExtensionShims at 3,291)
- [ ] Test coverage ≥ 60% overall
- [ ] `swift build` compiles without warnings
- [ ] `swift test` passes all tests
- [ ] CI/CD pipeline runs on every PR
- [ ] Bundle identifier fully migrated to `com.KhulnaSoft.agent-webkit`
- [ ] Environment variables renamed to `AGENT_WEBKIT_*`
- [ ] Single unified build script replaces build.sh + build-fast.sh
- [ ] Documentation generated for all public APIs

## Estimated Effort

| Phase | Effort | Dependency |
|-------|--------|------------|
| Phase 1: Structure | 3-4 days | None |
| Phase 2: Architecture | 5-7 days | Phase 1 |
| Phase 3: Build/CI | 3-4 days | Phase 1 |
| Phase 4: Documentation | 2-3 days | Phase 2 |
| Phase 5: QA | 4-5 days | Phase 2, 3 |
| **Total** | **17-23 days** | |