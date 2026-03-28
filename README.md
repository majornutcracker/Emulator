# Emulator

A small macOS app to launch the **Android Emulator** from the Dock: on open it starts a default AVD, and the Dock icon’s context menu lists virtual devices grouped by API level.

## Requirements

- macOS 26.2+ (project deployment target)
- [Android SDK](https://developer.android.com/studio) with `emulator/emulator` and at least one AVD (Android Studio or `avdmanager`)

## Behavior

- **On launch**, the preferred AVD is started in the background if it still exists; otherwise the first AVD in the list sorted by API (highest first).
- **Dock menu → Device** uses submenus per API; each item launches that AVD and stores the preference in `UserDefaults` (`<bundleId>.preferredAVDName`).

## Paths and environment variables

The SDK is resolved in this order:

1. `ANDROID_HOME`
2. `ANDROID_SDK_ROOT`
3. `~/Library/Android/sdk` if it exists

AVDs are read from:

1. `ANDROID_AVD_HOME`
2. `ANDROID_SDK_HOME/avd`
3. `~/.android/avd`

The displayed API level comes from `target=android-N` in each `.avd`’s `config.ini`.

## Build

1. Open `Emulator.xcodeproj` in Xcode.
2. Select the **Emulator** scheme and **Run** (⌘R).

Sandbox is off (`ENABLE_APP_SANDBOX = NO`) so the app can run the SDK `emulator` binary.

## Repository

https://github.com/majornutcracker/Emulator
