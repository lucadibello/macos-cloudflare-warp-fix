import Foundation
import SystemConfiguration

struct AppConfig: Codable {
    var warpIpRange: String
    var lanServerIp: String
}

func loadConfig() -> AppConfig? {
    let configFileURL = URL(fileURLWithPath: "/etc/zerotrust-lanmonitor/config.json")

    do {
        let data = try Data(contentsOf: configFileURL)
        let decoder = JSONDecoder()
        let config = try decoder.decode(AppConfig.self, from: data)
        return config
    } catch {
        print("Error loading config: \(error)")
        return nil  
    }
}

class NetworkMonitor {
    static var shared: NetworkMonitor?
    var store: SCDynamicStore?
    var storeRunLoopSource: CFRunLoopSource?
    var config: AppConfig

    init(config: AppConfig) {
        self.config = config
        setupNetworkChangeMonitoring()
    }

    func setupNetworkChangeMonitoring() {
        print("Monitoring network changes for IP range: \(config.warpIpRange)")

        var context = SCDynamicStoreContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        guard let store = SCDynamicStoreCreate(nil, "com.lucadibello.zerotrust-lanmonitor" as CFString, networkChangeCallback, &context) else {
            print("Failed to create SCDynamicStore")
            return
        }
        self.store = store

        let keys = ["State:/Network/Global/IPv4" as CFString, "State:/Network/Interface/.*/IPv4" as CFString]
        SCDynamicStoreSetNotificationKeys(store, keys as CFArray, nil)

        guard let runLoopSource = SCDynamicStoreCreateRunLoopSource(nil, store, 0) else {
            print("Failed to create run loop source")
            return
        }
        self.storeRunLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
    }
    
    func runScriptWithSudo() {
        let scriptPath = "/opt/zerotrust-lanmonitor/enforce-lan-zerotrust.sh"

        // Directly use the parameters since they don't contain special characters
        let warpIpRange = config.warpIpRange
        let lanServerIp = config.lanServerIp
        
        // Construct the AppleScript command with parameters
        let appleScriptString = """
        do shell script "sudo \(scriptPath) \(lanServerIp) \(warpIpRange)" 
        """
                
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScriptString) {
            let output = scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("Error: \(error)")
            } else {
                print(output.stringValue ?? "Success, but no output")
            }
        }
    }

}

func networkChangeCallback(store: SCDynamicStore, keys: CFArray, context: UnsafeMutableRawPointer?) {
    guard let context = context else {
        print("Context is nil.")
        return
    }
    let monitor = Unmanaged<NetworkMonitor>.fromOpaque(context).takeUnretainedValue()
    monitor.runScriptWithSudo()
}

if let config = loadConfig() {
    NetworkMonitor.shared = NetworkMonitor(config: config) // To avoid memory issues
    RunLoop.current.run()
} else {
    print("Could not load configuration. Exiting.")
    exit(1)
}
