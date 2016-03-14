//
//  ActivityLogWindowController.swift
//  InstantHandBrake
//
//  Created by Damiano Galassi on 10/03/16.
//  Copyright © 2016 HandBrake. All rights reserved.
//

import Cocoa

class ActivityLogWindowController: NSWindowController {

    let storage = NSTextStorage()

    @IBOutlet var textView: NSTextView!

    override var windowNibName : String! {
        return "ActivityLogWindowController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        textView.layoutManager?.replaceTextStorage(storage)
    }

    override func showWindow(sender: AnyObject?) {
        if (window?.visible == false) {
            textView.scrollToEndOfDocument(nil)
        }
        super.showWindow(sender)
    }

    func appendString(string: String) {
        let attributedString = NSAttributedString(string: string)
        storage.appendAttributedString(attributedString)

        if let window = window, let textView = textView {
            if window.visible {
                textView.scrollToEndOfDocument(nil)
            }
        }

    }

}
