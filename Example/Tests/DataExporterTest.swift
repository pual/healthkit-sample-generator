//
//  DataExporterTest.swift
//  HealthKitSampleGenerator
//
//  Created by Michael Seemann on 19.10.15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import XCTest
import Quick
import Nimble
import HealthKit
@testable import HealthKitSampleGenerator

class DataExporterTest: QuickSpec {
    
    let healthStore = HealthKitStoreMock()
    
    let profileName = "testName"

    
    override func spec() {
 
        var exportConfiguration = HealthDataFullExportConfiguration(profileName: self.profileName, exportType: HealthDataToExportType.ALL)
        exportConfiguration.exportUuids = true
        
        describe("MetaData and UserData Export") {
            
            it("should make sure the JsonSingleDocInMemExportTarget is always valid"){
                let target = JsonSingleDocInMemExportTarget()
                
                expect(target.isValid()) == true
            }
            
            it ("should export the meta data") {
            
                let exporter = MetaDataExporter(exportConfiguration: exportConfiguration)
                
                let target = JsonSingleDocInMemExportTarget()
                target.startExport()
                
                try! exporter.export(self.healthStore, exportTargets: [target])
                
                target.endExport()
                                
                let metaDataDict = JsonReader.toJsonObject(target.getJsonString(), returnDictForKey:HealthKitConstants.META_DATA)
                
                expect(metaDataDict[HealthKitConstants.CREATION_DATE] as? NSNumber).notTo(beNil())
                expect(metaDataDict[HealthKitConstants.PROFILE_NAME] as? String)  == self.profileName
                expect(metaDataDict[HealthKitConstants.VERSION] as? String)      == "1.0.0"
                expect(metaDataDict[HealthKitConstants.TYPE] as? String)         == "JsonSingleDocExportTarget"

            }
            
            it ("should export the user data") {
                let exporter = UserDataExporter(exportConfiguration: exportConfiguration)
                
                let target = JsonSingleDocInMemExportTarget()
                target.startExport()
                
                try! exporter.export(self.healthStore, exportTargets: [target])
                
                target.endExport()
                
                let userDataDict = JsonReader.toJsonObject(target.getJsonString(), returnDictForKey:"userData")
                
                let dateOfBirth         = userDataDict[HealthKitConstants.DATE_OF_BIRTH] as? NSNumber
                let biologicalSex       = userDataDict[HealthKitConstants.BIOLOGICAL_SEX] as? Int
                let bloodType           = userDataDict[HealthKitConstants.BLOOD_TYPE] as? Int
                let fitzpatrickSkinType = userDataDict[HealthKitConstants.FITZPATRICK_SKIN_TYPE] as? Int
                
                let date = Date(timeIntervalSince1970: (dateOfBirth?.doubleValue)! / 1000.0)
                
                expect(try! self.healthStore.dateOfBirth())  == date
                
                expect(biologicalSex)       == HKBiologicalSex.male.rawValue
                expect(bloodType)           == HKBloodType.aPositive.rawValue
                expect(fitzpatrickSkinType) == HKFitzpatrickSkinType.I.rawValue
                
            }
        }
        
        describe("QuantityType Exports") {
        
            let type  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
            let strUnit = "kg"
            let unit = HKUnit(from: strUnit)
            
            let exporter = QuantityTypeDataExporter(exportConfiguration: exportConfiguration, type: type, unit: unit)
            
            it("should export quantity data") {

                let target = JsonSingleDocInMemExportTarget()
                target.startExport()
                
                target.startWriteType(type)
                
                let date = Date()
                let quantity = HKQuantity(unit: unit, doubleValue: 70)
                let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
                
                exporter.writeResults([sample], exportTargets: [target], error: nil)

                target.endWriteType()
                
                target.endExport()
                
                let dataArray = JsonReader.toJsonObject(target.getJsonString(), returnArrayForKey:String(describing: HKQuantityTypeIdentifier.bodyMass))
                
                
                expect(dataArray.count) == 1
                
                let savedSample = dataArray.first as! Dictionary<String, AnyObject>
             
                
               
                let sdate       = savedSample[HealthKitConstants.S_DATE] as! NSNumber
                let uuid        = savedSample[HealthKitConstants.UUID] as! String
                let value       = savedSample[HealthKitConstants.VALUE] as! Double
                let unitValue   = savedSample[HealthKitConstants.UNIT] as! String
                
                expect(sdate).to(beCloseTo(date.timeIntervalSince1970 * 1000, within: 1000))
                expect(uuid).notTo(beNil())
                expect(value) == quantity.doubleValue(for: unit)
                expect(savedSample[HealthKitConstants.E_DATE]).to(beNil())
                expect(unitValue) == strUnit

            }
            
            it ("should handle healthkit query errors") {
                
                exporter.writeResults([], exportTargets: [], error: NSError(domain: "", code: 0, userInfo: [:]))
                expect{try exporter.rethrowCollectedErrors()}.to(throwError())
            }
        }

    
        describe("CategoryTypeDataExporter") {
            
            let type = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.appleStandHour)!
            
            let exporter = CategoryTypeDataExporter(exportConfiguration: exportConfiguration, type: type)
            
            it ("should export category types"){
                
                let target = JsonSingleDocInMemExportTarget()
                target.startExport()
                target.startWriteType(type)
                
                let date = Date()
                
                let sample = HKCategorySample(type: type, value: 1, start: date, end: date)
                
                exporter.writeResults([sample], exportTargets: [target], error: nil)
                
                target.endWriteType()
                
                target.endExport()
                
                let dataArray = JsonReader.toJsonObject(target.getJsonString(), returnArrayForKey:String(describing: HKCategoryTypeIdentifier.appleStandHour))
                
                expect(dataArray.count) == 1
                
                let savedSample = dataArray.first as! Dictionary<String, AnyObject>
            
                let sdate   = savedSample[HealthKitConstants.S_DATE] as! NSNumber
                let uuid    = savedSample[HealthKitConstants.UUID] as! String
                let value   = savedSample[HealthKitConstants.VALUE] as! NSNumber
                
                expect(sdate).to(beCloseTo(date.timeIntervalSince1970 * 1000, within: 1000))
                expect(uuid).notTo(beNil())
                expect(value) == 1
                
                expect(savedSample[HealthKitConstants.E_DATE]).to(beNil())
            
            }
            
            
            it ("should handle healthkit query errors") {
                exporter.writeResults([], exportTargets: [], error: NSError(domain: "", code: 0, userInfo: [:]))
                expect{try exporter.rethrowCollectedErrors()}.to(throwError())
            }
        }
        
