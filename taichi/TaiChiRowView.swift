//
//  TaiChiRowView.swift
//  taichi
//
//  Created by slee on 30/9/2020.
//  Copyright © 2020 sclee. All rights reserved.
//

import SwiftUI
import HealthKit


struct TaiChiRowView: View {
    
 @ObservedObject var taiChi: TaiChiItem
    var body: some View {
        
        let tap = TapGesture().onEnded{
            _ in
            Health.getInstant().delete(workout: self.taiChi.workout)
        }
        
        let dateformatter = DateFormatter()
        dateformatter.dateStyle = .short
        dateformatter.timeStyle = .medium
        
        return HStack {
            taiChi.type.getImage.resizable().scaledToFit().frame(width: 50.0, height: 50.0)
            //Text(String(taiChi.type.description))
            Text(dateformatter.string(from:taiChi.start))
            Text(dateformatter.string(from:taiChi.end))
            Text(String(taiChi.calorie))
            Spacer()
        }.gesture(tap)
        
        
    }
    
    
}

struct TaiChiRowView_Previews: PreviewProvider {
    static var previews: some View {
        
        
        let metadata = [HKMetadataKeyIndoorWorkout:false,"taichiType":TaichiType.flow.rawValue] as [String : Any]
             let start = Date.init()
             let end = start;
        let dur:TimeInterval = 200;
             let calorie:Double = 222;
             
             
            
              
             let energyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calorie)
             
             let taichi = HKWorkout(activityType: .mindAndBody,
                                  start: start, end: end, duration: dur,
                                  totalEnergyBurned: energyBurned,totalDistance: nil,  metadata: metadata)
        
        Health.getInstant().taiChiItems.append(TaiChiItem(taichi))
        
        
        return Group{
            
            
            
            TaiChiRowView(taiChi: Health.getInstant().taiChiItems[0])
      
        }
        .previewLayout(.fixed(width: 300, height: 100))
    }
}
