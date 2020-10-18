//
//  TaiChiListView.swift
//  taichi
//
//  Created by slee on 30/9/2020.
//  Copyright © 2020 sclee. All rights reserved.
//

import SwiftUI

struct TaiChiListView: View {
  @ObservedObject var health = Health.getInstant()
    @ObservedObject var bt = BT.getInstant()
          
    let newTap = TapGesture().onEnded{
            _ in
            Health.getInstant().add(.updown,Date(),Date())
        }
    
    var body: some View {
        VStack{
        List(health.getItems()) { item in
            TaiChiRowView(taiChi: item)
        }
           
            #if DEBUG
            Text(bt.connected_message).gesture(newTap).font(.callout)
            #endif
        }
    }
}

struct TaiChiListView_Previews: PreviewProvider {
    static var previews: some View {
        
        TaiChiListView()
    }
}


