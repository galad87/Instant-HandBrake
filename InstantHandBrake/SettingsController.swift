//
//  SettingsController.swift
//  InstantHandBrake
//
//  Created by Damiano Galassi on 03/03/16.
//  Copyright © 2016 HandBrake. All rights reserved.
//

import Cocoa
import HandBrakeKit

protocol SettingsControllerDelegate : class {
    func encodeJobs(jobs: [HBJob])
}

class SettingsController: NSViewController, Toolbared {

    private let core: HBCore
    private weak var delegate: SettingsControllerDelegate?

    // MARK: - Preset settings

    private let presetsManager: HBPresetsManager
    private var preset: HBPreset

    private var preferredAudioLang = "und"
    private var preferredSubtitlesLang = "und"

    // MARK: - Titles

    class TitleItem : NSObject {
        let title: HBTitle
        var enabled: Bool

        init(title: HBTitle, enabled: Bool = true) {
            self.title = title
            self.enabled = true
        }
    }

    private dynamic var items = [TitleItem]()
    private var destURL = NSURL(fileURLWithPath: "/")

    // MARK: - UI

    @IBOutlet var leftToolbarItem: NSView!

    @IBOutlet weak var destinationPopUp: NSPopUpButton!

    @IBOutlet weak var presetsPopUp: NSPopUpButton!
    @IBOutlet weak var audioPopUp: NSPopUpButton!
    @IBOutlet weak var subtitlesPopUp: NSPopUpButton!

    // MARK: - Init

    init?(core: HBCore, presetsManager: HBPresetsManager, delegate: SettingsControllerDelegate) {
        self.core = core

        self.presetsManager = presetsManager
        self.preset = presetsManager.defaultPreset

        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        items = core.titles.map({ TitleItem(title: $0) })

        buildDestinationPopUp()
        buildPresetPopUp()
        buildAudioPopUp()
        buildSubtitlesPopUp()
    }

    // MARK: - Destination popup

    @IBAction func handleDestination(sender: AnyObject) {
    }

    @IBAction func chooseDestination(sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Choose"

        func modalCompletionHandler(modalResponse: NSModalResponse) {
            if let URL = panel.URL where modalResponse == NSFileHandlingPanelOKButton {
                let item = self.prepareDestinationPopUpItem(URL)

                self.destinationPopUp.menu?.removeItemAtIndex(0)
                self.destinationPopUp.menu?.insertItem(item, atIndex: 0)

                self.destURL = URL

                NSUserDefaults.standardUserDefaults().setURL(URL, forKey: "destination")
            }

            self.destinationPopUp.selectItemAtIndex(0)
        }

        if let sheetParent = view.window {
            panel.beginSheetModalForWindow(sheetParent, completionHandler: modalCompletionHandler)
        }
        else {
            panel.beginWithCompletionHandler(modalCompletionHandler)
        }
    }

    private func prepareDestinationPopUpItem(destURL: NSURL) -> NSMenuItem {
        let sel = #selector(self.handleDestination(_:))
        let item = NSMenuItem(title: destURL.lastPathComponent!, action: sel, keyEquivalent: "")
        item.target = self

        let icon = NSWorkspace.sharedWorkspace().iconForFile(destURL.path!)
        icon.size = NSSize(width: 16, height: 16)
        item.image = icon

        return item
    }

    private func buildDestinationPopUp() {
        if let savedURL = NSUserDefaults.standardUserDefaults().URLForKey("destination"),
            let path = savedURL.path where NSFileManager.defaultManager().fileExistsAtPath(path) {
            self.destURL = savedURL
        }
        else if let movieFolderURL = NSSearchPathForDirectoriesInDomains(.MoviesDirectory, .UserDomainMask, true).first {
            self.destURL = NSURL(fileURLWithPath:movieFolderURL)
        }

        let folderItem = self.prepareDestinationPopUpItem(self.destURL)

        self.destinationPopUp.menu?.removeItemAtIndex(0)
        self.destinationPopUp.menu?.insertItem(folderItem, atIndex: 0)

        self.destinationPopUp.selectItemAtIndex(0)
    }

    // MARK: - Presets popup

    private func buildPresetPopUp() {
        self.presetsManager.root.enumerateObjectsUsingBlock({ (obj: AnyObject, idx: NSIndexPath, stop: UnsafeMutablePointer<ObjCBool>) in
            if let preset = obj as? HBPreset where idx.length > 0 {

                let item = NSMenuItem()
                item.title = preset.name
                if preset.isLeaf {
                    item.representedObject = preset
                    item.action = #selector(self.handlePresetPopup(_:))
                    item.target = self
                }
                else {
                    item.enabled = false
                }
                item.indentationLevel = idx.length - 1

                self.presetsPopUp.menu?.addItem(item)

                if preset == self.preset {
                    self.presetsPopUp.selectItem(item)
                }
            }
        })
    }

    @IBAction func handlePresetPopup(sender: NSMenuItem) {
        if let preset = (sender.representedObject as? HBPreset) {
            self.preset = preset
        }
    }

    // MARK: - Audio and subtitles language popup

    private func buildLanguagesMenu<T: CollectionType where T.Generator.Element == String>(menu: NSMenu, languages: T) {
        for lang in languages {
            let item = NSMenuItem()
            item.title = HBUtilities.languageCodeForIso6392Code(lang)
            item.representedObject = lang
            menu.addItem(item)
        }
    }

    private func buildAudioPopUp() {
        let languages = Set(items.flatMap{ $0.title.audioTracks.flatMap{ $0[keyAudioTrackLanguageIsoCode] as? String } })
        buildLanguagesMenu(audioPopUp.menu!, languages: languages)
    }

    @IBAction func handleAudioPopUp(sender: NSPopUpButton) {
        if let lang = sender.selectedItem?.representedObject as? String {
            self.preferredAudioLang = lang
        }
    }

    private func buildSubtitlesPopUp() {
        let languages = Set(items.flatMap{ $0.title.subtitlesTracks.flatMap{ $0["keySubTrackLanguageIsoCode"] as? String } })
        buildLanguagesMenu(subtitlesPopUp.menu!, languages: languages)
    }

    @IBAction func handleSubtitlesPopup(sender: NSPopUpButton) {
        if let lang = sender.selectedItem?.representedObject as? String {
            self.preferredSubtitlesLang = lang
        }
    }

    // MARK: - Toolbar

    func prepareJob(title: HBTitle) -> HBJob {
        let p = self.preset.mutableCopy() as! HBMutablePreset

        let audioLanguages = Set(title.audioTracks.flatMap{ $0[keyAudioTrackLanguageIsoCode] as? String })
        let subLanguages = Set(title.subtitlesTracks.flatMap{ $0["keySubTrackLanguageIsoCode"] as? String })

        if audioLanguages.contains(preferredAudioLang) {
            p.setObject(preferredAudioLang, forKey: "AudioLanguageList")
        }

        if subLanguages.contains(preferredSubtitlesLang) {
            p.setObject(preferredAudioLang, forKey: "SubtitleLanguageList")
        }

        let job = HBJob(title: title, andPreset: self.preset)
        let fileName = title.name + ".mp4"
        job.destURL = self.destURL.URLByAppendingPathComponent(fileName)

        return job
    }

    @IBAction func handleEncode(sender: AnyObject) {
        var jobs = [HBJob]()

        for item in items.filter({ $0.enabled }) {
            let job = prepareJob(item.title)
            jobs.append(job)
        }

        self.delegate?.encodeJobs(jobs)
    }

}
