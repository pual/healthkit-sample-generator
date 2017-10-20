//
//  UIUtil.swift
//  HealthKitSampleGenerator
//
//  Created by Michael Seemann on 25.10.15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class UIUtil {
    
    let formatter = DateFormatter()
    let fileNameFormatter = DateFormatter()
    
    static let sharedInstance = UIUtil()
    
    private init(){
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.medium
        
        fileNameFormatter.dateFormat = "yyyyMMddHHmmss"
    }
    
    func formatDate(date: Date?) -> String {
        return date != nil ? formatter.string(from: date!) : "unknown"
    }
    
    func formatDateForFileName(date: Date?) -> String {
        return date != nil ? fileNameFormatter.string(from: date!) : "unknown"
    }
}
