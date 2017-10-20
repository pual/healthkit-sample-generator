//
//  ImportProfileViewController.swift
//  HealthKitSampleGenerator
//
//  Created by Michael Seemann on 25.10.15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import HealthKitSampleGenerator
import HealthKit

import MessageUI
import Zip

class ImportProfileViewController : UIViewController {
    
    @IBOutlet weak var lbProfileName: UILabel!
    @IBOutlet weak var lbCreationDate: UILabel!
    @IBOutlet weak var lbVersion: UILabel!
    @IBOutlet weak var lbType: UILabel!
    
    @IBOutlet weak var swDeleteExistingData: UISwitch!
    @IBOutlet weak var pvImportProgress: UIProgressView!
    @IBOutlet weak var lbImportProgress: UILabel!
    @IBOutlet weak var aiImporting: UIActivityIndicatorView!
    @IBOutlet weak var btImport: UIButton!
    
    let healthStore  = HKHealthStore()
    
    var profile: HealthKitProfile?
    
    var importing = false {
        didSet {
            pvImportProgress.isHidden = !importing
            aiImporting.isHidden = !importing
            navigationItem.hidesBackButton = importing
            swDeleteExistingData.isEnabled = !importing
            btImport.isEnabled = !importing
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.importing          = false
        lbProfileName.text      = ""
        lbCreationDate.text     = ""
        lbVersion.text          = ""
        lbType.text             = ""
        lbImportProgress.text   = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        profile?.loadMetaData(true) { (metaData: HealthKitProfileMetaData) in
            OperationQueue.main.addOperation(){
                self.lbProfileName.text = metaData.profileName
                self.lbCreationDate.text = UIUtil.sharedInstance.formatDate(date: metaData.creationDate)
                self.lbVersion.text = metaData.version
                self.lbType.text = metaData.type
            }
        }
    }
    
    
    @IBAction func doImport(_ sender: AnyObject) {
        importing = true
        lbImportProgress.text = "Start import"
        if let importProfile = profile {
            let importer = HealthKitProfileImporter(healthStore: healthStore)
            importer.importProfile(
                importProfile,
                deleteExistingData: swDeleteExistingData.isOn,
                onProgress: {(message: String, progressInPercent: NSNumber?)->Void in
                    OperationQueue.main.addOperation(){
                        self.lbImportProgress.text = message
                        if let progress = progressInPercent {
                            self.pvImportProgress.progress = progress.floatValue
                        }
                    }
                },
                
                onCompletion: {(error: Error?)-> Void in
                    OperationQueue.main.addOperation(){
                        if let exportError = error {
                            self.lbImportProgress.text = "Import error: \(exportError)"
                            print(exportError)
                        }
                        
                        self.importing = false
                    }
                }
            )
        }
    }
    
    @IBAction func emailData(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setSubject("HealthKit export data")
            mailComposer.setMessageBody("Data generated on " + (lbCreationDate.text ?? "unknown date"), isHTML: false)
            
            if let profile = profile {
                do {
                    let zippedFileName = profile.fileName + ".zip"
                    let zippedFileUrl = try Zip.quickZipFiles([profile.fileAtPath], fileName: zippedFileName, progress: nil)
                    let fileData = try! Data(contentsOf: zippedFileUrl)
                    mailComposer.addAttachmentData(fileData, mimeType: "application/zip", fileName: zippedFileName)
                }
                catch {
                    print("Woops")
                }
            }
            self.present(mailComposer, animated: true, completion: nil)
        }
    }
    
}

extension ImportProfileViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
