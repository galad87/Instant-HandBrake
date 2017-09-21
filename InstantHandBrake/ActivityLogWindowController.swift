//
//  ActivityLogWindowController.swift
//  InstantHandBrake
//
//  Created by Damiano Galassi on 10/03/16.
//  Copyright © 2016 HandBrake. All rights reserved.
//

import Cocoa

class ActivityLogWindowController: NSWindowController {

    private let storage = NSTextStorage()

    @IBOutlet var textView: NSTextView!

    override var windowNibName : NSNib.Name? {
        return NSNib.Name(rawValue: "ActivityLogWindowController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        textView.layoutManager?.replaceTextStorage(storage)
    }

    override func showWindow(_ sender: Any?) {
        if (window?.isVisible == false) {
            textView.scrollToEndOfDocument(nil)
        }
        super.showWindow(sender)
    }

    func appendString(_ string: String) {
        let attributedString = NSAttributedString(string: string)
        storage.append(attributedString)

        if let window = window, let textView = textView {
            if window.isVisible {
                textView.scrollToEndOfDocument(nil)
            }
        }

    }

}
