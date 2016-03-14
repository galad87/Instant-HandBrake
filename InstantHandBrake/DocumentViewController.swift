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
    func setLeftToolbarView(view: NSView)
}

class DocumentViewController: NSViewController, SettingsControllerDelegate, ScanControllerDelegate {

    private let core: HBCore = HBCore()
    private let presetsManager: HBPresetsManager

    private let fileURL: NSURL

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

    init?(fileURL: NSURL, presetsManager: HBPresetsManager, delegate: DocumentViewControllerDelegate) {
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

        addChildViewController(scanController)
        view.addSubview(scanController.view)
        delegate?.setLeftToolbarView(scanController.leftToolbarItem)

        scanController.scan(fileURL)
    }

    override func addChildViewController(childViewController: NSViewController) {
        childViewController.view.frame = self.view.bounds
        childViewController.view.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]

        super.addChildViewController(childViewController)
    }

    private func transitionFromViewController<T: NSViewController where T:Toolbared>(fromViewController: NSViewController, toViewController: T) {
        addChildViewController(toViewController)

        CATransaction.begin()
        delegate?.setLeftToolbarView(toViewController.leftToolbarItem)
        transitionFromViewController(fromViewController, toViewController: toViewController, options: .SlideForward, completionHandler: nil)
        CATransaction.commit()
    }

    func scanDone(titles: [HBTitle]) {
        if titles.count > 0 {
            transitionFromViewController(scanController, toViewController: settingsController)
        }
    }

    func encodeJobs(jobs: [HBJob]) {
        if jobs.count > 0 {
            transitionFromViewController(settingsController, toViewController: encodeController)
            encodeController.encodeJobs(jobs)
        }
    }

}
