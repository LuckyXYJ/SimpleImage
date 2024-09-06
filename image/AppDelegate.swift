//
//  AppDelegate.swift
//  image
//
//  Created by lucky on 2024/8/24.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
        
        let windowSize = NSMakeRect(0, 0, 800, 600)
        window = NSWindow(contentRect: windowSize, styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        // 设置窗口最大尺寸
//        window.maxSize = CGSize(width: 800, height: 600)
        // 设置窗口的最小高度和最大高度
//        let fixedHeight: CGFloat = 600
//        window.minSize = NSSize(width: 200, height: fixedHeight)
//        window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: fixedHeight)
        window.center()
        window.title = "简图"
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
