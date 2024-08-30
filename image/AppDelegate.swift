//
//  AppDelegate.swift
//  image
//
//  Created by dingtone on 2024/8/24.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let windowSize = NSMakeRect(0, 0, 800, 600)
        window = NSWindow(contentRect: windowSize, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.center()
        window.title = "Nicole"
        window.makeKeyAndOrderFront(nil)
        
        
        
        let vc = HomeViewController()
        window.contentViewController = vc
        window.delegate = self
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(self)
    }
}
