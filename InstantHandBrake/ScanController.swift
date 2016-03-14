//
//  ScanController.swift
//  InstantHandBrake
//
//  Created by Damiano Galassi on 03/03/16.
//  Copyright © 2016 HandBrake. All rights reserved.
//

import Cocoa
import HandBrakeKit

protocol ScanControllerDelegate : class {
    func scanDone(titles: [HBTitle])
}

class ScanController: NSViewController, Toolbared {

    private let core: HBCore
    private weak var delegate: ScanControllerDelegate?

    @IBOutlet var leftToolbarItem: NSView!

    @IBOutlet weak var percentLabel: NSTextField!
    @IBOutlet weak var progressIndicator: KDCircularProgress!

    init?(core: HBCore, delegate: ScanControllerDelegate) {
        self.core = core
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func scan(fileURL: NSURL) {
        self.core.scanURL(fileURL, titleIndex: 0, previews: 10, minDuration: 10,
                          progressHandler: handleProgress,
                          completionHandler: handleCompletion)

    }

    @IBAction func handleCancel(sender: AnyObject) {
        self.core.cancelScan()
    }
    
    private func handleProgress(state: HBState, progress: HBProgress, info: String) {
        self.percentLabel.stringValue = String(format: "%.0f %%", arguments: [progress.percent * 100])
        self.progressIndicator.angle = Int(progress.percent * 360)
    }

    private func handleCompletion(result: HBCoreResult) {
        delegate?.scanDone(self.core.titles)
    }

}
