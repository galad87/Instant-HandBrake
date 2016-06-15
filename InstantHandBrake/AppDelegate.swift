//
//  AppDelegate.swift
//  InstantHandBrake
//
//  Created by Damiano Galassi on 25/02/16.
//  Copyright © 2016 HandBrake. All rights reserved.
//

import Cocoa
import HandBrakeKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, DocumentDelegate {

    let activityWindow = ActivityLogWindowController()
    var presetsManager = HBPresetsManager()

    let presetsURL: URL = {
        try! AppDelegate.appSupportURL().appendingPathComponent("UserPresets.json")
    }()

    var documentControllers = [DocumentController]()

    private static func appSupportURL() -> URL {
        let fileManager = FileManager.default()
        if let url = try! fileManager.urlsForDirectory(.applicationSupportDirectory, inDomains: .userDomainMask)
            .first?.appendingPathComponent("Instant HandBrake") {

            do {
                if let path = url.path where fileManager.fileExists(atPath: path) == false {
                    try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
                }
            }
            catch _ {
                fatalError("Couldn't create the app support directory")
            }

            return url
        }
        else {
            fatalError("Couldn't find the app support directory")
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        HBCore.initGlobal()
        presetsManager = HBPresetsManager(url: presetsURL)

        _ = OutputRedirect.stdoutRedirect.addListener { (string: String) in
            self.activityWindow.appendString(string)
        }

        _ = OutputRedirect.stderrRedirect.addListener { (string: String) in
            self.activityWindow.appendString(string)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if documentControllers.count == 0 {
            openDocument(self)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        presetsManager.savePresets()
        HBCore.closeGlobal()
    }

    @IBAction func showActivityLog(_ sender: AnyObject) {
        activityWindow.showWindow(self)
    }

    func addDocumentController(_ fileURL: URL) {
        let documentController = DocumentController(fileURL: fileURL, presetsManager: presetsManager, delegate: self)
        documentControllers.append(documentController)
        documentController.showWindow(self)

        NSDocumentController.shared().noteNewRecentDocumentURL(fileURL)
    }

    func documentDidClose(_ document: DocumentController) {
        documentControllers = documentControllers.filter{ $0 !== document }
    }

    @IBAction func openDocument(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true

        panel.begin { result in
            if result == NSFileHandlingPanelOKButton {
                if let url = panel.url {
                    self.addDocumentController(url)
                }
            }
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        if let filename =  filenames.first {
            let fileURL = URL(fileURLWithPath: filename)
            addDocumentController(fileURL)
        }
    }

    func validate(_ menuItem: NSMenuItem) -> Bool {
        return true
    }

}
