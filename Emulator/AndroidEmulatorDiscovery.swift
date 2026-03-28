import Foundation

struct AVDInfo: Hashable {
    let name: String
    let apiLevel: Int
}

enum AndroidEmulatorDiscovery {

    private static var preferredAVDKey: String {
        (Bundle.main.bundleIdentifier ?? "Emulator") + ".preferredAVDName"
    }

    static func preferredAVDName() -> String? {
        UserDefaults.standard.string(forKey: preferredAVDKey)
    }

    static func setPreferredAVDName(_ name: String) {
        UserDefaults.standard.set(name, forKey: preferredAVDKey)
    }

    private static func sdkRootURL() -> URL? {
        let env = ProcessInfo.processInfo.environment
        if let home = env["ANDROID_HOME"], !home.isEmpty {
            return URL(fileURLWithPath: home, isDirectory: true)
        }
        if let root = env["ANDROID_SDK_ROOT"], !root.isEmpty {
            return URL(fileURLWithPath: root, isDirectory: true)
        }
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let fallback = homeDir.appendingPathComponent("Library/Android/sdk", isDirectory: true)
        if FileManager.default.fileExists(atPath: fallback.path) {
            return fallback
        }
        return nil
    }

    static func emulatorExecutableURL() -> URL? {
        guard let root = sdkRootURL() else { return nil }
        let url = root.appendingPathComponent("emulator/emulator", isDirectory: false)
        return FileManager.default.isExecutableFile(atPath: url.path) ? url : nil
    }

    private static func avdHomeDirectoryURL() -> URL {
        let env = ProcessInfo.processInfo.environment
        if let path = env["ANDROID_AVD_HOME"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        if let sdkHome = env["ANDROID_SDK_HOME"], !sdkHome.isEmpty {
            return URL(fileURLWithPath: sdkHome, isDirectory: true).appendingPathComponent("avd", isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".android/avd", isDirectory: true)
    }

    private static func avdConfigIniURL(forAVDName name: String) -> URL {
        avdHomeDirectoryURL().appendingPathComponent("\(name).avd/config.ini", isDirectory: false)
    }

    private static func apiLevel(forAVDName name: String) -> Int {
        let configURL = avdConfigIniURL(forAVDName: name)
        guard let data = try? Data(contentsOf: configURL),
              let text = String(data: data, encoding: .utf8) else {
            return 0
        }
        return parseTargetAndroidApi(fromConfig: text)
    }

    private static func parseTargetAndroidApi(fromConfig text: String) -> Int {
        guard let regex = try? NSRegularExpression(
            pattern: #"^\s*target\s*=\s*android-(\d+)\s*$"#,
            options: .caseInsensitive
        ) else { return 0 }
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = String(raw)
            let range = NSRange(line.startIndex..., in: line)
            guard let match = regex.firstMatch(in: line, options: [], range: range),
                  match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: line),
                  let n = Int(line[r]) else { continue }
            return n
        }
        return 0
    }

    static func listAVDInfosSorted() -> [AVDInfo] {
        let names = listAVDNamesRaw()
        var infos: [AVDInfo] = names.map { AVDInfo(name: $0, apiLevel: apiLevel(forAVDName: $0)) }
        infos.sort {
            if $0.apiLevel != $1.apiLevel { return $0.apiLevel > $1.apiLevel }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        return infos
    }

    static func listAVDNames() -> [String] {
        listAVDInfosSorted().map(\.name)
    }

    private static func listAVDNamesRaw() -> [String] {
        guard let exe = emulatorExecutableURL() else { return [] }
        let process = Process()
        process.executableURL = exe
        process.arguments = ["-list-avds"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return []
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return [] }
        return text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func defaultAVDToLaunch() -> String? {
        let infos = listAVDInfosSorted()
        guard !infos.isEmpty else { return nil }
        if let saved = preferredAVDName(), infos.contains(where: { $0.name == saved }) {
            return saved
        }
        return infos.first?.name
    }

    static func launchAVD(named name: String) {
        guard let exe = emulatorExecutableURL() else { return }
        let process = Process()
        process.executableURL = exe
        process.arguments = ["-avd", name]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }
}
