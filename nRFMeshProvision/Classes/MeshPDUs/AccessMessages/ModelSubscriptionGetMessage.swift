//
//  ModelSubscriptionGetMessage.swift
//  nRFMeshProvision
//
//  Created by Jonas Nicklas on 2019-06-12.
//

import Foundation

public struct ConfigVendorModelSubscriptionGetMessage {
    var opcode  : Data
    var payload : Data
    
    public init(modelType: ModelType, withElementAddress anElementAddress: Data, andModelIdentifier aModelIdentifier: Data) {
        switch modelType {
            case .sig: opcode = Data([0x80, 0x29])
            case .vendor: opcode = Data([0x80, 0x2B])
        }
        payload = Data()
        payload.append(Data([anElementAddress[1], anElementAddress[0]]))
        
        switch modelType {
            case .sig:
                payload.append(Data([aModelIdentifier[1], aModelIdentifier[0]]))
            case .vendor:
                payload.append(Data([aModelIdentifier[1], aModelIdentifier[0],
                                     aModelIdentifier[3], aModelIdentifier[2]]))
        }
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, deviceKey: deviceKey!, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
