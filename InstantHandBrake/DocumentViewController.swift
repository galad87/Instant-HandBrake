//
//  DocumentViewController.swift
//  InstantHandBrake
//
//  Created by Damiano Galassi on 03/03/16.
//  Copyright © 2016 HandBrake. All rights reserved.
//

import Cocoa
import HandBrakeKit

protocol DocumentViewControllerDelegate : class {
    func setLeftToolbarView(_ view: NSView)
}

class DocumentViewController: NSViewController, SettingsControllerDelegate, ScanControllerDelegate {

    private let core: HBCore = HBCore()
    private let presetsManager: HBPresetsManager

    private let fileURL: URL

    private lazy var scanController : ScanController  = {
        return ScanController(core: self.core, delegate: self)!
    }()

    private lazy var settingsController : SettingsController = {
        return SettingsController(core: self.core,
                                  presetsManager: self.presetsManager,
                                  delegate: self)!
    }()

    private lazy var encodeController : EncodeController = {
        return EncodeController(core: self.core)!
    }()

    private weak var delegate: DocumentViewControllerDelegate?

    init?(fileURL: URL, presetsManager: HBPresetsManager, delegate: DocumentViewControllerDelegate) {
        self.fileURL = fileURL
        self.presetsManager = presetsManager
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(scanController)
        view.addSubview(scanController.view)
        delegate?.setLeftToolbarView(scanController.leftToolbarItem)

        scanController.scan(fileURL)
    }

    override func addChild(_ childViewController: NSViewController) {
        childViewController.view.frame = self.view.bounds
        childViewController.view.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]

        super.addChild(childViewController)
    }

    private func transitionFromViewController<T: NSViewController>(_ fromViewController: NSViewController, toViewController: T) where T:Toolbared {
        addChild(toViewController)

        CATransaction.begin()
        delegate?.setLeftToolbarView(toViewController.leftToolbarItem)
        transition(from: fromViewController, to: toViewController, options: NSViewController.TransitionOptions.slideForward, completionHandler: nil)
        CATransaction.commit()
    }

    func scanDone(_ titles: [HBTitle]) {
        if titles.count > 0 {
            transitionFromViewController(scanController, toViewController: settingsController)
        }
    }

    func encode(jobs: [HBJob]) {
        if jobs.count > 0 {
            transitionFromViewController(settingsController, toViewController: encodeController)
            encodeController.encode(jobs: jobs)
        }
    }

}
