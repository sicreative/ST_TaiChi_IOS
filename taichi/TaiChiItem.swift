//
//  TaiChiItem.swift
//  taichi
//
//  Created by slee on 30/9/2020.
//  Copyright © 2020 sclee. All rights reserved.
//

import Foundation
import HealthKit


class TaiChiItem: Identifiable,ObservableObject{

    
    @Published var workout:HKWorkout
    
    
    var type:TaichiType{
        get{
            TaichiType(rawValue:workout.metadata!["taichiType"] as! Int)!
        }
    }
    
    var start:Date{
        get{
            workout.startDate
        }
        
    }
    
    var end:Date{
        get{
            workout.endDate
        }
    }
    var calorie:Double{
        get{
            workout.totalEnergyBurned!.doubleValue(for: .kilocalorie())
        }
    }
    
   
    

    
    init(_ workout:HKWorkout){
        self.workout = workout
        
    }
}
