# SafeKeep

A security-first, on-device password keeper for iPhone, built with SwiftUI.

- No accounts, servers, analytics or network code. The vault never leaves the device unless you export it yourself.
- Zero third-party dependencies.
- iOS 18+, Swift 6, Xcode 27.

## Security model

| Layer | What it does |
|---|---|
| Vault file | One AES-256-GCM sealed blob (`Application Support/Vault/vault.sealed`). Every field is encrypted, including service names and usernames. Complete file protection, excluded from backups. |
| Vault key | Random 256-bit key. Never stored in the clear. |
| Passcode wrap | The vault key is sealed with a key derived from your 6-digit passcode (PBKDF2-SHA256, ≥600k rounds, tuned to about 0.5 s on the device). Stored in the Keychain as `WhenUnlockedThisDeviceOnly`. |
| Face ID wrap | The vault key is stored in the Keychain behind `biometryCurrentSet` access control. Face ID is evaluated first, then that authenticated context is passed to the Keychain read. Changing Face ID enrollment turns this off. |
| Lockout | 5 free attempts, then 1 min, 5 min, 15 min and 1 h waits. The lockout state lives in the Keychain, and setting the clock back doesn't shorten a wait. |
| Runtime | Auto-lock on background, a privacy shield in the app switcher and during screen recording or mirroring, a 30-second local-only clipboard, third-party keyboards blocked, and system Password AutoFill turned off on vault fields. |
| Backup | Optional `.safekeep` export, sealed with a separate backup password of at least 12 characters (PBKDF2 + AES-GCM). Importing merges and skips duplicates. |

There is no recovery path for a forgotten passcode. That is by design.

## Project layout

```
SafeKeep/
  App/            entry point, app delegate, root routing, tab bar
  Core/
    Security/     crypto, Keychain, key wrapping, lockout, generator, strength, clipboard
    Storage/      encrypted vault file, encrypted backup format
    Session/      VaultSession (app state), auto-lock, screen-capture monitor
  Models/         Account, categories, brand catalog, preferences
  Features/       Onboarding, Lock, Home, Accounts, AccountDetail, AccountEditor, Settings
  DesignSystem/   theme tokens and reusable components
  Resources/      assets, brand icons, Info.plist, privacy manifest
SafeKeepTests/    Swift Testing unit tests
scripts/          brand icon and app icon generators
```

## Build and test

```bash
xcodebuild -project SafeKeep.xcodeproj -scheme SafeKeep \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

## Brand icons

The service logos come from [Simple Icons](https://simpleicons.org) (CC0), pinned in `scripts/fetch-brand-icons.sh` and bundled at build time. The app itself never downloads anything. To change the set, edit `scripts/brands.tsv` and run:

```bash
./scripts/fetch-brand-icons.sh
```

Brands that Simple Icons no longer ships (for example Amazon and Slack) appear as letter tiles in their brand colour. Logos are trademarks of their owners.

## Mascot

Kip the squirrel appears across the app in ten poses (`MascotPose`): waving and proud on Home (where Kip also announces the vault status), concerned for weak passwords, curled up on the lock screen and privacy shield, sleepy during a lockout, holding a key during passcode setup, searching for empty results, carrying a box for backups, and celebrating a first save. The welcome tour (`WelcomeTourView`) runs before passcode setup and can be replayed from Settings › Welcome Tour.

The source art has a white background. To cut it out and install it into the asset catalog (on-device Vision subject lifting, with the expression marks restored):

```bash
./scripts/prepare-mascot.sh <folder-with-the-original-pngs>
```