        describe("CorrelationTypeDataExporter") {
            let unit = HKUnit(from: "mmHg")
            let type1 = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!
            let type2 = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!
            
            let type = HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!
            let exporter = CorrelationTypeDataExporter(exportConfiguration: exportConfiguration, type: type, typeMap:[type1:unit,type2:unit])
            
            it ("should export correlation types") {
                
                let target = JsonSingleDocInMemExportTarget()
                target.startExport()
                target.startWriteType(type)

                
                let quantity1 = HKQuantity(unit: unit, doubleValue: 80)
                let quantity2 = HKQuantity(unit: unit, doubleValue: 120)
                
                let date = Date()
                
                let samples: [HKSample] = [
                    HKQuantitySample(type: type1, quantity: quantity1, start: date, end: date),
                    HKQuantitySample(type: type2, quantity: quantity2, start: date, end: date)
                ]

                let correlation = HKCorrelation(type: type, start: date, end: date, objects: Set(samples))
                
                exporter.writeResults([correlation], exportTargets: [target], error: nil)

                target.endWriteType()
                
                target.endExport()
                
                let dataArray = JsonReader.toJsonObject(target.getJsonString(), returnArrayForKey:String(describing: HKCorrelationTypeIdentifier.bloodPressure))
                
                expect(dataArray.count) == 1
                
                let savedCorrelation = dataArray.first as! Dictionary<String, AnyObject>
                
                
                let sdate   = savedCorrelation[HealthKitConstants.S_DATE] as! NSNumber
                let uuid    = savedCorrelation[HealthKitConstants.UUID] as! String
                let objects   = savedCorrelation[HealthKitConstants.OBJECTS] as! [AnyObject]
                
                expect(sdate).to(beCloseTo(date.timeIntervalSince1970 * 1000, within: 1000))
                expect(uuid).notTo(beNil())
                expect(objects.count) == 2
                expect(savedCorrelation[HealthKitConstants.E_DATE]).to(beNil())
                
                for object in objects {
                    let dictObject = object as! Dictionary<String, AnyObject>
                    let oUuid = dictObject[HealthKitConstants.UUID] as! String
                    let oType = dictObject[HealthKitConstants.TYPE] as! String
                    
                    expect(oUuid).notTo(beNil())
                    expect(oType).to(contain("HKQuantityTypeIdentifierBloodPressure"))
                }

            }
            
            it ("should handle healthkit query errors") {
                exporter.writeResults([], exportTargets: [], error: NSError(domain: "", code: 0, userInfo: [:]))
                expect{try exporter.rethrowCollectedErrors()}.to(throwError())
            }
        }
        
