//
//  DocumentController.swift
//  InstantHandBrake
//
//  Created by Damiano Galassi on 03/03/16.
//  Copyright © 2016 HandBrake. All rights reserved.
//

import Cocoa
import HandBrakeKit

protocol DocumentDelegate : class {
    func documentDidClose(_ document: DocumentController)
}

class DocumentController: NSWindowController, NSWindowDelegate, DocumentViewControllerDelegate {

    private let fileURL: URL
    private let presetsManager: HBPresetsManager

    private weak var delegate: DocumentDelegate?

    @IBOutlet weak var leftItem: NSToolbarItem!

    override var windowNibName : NSNib.Name? {
        return "DocumentController"
    }

    init(fileURL: URL, presetsManager: HBPresetsManager, delegate: DocumentDelegate) {
        self.presetsManager = presetsManager
        self.fileURL = fileURL
        self.delegate = delegate

        super.init(window: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        guard let window = window else {
            fatalError("`window` is expected to be non nil by this time.")
        }

        window.title = self.fileURL.lastPathComponent
        window.titleVisibility = .hidden

        window.contentViewController = DocumentViewController(fileURL: self.fileURL, presetsManager: self.presetsManager, delegate: self)
    }

    func windowWillClose(_ notification: Notification) {
        delegate?.documentDidClose(self)
    }

    func setLeftToolbarView(_ view: NSView) {
        if let oldView = self.leftItem.view?.subviews.first {
            self.leftItem.view?.animator().replaceSubview(oldView, with: view)
        }
        else {
            self.leftItem.view?.addSubview(view)
        }
    }

}
