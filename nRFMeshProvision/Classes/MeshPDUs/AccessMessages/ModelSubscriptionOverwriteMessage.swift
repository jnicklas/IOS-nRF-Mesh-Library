//
//  ModelSubscriptionOverwriteMessage.swift
//  nRFMeshProvision
//
//  Created by Jonas Nicklas on 2019-06-12.
//

import Foundation

public struct ModelSubsriptionOverwriteMessage {
    var opcode  : Data
    var payload : Data
    
    public init(withElementAddress anElementAddress: Data,
                subscriptionAddress aSubscriptionAddress: Data,
                andModelIdentifier aModelIdentifier: Data) {
        
        opcode = Data([0x80, 0x1E])
        payload = Data()
        payload.append(Data([anElementAddress[1], anElementAddress[0]]))
        payload.append(Data([aSubscriptionAddress[1], aSubscriptionAddress[0]]))
        if aModelIdentifier.count == 2 {
            payload.append(Data([aModelIdentifier[1], aModelIdentifier[0]]))
        } else {
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