        describe("WorkoutDataExporter") {
            
            let exporter = WorkoutDataExporter(exportConfiguration: exportConfiguration)
            
            it("should export workouts"){
                let start = Date()
                let pause = start.addingTimeInterval(60*2) // + 2 minutes
                let resume = start.addingTimeInterval(60*3) // + 3 minutes
                let end = start.addingTimeInterval(60*10) // + 10 minutes
                
                let events : [HKWorkoutEvent] = [HKWorkoutEvent(type: HKWorkoutEventType.pause, date: pause), HKWorkoutEvent(type: HKWorkoutEventType.resume, date: resume)]
                let burned = HKQuantity(unit: HKUnit(from: "kcal"), doubleValue: 200.6)
                let distance = HKQuantity(unit: HKUnit(from: "km"), doubleValue: 4.5)
                
                let workout = HKWorkout(activityType: HKWorkoutActivityType.running, start: start, end: end, workoutEvents: events, totalEnergyBurned: burned, totalDistance: distance, metadata: nil)
                
                let target = JsonSingleDocInMemExportTarget()
                target.startExport()
                
                exporter.writeResults([workout], exportTargets: [target], error: nil)
                
                target.endExport()
                
                let dataArray = JsonReader.toJsonObject(target.getJsonString(), returnArrayForKey:String(describing: HKObjectType.workoutType()))
                
                expect(dataArray.count) == 1
                
                let savedWorkout = dataArray.first as! Dictionary<String, AnyObject>
                
                let uuid = savedWorkout[HealthKitConstants.UUID] as! String
                expect(uuid).notTo(beNil())
                
                let workoutActivityType = savedWorkout[HealthKitConstants.WORKOUT_ACTIVITY_TYPE] as! UInt
                expect(workoutActivityType) == HKWorkoutActivityType.running.rawValue
                
                let sDate = savedWorkout[HealthKitConstants.S_DATE] as! NSNumber
                let eDate = savedWorkout[HealthKitConstants.E_DATE] as! NSNumber
                expect(sDate).to(beCloseTo(eDate, within: 60*10*1001))
                
                let duration = savedWorkout[HealthKitConstants.DURATION] as! NSNumber
                expect(duration) == 540 // 9 minutes
                
                let totalDistance = savedWorkout[HealthKitConstants.TOTAL_DISTANCE] as! NSNumber
                expect(totalDistance) == 4500 //meters
                
                let totalEnergyBurned = savedWorkout[HealthKitConstants.TOTAL_ENERGY_BURNED] as! NSNumber
                expect(totalEnergyBurned) == 200.6
                
                
                
                let workoutEvents = savedWorkout[HealthKitConstants.WORKOUT_EVENTS] as! [AnyObject]
                
                let pauseEvent = workoutEvents[0] as! Dictionary<String, AnyObject>
                let pauseSDate = pauseEvent[HealthKitConstants.S_DATE] as! NSNumber
                expect(pauseSDate).to(beGreaterThan(sDate))
                
                let pauseType = pauseEvent[HealthKitConstants.TYPE] as! Int
                expect(pauseType) == HKWorkoutEventType.pause.rawValue
                
                let resumeEvent = workoutEvents[1] as! Dictionary<String, AnyObject>
                let resumeSDate = resumeEvent[HealthKitConstants.S_DATE] as! NSNumber
                expect(resumeSDate).to(beGreaterThan(sDate))
                
                let resumeType = resumeEvent[HealthKitConstants.TYPE] as! Int
                expect(resumeType) == HKWorkoutEventType.resume.rawValue
                
            }
            
            it ("should handle healthkit query errors") {
                exporter.writeResults([], exportTargets: [], error: NSError(domain: "", code: 0, userInfo: [:]))
                expect{try exporter.rethrowCollectedErrors()}.to(throwError())
            }
        }
    }
    
  }
