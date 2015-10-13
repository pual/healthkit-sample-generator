//
//  ExportViewController.swift
//  HealthKitSampleGenerator
//
//  Created by Michael Seemann on 02.10.15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import HealthKitSampleGenerator

class ExportViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tfProfileName:       UITextField!
    @IBOutlet weak var btnExport:           UIButton!
    @IBOutlet weak var avExporting:         UIActivityIndicatorView!
    @IBOutlet weak var tvOutputFileName:    UITextView!
    @IBOutlet weak var swOverwriteIfExist:  UISwitch!
    @IBOutlet weak var scExportType:        UISegmentedControl!
    @IBOutlet weak var tvExportDescription: UITextView!
    @IBOutlet weak var tvExportMessages:    UITextView!
    @IBOutlet weak var pvExportProgress:    UIProgressView!
    
    var exportConfigurationValid = false {
        didSet {
            btnExport.enabled = exportConfigurationValid
        }
    }
    
    var exportConfiguration : ExportConfiguration = ExportConfiguration(){
        didSet {
            tvOutputFileName.text = exportConfiguration.outputFielName
            switch exportConfiguration.exportType {
            case .ALL:
                self.tvExportDescription.text = "All accessable health data wil be exported."
            case .ADDED_BY_THIS_APP :
                self.tvExportDescription.text = "All health data will be exported, that has been added by this app - e.g. they are imported from a profile."
            case .GENERATED_BY_THIS_APP :
                self.tvExportDescription.text = "All health data will be exported that has been generated by this app - e.g. they are not created through an import of a profile but generated by code. "
            }
        }
    }
    
    var exportInProgress = false {
        didSet {
            avExporting.hidden      = !exportInProgress
            btnExport.enabled       = !exportInProgress
            pvExportProgress.hidden = !exportInProgress
        }
    }
    
    var outputFielName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tfProfileName.text                  = "output"
        tfProfileName.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
        scExportType.selectedSegmentIndex   = HealthDataToExportType.allValues.indexOf(HealthDataToExportType.ALL)!
        
        tvExportMessages.text               = ""
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        exportInProgress = false
        createAndAnalyzeExportConfiguration()
    }
    
    @IBAction func scEpxortDataTypeChanged(sender: AnyObject) {
        createAndAnalyzeExportConfiguration()
    }
    
    @IBAction func doExport(_: AnyObject) {
        exportInProgress = true
        self.pvExportProgress.progress = 0.0

        exportConfiguration.outputStream = NSOutputStream.init(toFileAtPath: exportConfiguration.outputFielName!, append: false)!
        exportConfiguration.outputStream!.open()
        
        HealthKitDataExporter().export(
            
            exportConfiguration,
            
            onProgress: {(message: String, progressInPercent: NSNumber?)->Void in
                dispatch_async(dispatch_get_main_queue(), {
                    self.tvExportMessages.text = message
                    if let progress = progressInPercent {
                        self.pvExportProgress.progress = progress.floatValue
                    }
                })
            },
            
            onCompletion: {(error: ErrorType?)-> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    if let exportError = error {
                        self.tvExportMessages.text = "Export error: \(exportError)"
                        print(exportError)
                    }
                    
                    self.exportConfiguration.outputStream!.close()
                    self.exportInProgress = false
                })
            }
        )
    }
    
    @IBAction func swOverwriteIfExistChanged(sender: AnyObject) {
        createAndAnalyzeExportConfiguration()
    }
    
    func createAndAnalyzeExportConfiguration(){
        var fileName = "output"
        if let text = tfProfileName.text where !text.isEmpty {
            fileName = FileNameUtil.normalizeName(text)
        }
        
        exportConfiguration = ExportConfiguration()
        
        let documentsUrl = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        
        exportConfiguration.outputFielName          = documentsUrl.URLByAppendingPathComponent(fileName+".json.hsg").path!
        exportConfiguration.exportType              = HealthDataToExportType.allValues[scExportType.selectedSegmentIndex]
        exportConfiguration.profileName             = tfProfileName.text
        exportConfiguration.overwriteIfFileExist    = swOverwriteIfExist.on
        
        exportConfigurationValid = exportConfiguration.isValid()
    }

    func textFieldDidChange(_: UITextField) {
       createAndAnalyzeExportConfiguration()
    }

    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
