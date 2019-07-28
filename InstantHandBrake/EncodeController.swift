//
//  EncodeController.swift
//  InstantHandBrake
//
//  Created by Damiano Galassi on 03/03/16.
//  Copyright © 2016 HandBrake. All rights reserved.
//

import Cocoa
import HandBrakeKit

class EncodeController: NSViewController, Toolbared {

    private let core: HBCore

    private var jobs = [HBJob]()
    private var remainingJobs = [HBJob]()

    @IBOutlet var leftToolbarItem: NSView!

    @IBOutlet weak var circularIndicator: KDCircularProgress!

    @IBOutlet weak var percentLabel: NSTextField!
    @IBOutlet weak var etaLabel: NSTextField!
    @IBOutlet weak var jobNumberLabel: NSTextField!

    @IBOutlet weak var showInFinderButton: NSButton!

    @IBOutlet weak var pauseButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!

    private var alert : NSAlert?

    init?(core: HBCore) {
        self.core = core
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        etaLabel.stringValue = ""
        showInFinderButton.isHidden = true
    }

    func encode(jobs: [HBJob]) {
        self.jobs = jobs
        self.remainingJobs = jobs;

        _ = encodeNextJob()
    }

    private func encodeNextJob() -> Bool {
        if let job = remainingJobs.first {
            remainingJobs.remove(at: remainingJobs.firstIndex(of: job)!)

            core.encode(job, progressHandler: handleProgress,
                           completionHandler: handleCompletion)

            if jobs.count > 1 {
                let current = jobs.count - remainingJobs.count
                let total = jobs.count
                jobNumberLabel.stringValue = "\(current) of \(total)"
            }
            else {
                jobNumberLabel.isHidden = true
            }
            return true
        }
        return false
    }

    @IBAction func showInFinder(_ sender: AnyObject) {
        let urls = jobs.compactMap{ job -> URL? in
            if let url = job.outputURL, let name = job.outputFileName {
                return url.appendingPathComponent(name)
            }
            return nil
        }

        let workspace = NSWorkspace.shared
        workspace.activateFileViewerSelecting(urls)
    }

    @IBAction func handleCancel(_ sender: AnyObject) {
        let alert = NSAlert()
        alert.messageText = "Stop This Encode?"
        alert.informativeText = "Your movie will be lost if you don't continue encoding."
        alert.addButton(withTitle: "Keep Encoding")
        alert.addButton(withTitle: "Stop Encoding")
        alert.alertStyle = .critical

        alert.beginSheetModal(for: self.view.window!) { (response: NSApplication.ModalResponse) in
            if response == NSApplication.ModalResponse.alertSecondButtonReturn {
                self.jobs.removeAll()
                self.remainingJobs.removeAll()
                self.core.cancelEncode()
            }
        }

        self.alert = alert
    }

    @IBAction func handlePause(_ sender: AnyObject) {
        if core.state == .paused {
            core.resume()
            pauseButton.image = NSImage(imageLiteralResourceName: "pauseBlackTemplate")
        }
        else if core.state == .working {
            core.pause()
            pauseButton.image = NSImage(imageLiteralResourceName: "playBackTemplate")
        }
    }

    private func handleProgress(_ state: HBState, progress: HBProgress, info: String) {
        percentLabel.stringValue = String(format: "%.0f %%", arguments: [progress.percent * 100])
        if progress.seconds > -1 {
            etaLabel.stringValue = String(format: "%02dh%02dm%02ds", arguments: [progress.hours, progress.minutes, progress.seconds])
        }

        self.circularIndicator.angle = min(Int(progress.percent * 360), 360)
    }

    private func handleCompletion(_ result: HBCoreResult) {
        if self.encodeNextJob() == false {
            circularIndicator.angle = 360

            percentLabel.stringValue = "100 %"

            switch result {
            case .done:
                etaLabel.stringValue = NSLocalizedString("Completed", comment: "Encode -> Completed")
            case .canceled:
                etaLabel.stringValue = NSLocalizedString("Cancelled", comment: "Encode -> Cancelled")
            case .failed:
                etaLabel.stringValue = NSLocalizedString("Failed", comment: "Encode -> Failed")
            @unknown default:
                break;
            }

            pauseButton.isEnabled = false
            stopButton.isEnabled = false

            jobNumberLabel.isHidden = true
            showInFinderButton.isHidden = false
        }

        if let alert = self.alert {
            alert.buttons.first?.performClick(self)
        }
    }

}
