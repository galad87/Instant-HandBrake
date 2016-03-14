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

    let presetsURL: NSURL = {
        AppDelegate.appSupportURL().URLByAppendingPathComponent("UserPresets.json")
    }()

    var documentControllers = [DocumentController]()

    private static func appSupportURL() -> NSURL {
        let fileManager = NSFileManager.defaultManager()
        if let url = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
            .first?.URLByAppendingPathComponent("Instant HandBrake") {

            do {
                if let path = url.path where fileManager.fileExistsAtPath(path) == false {
                    try fileManager.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: [:])
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

    func applicationWillFinishLaunching(notification: NSNotification) {
        HBCore.initGlobal()
        presetsManager = HBPresetsManager(URL: presetsURL)

        OutputRedirect.stdoutRedirect.addListener { (string: String) in
            self.activityWindow.appendString(string)
        }

        OutputRedirect.stderrRedirect.addListener { (string: String) in
            self.activityWindow.appendString(string)
        }

        openDocument(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        presetsManager.savePresets()
        HBCore.closeGlobal()
    }

    @IBAction func showActivityLog(sender: AnyObject) {
        activityWindow.showWindow(self)
    }

    func addDocumentController(fileURL: NSURL) {
        let documentController = DocumentController(fileURL: fileURL, presetsManager: presetsManager, delegate: self)
        documentControllers.append(documentController)
        documentController.showWindow(self)

        NSDocumentController.sharedDocumentController().noteNewRecentDocumentURL(fileURL)
    }

    func documentDidClose(document: DocumentController) {
        documentControllers = documentControllers.filter{ $0 !== document }
    }

    @IBAction func openDocument(sender: AnyObject) {
        let panel = NSOpenPanel()

        panel.canChooseDirectories = true

        panel.beginWithCompletionHandler { (result: Int) in
            if result == NSFileHandlingPanelOKButton {
                if let url = panel.URL {
                    self.addDocumentController(url)
                }
            }
        }
    }

    func application(sender: NSApplication, openFiles filenames: [String]) {
        if let filename =  filenames.first {
            let fileURL = NSURL(fileURLWithPath: filename)
            addDocumentController(fileURL)
        }
    }

    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        return true
    }

}
