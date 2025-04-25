//
//  AppDelegate.swift
//  SKGenerateModelTool
//
//  Created by KUN on 2020/5/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private lazy var statusItem: NSStatusItem = {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(named: "itemIcon")
            button.action = #selector(applicationShouldHandleReopen(_:hasVisibleWindows:))
        }
        return item
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        configureStatusItemMenu()
    }

    @objc
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        for window in NSApplication.shared.windows {
            window.makeKeyAndOrderFront(self)
        }
        return true
    }
    
    private func configureStatusItemMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem.separator())
        
        let showItem = NSMenuItem(
            title: "显示",
            action: #selector(applicationShouldHandleReopen(_:hasVisibleWindows:)),
            keyEquivalent: "w"
        )
        
        let hideItem = NSMenuItem(
            title: "隐藏",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "e"
        )
        
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        
        menu.addItem(showItem)
        menu.addItem(hideItem)
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
}
