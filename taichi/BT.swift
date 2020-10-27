//
//  BT.swift
//  For handle Bluetooth LE and iBeacon
//
//
//  Created by slee on 3/10/2020.
//  Copyright © 2020 sclee. All rights reserved.
//

import Foundation
import BlueSTSDK
import CoreLocation



//Delegate for new bluetooth data
protocol BTTaiChiDelegate {
    func didNewData(items:[TaichiType],start:[Date],end:[Date])
}


class BT: NSObject, BlueSTSDKManagerDelegate, ObservableObject,BlueSTSDKNodeStateDelegate, BlueSTSDKFeatureDelegate {

    @Published var connected_message = "UnConnect"
    
    let taichiDeviceID = 0x92
    
    var node: BlueSTSDKNode!
    private var taichiDelegate: BTTaiChiDelegate!
    var locationManager = CLLocationManager()
    
    
    func setTaiChiDelegate(delegate:BTTaiChiDelegate){
        taichiDelegate = delegate
    }
    
    // MARK: - BlueSTSDKFeatureDelegate
    
    func didUpdate(_ feature: BlueSTSDKFeature, sample: BlueSTSDKFeatureSample) {
        NSLog("TaiChi Recevied timestamp:%d, value:", sample.timestamp,sample.data[0].uint16Value)
        
  
 
        
        
        NSLog("end")
        
        guard taichiDelegate != nil else {
            return
        }
        
        var types:[TaichiType] = []
         var start:[Date] = []
         var end:[Date] = []
        let count = Int(sample.data[0].uint16Value)
        
        if count==0 {
            
            return
        }
        
        
    
        for i in 0...count-1 {
            NSLog("TaiChi t:%d, value:%f %f", sample.data[2+i*6].uint16Value,-(Double(sample.data[4+i*6].uint16Value)),-(Double(sample.data[6+i*6].uint16Value)))
            
            types.append(TaichiType(rawValue: Int(sample.data[2+i*6].uint16Value))!)
            start.append(Date(timeIntervalSinceNow: -(Double(sample.data[4+i*6].uint16Value))))
            end.append(Date(timeIntervalSinceNow: -(Double(sample.data[6+i*6].uint16Value))))
        }
        
        
        taichiDelegate.didNewData(items: types,start: start,end:end)
     }

    // MARK: - BlueSTSDKNodeStateDelegate
    func node(_ node: BlueSTSDKNode, didChange newState: BlueSTSDKNodeState, prevState: BlueSTSDKNodeState) {
        if newState == .connected {
            
            guard let feature = node.getFeatureOfType(BTFeatureTaiChi.self) else {
                return self.bTDisConnect()
            }
  
            self.node = node
            
            
            
            feature.add(self)
            feature.enableNotification()

             DispatchQueue.main.async {
                self.connected_message =  "\(node.friendlyName())\n(Connected)"
                
            }
        }

        
        if (prevState == .connected && (newState == .dead || newState == .lost)){
            bTConnect()
        }
        
     }
    
    //:MARK -
    
    func getTaiChiCharacteristics() -> [CBUUID:[AnyClass]]{
        var temp:[CBUUID:[AnyClass]]=[:]
        temp.updateValue([BTFeatureTaiChi.self],
                         forKey: CBUUID(string: "00000001-000d-11e1-ac36-0002a5d5c51b"))
        return temp;
    }
    
    //:MARK - BlueSTSDKManagerDelegate
    func manager(_ manager: BlueSTSDKManager, didDiscoverNode node: BlueSTSDKNode) {
        
        
        if (node.advertiseInfo.deviceId != taichiDeviceID){
            return
        }
        
        
        DispatchQueue.main.async {
            self.connected_message =  "\(node.friendlyName())\n(\(String(describing:  node.advertiseInfo.deviceId)))"
            
        }
        
        btManager.discoveryStop()
        

        
        node.addStatusDelegate(self)
        node.addExternalCharacteristics(getTaiChiCharacteristics())
        
        
        
        node.connect()
      

    }
    
