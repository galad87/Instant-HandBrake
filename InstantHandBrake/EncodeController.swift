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
        showInFinderButton.hidden = true
    }

    func encodeJobs(jobs: [HBJob]) {
        self.jobs = jobs
        self.remainingJobs = jobs;

        encodeNextJob()
    }

    private func encodeNextJob() -> Bool {
        if let job = remainingJobs.first {
            remainingJobs.removeAtIndex(remainingJobs.indexOf(job)!)

            core.encodeJob(job, progressHandler: handleProgress,
                           completionHandler: handleCompletion)

            if jobs.count > 1 {
                let current = jobs.count - remainingJobs.count
                let total = jobs.count
                jobNumberLabel.stringValue = "\(current) of \(total)"
            }
            else {
                jobNumberLabel.hidden = true
            }
            return true
        }
        return false
    }

    @IBAction func showInFinder(sender: AnyObject) {
        let urls = jobs.flatMap{ $0.destURL }

        let workspace = NSWorkspace.sharedWorkspace()
        workspace.activateFileViewerSelectingURLs(urls)
    }

    @IBAction func handleCancel(sender: AnyObject) {
        let alert = NSAlert()
        alert.messageText = "Stop This Encode?"
        alert.informativeText = "Your movie will be lost if you don't continue encoding."
        alert.addButtonWithTitle("Keep Encoding")
        alert.addButtonWithTitle("Stop Encoding")
        alert.alertStyle = .CriticalAlertStyle

        alert.beginSheetModalForWindow(self.view.window!) { (response: NSModalResponse) in
            if response == NSAlertSecondButtonReturn {
                self.jobs.removeAll()
                self.remainingJobs.removeAll()
                self.core.cancelEncode()
            }
        }

        self.alert = alert
    }

    @IBAction func handlePause(sender: AnyObject) {
        if core.state == .Paused {
            core.resume()
            pauseButton.image = NSImage(imageLiteral: "pauseBlackTemplate")
        }
        else if core.state == .Working {
            core.pause()
            pauseButton.image = NSImage(imageLiteral: "playBackTemplate")
        }
    }

    private func handleProgress(state: HBState, progress: HBProgress, info: String) {
        percentLabel.stringValue = String(format: "%.0f %%", arguments: [progress.percent * 100])
        if progress.seconds > -1 {
            etaLabel.stringValue = String(format: "%02dh%02dm%02ds", arguments: [progress.hours, progress.minutes, progress.seconds])
        }

        self.circularIndicator.angle = min(Int(progress.percent * 360), 360)
    }

    private func handleCompletion(result: HBCoreResult) {
        if self.encodeNextJob() == false {
            circularIndicator.angle = 360

            percentLabel.stringValue = "100 %"

            switch result {
            case .Done:
                etaLabel.stringValue = "Completed"
            case .Cancelled:
                etaLabel.stringValue = "Cancelled"
            case .Failed:
                etaLabel.stringValue = "Failed"
            }

            pauseButton.enabled = false
            stopButton.enabled = false

            jobNumberLabel.hidden = true
            showInFinderButton.hidden = false
        }

        if let alert = self.alert {
            alert.buttons.first?.performClick(self)
        }
    }

}
