import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private let showsMainWindow = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if showsMainWindow {
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
            }
        } else {
            for window in NSApp.windows {
                window.orderOut(nil)
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            if let name = AndroidEmulatorDiscovery.defaultAVDToLaunch() {
                AndroidEmulatorDiscovery.launchAVD(named: name)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if showsMainWindow, !flag {
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
            }
            return true
        }
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let infos = AndroidEmulatorDiscovery.listAVDInfosSorted()
        if infos.isEmpty {
            let item = NSMenuItem(
                title: "No AVDs",
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            return menu
        }

        let devicesItem = NSMenuItem(title: "Device", action: nil, keyEquivalent: "")
        let devicesMenu = NSMenu()
        devicesItem.submenu = devicesMenu

        let grouped = Dictionary(grouping: infos, by: \.apiLevel)
        let levels = grouped.keys.sorted(by: >)
        for level in levels {
            let apiTitle = level > 0 ? "\(level)" : "?"
            let apiItem = NSMenuItem(title: apiTitle, action: nil, keyEquivalent: "")
            let apiMenu = NSMenu()
            apiItem.submenu = apiMenu
            let items = grouped[level] ?? []
            for info in items.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) {
                let item = NSMenuItem(title: info.name, action: #selector(launchAVD(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = info.name
                item.toolTip = "Device/\(level > 0 ? "\(level)" : "?")/\(info.name)"
                apiMenu.addItem(item)
            }
            devicesMenu.addItem(apiItem)
        }

        menu.addItem(devicesItem)
        return menu
    }

    @objc private func launchAVD(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        AndroidEmulatorDiscovery.setPreferredAVDName(name)
        AndroidEmulatorDiscovery.launchAVD(named: name)
    }
}
