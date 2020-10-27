//
//  Health.swift
//
//
// Singleton for handle communicating with apple HealthKit fore read and write health record.
//
//  Created by slee on 28/9/2020.
//  Copyright © 2020 sclee. All rights reserved.
//

import Foundation


import HealthKit
import SwiftUI



enum TaichiType: Int{
    
 // Int value received from STWIN
    case flow = 4
    case updown = 8
    case open = 12
    case push = 16
    case circle = 20
    
    
    // return desc. string of the type
    var description : String {
      switch self {
      
        case .flow: return "Flow"
        case .updown: return "Updown"
        case .open: return "Open"
        case .push: return "Push"
        case .circle: return "Circle"
      
      }
    }
   
    // return icon image of the type
    var getImage : Image {
        switch self {
            case .flow: return Image("flow")
            case .updown: return Image("updown")
            case .open: return Image("open")
            case .push: return Image("push")
            case .circle: return Image("circle")
            
        }
        
        
    }
    

 
    
    // return calore value
    // The return value only for technical demonstration and not rigorous for clinical
    func getCalorie(_ duration:Double) -> Double  {
        switch self {
            case .flow: return 10.0*duration
            case .updown: return 15.0*duration
            case .open: return 20.0*duration
            case .push: return 25*duration
            case .circle: return 30*duration
            
        }
        
        
    }
}

class Health: ObservableObject, BTTaiChiDelegate {
    
    static var instant:Health = Health();
    var healthStore:HKHealthStore!
    var anchor:HKQueryAnchor!;
    var query:HKAnchoredObjectQuery!;
    
    @Published var taiChiItems:[TaiChiItem] = []
    
    
    // BT callback for received new data
    func didNewData(items: [TaichiType],start:[Date],end:[Date]) {
        for (i,item) in items.enumerated() {
            add(item,start[i],end[i])
        }
    }
    
    private init(){
        BT.getInstant().setTaiChiDelegate(delegate: self)
    }
    
    static func getInstant()->Health{
        return instant
    }
    
    func getItems()->[TaiChiItem]{
        
        return taiChiItems
    }
    
    
    /*
     * Init HealthKit
     */
     func healthConnect(){

        if HKHealthStore.isHealthDataAvailable() {
            
            
            // get instead of HKHealth
            healthStore = HKHealthStore()
            
            // Set type of health data request gain of read authorization
            let readTypes = Set([HKObjectType.workoutType(),
                                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                HKObjectType.quantityType(forIdentifier: .heartRate)!])
            
            // Set type of health data request gain of write authorization
            let writeTypes = Set([HKObjectType.workoutType(),
                                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!])

            healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { (success, error) in
                if !success {
                    return
                }
                
            }
            
        }
    
    }
    
    /*   add
     *  Add new Health record
     *
     */
    func add(_ type:TaichiType,_ start:Date,_ end: Date){
        
        
        if healthStore==nil || healthStore.authorizationStatus(for: HKObjectType.workoutType()) != .sharingAuthorized{
            return
        }
        

        let metadata = [HKMetadataKeyIndoorWorkout:false,"taichiType":type.rawValue] as [String : Any]
        

        var calorie:Double;
        
        
        let dur:Double = Double(Int(end.timeIntervalSince(start)))
        
        if dur<1.0 {
            return;
        }
        
        calorie = type.getCalorie(dur)
        
        
        let energyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calorie)
        
        let taichi = HKWorkout(activityType: .mindAndBody,
                             start: start, end: end, duration: dur,
                             totalEnergyBurned: energyBurned,totalDistance: nil,  metadata: metadata)
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
         
        healthStore.save(taichi) { (success, error) -> Void in
            guard success else {
                // Perform proper error handling here...
                fatalError("*** An error occurred while saving this " +
                    "workout: \(String(describing: error?.localizedDescription))")
            }
            
            
        }
    }
   
    /*   get
     *  get all record and update UI list
     *
     */
    
     func get() {
        
       // self.anchor = nil
       // self.taiChiItems.removeAll()

        
        // Check authorization status
        if healthStore==nil || healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .notDetermined{
                  return
              }
        
        // Use Anchored Query for listening update feedback
        
        if query != nil {
           return
          
            
           
           // healthStore.execute(query)
            
           // return
        }
        
        Health.getInstant().anchor = nil;
        taiChiItems.removeAll()
        
        
      query = HKAnchoredObjectQuery(type: .workoutType(),predicate: nil, anchor: self.anchor, limit: HKObjectQueryNoLimit){query,samples,deletes,anchor,error in
            
            
            if error != nil{
                return
            }
            
            self.anchor = anchor
            
            // Insert All health samples to the UI list
            for sample in samples!  {
                
                
                // Check is WorkOut type
                if sample.sampleType is HKWorkoutType{
                    
                    // confirm the sample is created by this app
                    guard sample.metadata!["taichiType"] != nil else {
                        continue
                    }
                    // Append new samples on UI list
                    DispatchQueue.main.async {
                     //   self.objectWillChange.send()
                        self.taiChiItems.append(TaiChiItem(sample as! HKWorkout))
                    }
                }
            }
      
        }
        
        
        
        
        // Handler for HealthKit samples add/update
        query.updateHandler = {
            
            
            query,samples,deletes,anchor,error in

             for sample in samples!  {
                var newItem = true;
                
                if sample.metadata!["taichiType"] == nil {
                    continue
                }
                
                // Check is the samples is new
                for item in self.taiChiItems {
                    if item.workout.startDate == sample.startDate &&
                        item.workout.endDate == sample.endDate {
                        newItem = false;
                        break;
                    }
                }
                
                // confirm the sample is created by this app
                if newItem {
                   
                    DispatchQueue.main.async {
                     //   self.objectWillChange.send()
                        self.taiChiItems.append(TaiChiItem(sample as! HKWorkout))
                    }
                }
                
               
                    
            }
            
            // read delete list and remove item in UI lists
            for delete in deletes! {
                       
                        for(index,item) in self.taiChiItems.enumerated().reversed(){
                         if item.workout.uuid == delete.uuid {
                             DispatchQueue.main.async {
                          //      self.objectWillChange.send()
                                 self.taiChiItems.remove(at:index)
                                 }
                             break;
                             }
                        }
                
              
                        
                        
                    }
            
        }
        
        
        healthStore.execute(query)
        
       
    }
    
    
    // Delete health data 
    func delete(workout:HKWorkout){
        
        if healthStore==nil || healthStore.authorizationStatus(for: HKObjectType.workoutType()) != .sharingAuthorized {
                         return
                     }
     
        healthStore.delete(workout){success,error in
            guard success else {
                           // Perform proper error handling here...
                           fatalError("*** An error occurred while delete this " +
                               "workout: \(String(describing: error?.localizedDescription))")
                       }
        }
        
      
        
    }
    

    
   
}
