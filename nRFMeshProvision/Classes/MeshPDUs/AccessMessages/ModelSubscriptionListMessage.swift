//
//  ModelSubscriptionListMessage.swift
//  nRFMeshProvision
//
//  Created by Jonas Nicklas on 2019-06-12.
//

import Foundation

public struct ModelSubscriptionListMessage {
    public var sourceAddress: Data
    public var statusCode: MessageStatusCodes
    public var elementAddress: Data
    public var modelIdentifier: Data
    public var addresses: [Data]
    
    public init(modelType: ModelType, withPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        if let aStatusCode = MessageStatusCodes(rawValue: aPayload[0]) {
            statusCode = aStatusCode
        } else {
            statusCode = .success
        }
        elementAddress      = Data([aPayload[2], aPayload[1]])
        switch modelType {
        case .sig:
            modelIdentifier = Data([aPayload[4], aPayload[3]])
        case .vendor:
            modelIdentifier = Data([
                aPayload[4], aPayload[3],
                aPayload[6], aPayload[5]
                ])
        }
        
        addresses = []
        
        let addressesStart: Int
        switch modelType {
        case .sig: addressesStart = 5
        case .vendor: addressesStart = 7
        }
        
        let numberOfAddresses = (aPayload.count - addressesStart) / 2
        
        for number in 0..<numberOfAddresses {
            let firstByte = (number * 2) + addressesStart
            addresses.append(Data([aPayload[firstByte + 1], aPayload[firstByte]]))
        }
    }
}
