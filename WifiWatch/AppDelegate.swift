//
//  AppDelegate.swift
//  WifiWatch
//
//  Created by Pascal Pfiffner on 25.11.16.
//  Inspired by:
//  - https://github.com/slozo/Network-listener
//  - https://gist.github.com/adgedenkers/3874427
//

import Cocoa
import CoreWLAN
import SystemConfiguration


let kScriptConnected    = ".wifiConnected"
let kScriptDisconnected = ".wifiDisconnected"


enum InterfaceChangeType: String {
	case power = "Power"
	case link  = "Link"
	case ssid  = "SSID"
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CWEventDelegate {
	
	var appName: String {
		return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "WifiWatch"
	}
	
	var lastSSID: String?
	
	var client: CWWiFiClient?
	
	var monitored: [CWEventType]?
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		NSLog("\(appName) starting")
		defer { NSLog("\(appName) startup complete") }
		
		let clnt = CWWiFiClient.shared()
		clnt.delegate = self
		client = clnt
		monitored = [.ssidDidChange] // .powerDidChange, .linkDidChange
		monitored?.forEach() {
			do { try clnt.startMonitoringEvent(with: $0) }
			catch let error { NSLog("Failed to start monitoring \($0): \(error)") }
		}
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		NSLog("\(appName) shutting down")
		defer { NSLog("\(appName) shutdown complete") }
		guard let client = client else {
			return
		}
		monitored?.forEach() {
			do { try client.stopMonitoringEvent(with: $0) }
			catch let error { NSLog("Failed to stop monitoring \($0): \(error)") }
		}
	}
	
	
	// MARK: - Actions
	
	func didChangeWifi(interface: CWInterface?, type: InterfaceChangeType) {
		print("--->  CHANGED \(type.rawValue) FOR \(interface?.interfaceName ?? "nil"): \(lastSSID ?? "nil") --> \(interface?.ssid() ?? "nil")")
		
		// run script if link changed
		let ssid = interface?.ssid()
		if let last = lastSSID {
			if let ssid = ssid {                 // different SSID or reconnect
				runScript(named: kScriptConnected, arguments: [ssid, last])
			}
			else if nil == ssid {                // disconnected
				runScript(named: kScriptDisconnected, arguments: [last])
			}
		}
		else if let ssid = ssid {                // connected
			runScript(named: kScriptConnected, arguments: [ssid])
		}
		
		lastSSID = interface?.ssid()
	}
	
	func runScript(named: String, arguments: [String]? = nil) {
		let home = URL(fileURLWithPath: NSHomeDirectory())
		let url = home.appendingPathComponent(named)
		if FileManager.default.fileExists(atPath: url.path) {
			do {
				let task = try NSUserUnixTask(url: url)
				NSLog("Executing script «\(url.path)» with [\(arguments?.joined(separator: ", ") ?? "")]")
				task.execute(withArguments: arguments) { error in
					if let error = error {
						NSLog("Error executing script «\(url.path)»: \(error)")
					}
				}
			}
			catch let error {
				NSLog("Failed to execute script «\(url.path)»: \(error)")
			}
		}
	}
	
	
	// MARK: - CWEventDelegate
	
	func powerStateDidChangeForWiFiInterface(withName interfaceName: String) {
		let iface = client?.interface(withName: interfaceName)
		didChangeWifi(interface: iface, type: .power)
	}
	
	func linkDidChangeForWiFiInterface(withName interfaceName: String) {
		let iface = client?.interface(withName: interfaceName)
		didChangeWifi(interface: iface, type: .link)
	}
	
	func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
		let iface = client?.interface(withName: interfaceName)
		didChangeWifi(interface: iface, type: .ssid)
	}
}

