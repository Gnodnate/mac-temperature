//
//  AppDelegate.swift
//  Temperature
//
//  Created by Gondnat on 26/03/2018.
//  Copyright © 2018 Gondnat. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    lazy var statusMenu: NSStatusItem = {
        let _statusMenu = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        return _statusMenu
    }()

    lazy var smcReadQueue: DispatchQueue = {
        return DispatchQueue(label: "com.thnuth.temperature.smc.read",
                             qos: DispatchQoS.background,
                             attributes: DispatchQueue.Attributes())
    }()

    lazy var PreferencesWC: PreferencesWindowController = {
        return PreferencesWindowController()
    }()

    var quitMenuItem: NSMenuItem {
        return NSMenuItem(title: NSLocalizedString("Quit", comment: "Quit App"), action: #selector(quit), keyEquivalent: "q")
    }

    var preferenceMenuItem:NSMenuItem {
        return NSMenuItem(title: NSLocalizedString("Preferences...", comment: "button will show preferences"), action: #selector(preference), keyEquivalent: ",")
    }

    private var refreshTimer:Timer?

    fileprivate func fanMenuItem(title string: String) -> NSMenuItem {
        let fanMenuItem = NSMenuItem()
        fanMenuItem.isEnabled = false
        fanMenuItem.attributedTitle = NSAttributedString(string: string,
                                                         attributes: [NSAttributedStringKey.font: NSFont.messageFont(ofSize: 12)])
        return fanMenuItem
    }
    @objc fileprivate func quit() {
        NSApp.terminate(nil)
    }

    @objc fileprivate func preference() {
        PreferencesWC.preferenceViewControllers = [ GeneralPreferenceViewController()
        ]
        PreferencesWC.window?.center()
        PreferencesWC.window?.makeKeyAndOrderFront(self)
        PreferencesWC.window?.orderedIndex = 0
        NSApp .activate(ignoringOtherApps: true)
    }

    @objc fileprivate func refreshStatus() {
        var menu = NSMenu()
        if statusMenu.menu != nil {
            menu = statusMenu.menu!
        }
        menu.removeAllItems()
        SMCWrapper.shared().readFloat(withKey: "TC0P".cString(using: .ascii)) { (temperature) in
            let title = String(format: "%.01f℃", arguments: [temperature])
            self.statusMenu.button?.title = title
            self.statusMenu.button?.font = NSFont(name: "system", size: 10)
        }

        SMCWrapper.shared().readFloat(withKey: "FNum".cString(using: .ascii)) { fansCount in
            var i = 0;
            while i < Int(fansCount) {
                let fmt = NSLocalizedString("Fan  #%d", comment: "Fan number")
                let fanNameItem = NSMenuItem(title: String(format: fmt, arguments:[i+1]), action: nil, keyEquivalent: "")
                fanNameItem.isEnabled = false
                menu.addItem(fanNameItem)

                // actual RPM
                SMCWrapper.shared().readFloat(withKey: "F\(i)Ac".cString(using: .ascii),
                                              withComplation: { fanRPM in
                                                let fmt = NSLocalizedString("Current Speed: %d RPM", comment: "Current fan speed")
                                                menu.addItem(self.fanMenuItem(title: String(format: fmt, arguments: [Int(fanRPM)])))
                })


                // target RPM
                SMCWrapper.shared().readFloat(withKey: "F\(i)Tg".cString(using: .ascii),
                                              withComplation: { fanRPM in
                                                let fmt = NSLocalizedString("Target Speed: %d RPM", comment: "Fan  target speed")
                                                menu.addItem(self.fanMenuItem(title: String(format: fmt, arguments: [Int(fanRPM)])))
                })

                // MIN RPM
                SMCWrapper.shared().readFloat(withKey: "F\(i)Mn",
                    withComplation: { fanRPM in
                        let fmt = NSLocalizedString("Min Speed: %d RPM", comment: "Fan  min speed")
                        menu.addItem(self.fanMenuItem(title: String(format: fmt, arguments: [Int(fanRPM)])))
                })
                // MAX RPM
                SMCWrapper.shared().readFloat(withKey: "F\(i)Mx",
                    withComplation: { fanRPM in
                        let fmt = NSLocalizedString("Max Speed: %d RPM", comment: "Fan max speed")
                        menu.addItem(self.fanMenuItem(title: String(format: fmt, arguments: [Int(fanRPM)])))
                })

                menu.addItem(NSMenuItem.separator())
                i += 1
            }
        }

        menu.addItem(preferenceMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitMenuItem)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let menu = NSMenu()
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitMenuItem)
        self.statusMenu.menu = menu
        createRefreshTimer()
        UserDefaults.standard.addObserver(self, forKeyPath: refreshSecondID, options: .new, context: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func createRefreshTimer() {
        var interval = UserDefaults.standard.value(forKey: refreshSecondID) as? TimeInterval
        if interval == nil {
            UserDefaults.standard.setValue(1, forKey: refreshSecondID)
            interval = 1
        }
        if #available(OSX 10.12, *) {
            refreshTimer = Timer(fire: Date(timeIntervalSinceNow: 0), interval: interval!, repeats: true) { timer in
                self.refreshStatus()
            }
            RunLoop.current.add(refreshTimer!, forMode: .commonModes)
        } else {
            refreshTimer = Timer(fireAt: Date(timeIntervalSinceNow: 0), interval: interval!, target: self, selector: #selector(refreshStatus), userInfo: nil, repeats: true)
            RunLoop.current.add(refreshTimer!, forMode: .commonModes)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == refreshSecondID {
            refreshTimer?.invalidate()
            createRefreshTimer()
        }
    }


}