    func manager(_ manager: BlueSTSDKManager, didChangeDiscovery: Bool) {
        
    }
    
    //:MARK -
    
    static var instant:BT = BT();
    
    private var btManager:BlueSTSDKManager!
    
    
    
    func startupBeacons() {
        
        if CLLocationManager.isMonitoringAvailable(for:
                      CLBeaconRegion.self) {
           
        
            
            self.locationManager.delegate = self
            self.locationManager.allowsBackgroundLocationUpdates = true
            self.locationManager.showsBackgroundLocationIndicator = true
            
            self.locationManager.activityType = .fitness
            
            
         
            
           
            
            var authStatus:CLAuthorizationStatus!;
            
            if #available(iOS 14.0, *) {
                authStatus = self.locationManager.authorizationStatus
            } else {
                authStatus = CLLocationManager.authorizationStatus()
            }
            
            if (authStatus == .none || authStatus == .some(.notDetermined)){
                self.locationManager.requestAlwaysAuthorization()
                return;
            }

            startLocation();
            
            
        }
    }
    
    
    private func startLocation(){
        
        // Match all beacons with the specified UUID
        let uuid = UUID(uuidString:
               "00020000-000D-11E1-AC36-0002A5D5C51B")
        
        
        
        let beaconID = "sclee.taichi"
            
        // Create the region and begin monitoring it.
        let region = CLBeaconRegion(uuid: uuid!,
               identifier: beaconID)
        
        region.notifyEntryStateOnDisplay = true;
        region.notifyOnExit = true;
        region.notifyOnEntry = true;
        
        var authStatus:CLAuthorizationStatus!;
        
        if #available(iOS 14.0, *) {
            authStatus = self.locationManager.authorizationStatus
        } else {
            authStatus = CLLocationManager.authorizationStatus()
        }
        
        if (authStatus == .some(.authorizedAlways)){
            
           
            self.locationManager.startMonitoring(for: region)

          //  self.locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
            
          //  self.locationManager.startUpdatingLocation()
            
          //  self.locationManager.startMonitoringVisits()
            
            
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.requestAuthorization(options: [ .badge, .provisional]) { granted, error in
                
                if let error = error {
                    print("request notification authrization error: \(error.localizedDescription)")
                }
                
               
            }

            
        }else{
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.stopMonitoring(for: region)
        }
        
        
        
    }
    
    
    private override init(){
        super.init()
        
    
        
        startupBeacons();
        
        
    }
    
    static func getInstant()->BT{
           return instant
       }
    
    

    func bTConnect(){
        btManager = BlueSTSDKManager.sharedInstance
        btManager.addDelegate(self)
  
        
        if (btManager.isDiscovering){
            btManager.discoveryStop()
        }else{
            btManager.resetDiscovery()
            btManager.discoveryStart()
        }
        
    }
    
    
    func bTDisConnect(){
         if (btManager.isDiscovering){
                   btManager.discoveryStop()
               }
        
        if (node != nil && node.isConnected()) {
            node.disconnect()
        }  
        
    }
    
}

extension BT:CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        if beacons.count>0 {
            print("didRange\(beaconConstraint.uuid.uuidString): \(beacons[0].proximity.rawValue) RSSI:\(beacons[0].rssi)")
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
       // NSLog("Location Manager ")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        NSLog("Location Manager Enter")
        
     
       
        
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            guard (settings.authorizationStatus == .authorized) ||
                  (settings.authorizationStatus == .provisional) else { return }
            
            
       
                let pushContent = UNMutableNotificationContent()
                pushContent.title = "New TaiChi event is waiting"
                pushContent.body = "Click to open the APP to receive that"
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: pushContent, trigger: nil)
                UNUserNotificationCenter.current().add(request) { (error) in
                    if error != nil {
                        print("error push notification")
                    }
                }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NSLog("Location Manager Exit")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       // monitorBeacons()
        startLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        NSLog("Location Manager did Vist")
    
    }
    
}




