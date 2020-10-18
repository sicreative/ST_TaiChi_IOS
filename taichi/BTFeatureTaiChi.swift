//
//  BTFeatureTaiChi.swift
//  taichi
//
//  Created by slee on 4/10/2020.
//  Copyright © 2020 sclee. All rights reserved.
//


import BlueSTSDK


public class BTFeatureTaiChi : BlueSTSDKFeature{
    private static let MAX_TAICHI_RECORD = 3
    private static let N_REGISTER_NUMBER = 2+6*4
    private static let FEATURE_NAME = "Tai Chi Device";
    private static let FIELDS:[BlueSTSDKFeatureField] =  (0..<N_REGISTER_NUMBER).map{ i in
        BlueSTSDKFeatureField(name: "Register_\(i)", unit: nil, type: .uInt8,
        min: NSNumber(value: 0), max: NSNumber(value:UInt8.max))
    }
    
    public override func getFieldsDesc() -> [BlueSTSDKFeatureField] {
        return BTFeatureTaiChi.FIELDS;
    }
    
    public override init(whitNode node: BlueSTSDKNode) {
        super.init(whitNode: node, name: BTFeatureTaiChi.FEATURE_NAME)
    }
    
    public static func getRegisterStatus( _ sample:BlueSTSDKFeatureSample) -> [UInt8] {
        return sample.data.map{ $0.uint8Value }
    }
    
    public static func getRegisterStatus( _ sample:BlueSTSDKFeatureSample, index:Int) -> UInt8?{
        guard sample.data.count > index else{
            return nil
        }
        return sample.data[index].uint8Value
    }
    
    public override func extractData(_ timestamp: UInt64, data: Data,
                                     dataOffset offset: UInt32) -> BlueSTSDKExtractResult {
        let intOffset = Int(offset)
        
        if((data.count-intOffset) < Self.N_REGISTER_NUMBER){
            NSException(name: NSExceptionName(rawValue: "Invalid data"),
                        reason: "There are no \(Self.N_REGISTER_NUMBER) bytes available to read",
                        userInfo: nil).raise()
            return BlueSTSDKExtractResult(whitSample: nil, nReadData: 0)
        }
        
        let status = (intOffset..<(intOffset+Self.N_REGISTER_NUMBER)).map{
            NSNumber(value: data[$0])
        }
        
        let sample = BlueSTSDKFeatureSample(timestamp: timestamp, data: status)
        
        return BlueSTSDKExtractResult(whitSample: sample, nReadData: UInt32(Self.N_REGISTER_NUMBER))
    }
    
}
