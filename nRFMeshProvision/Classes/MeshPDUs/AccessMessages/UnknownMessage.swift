//
//  UnknownMessage.swift
//  nRFMeshProvision
//
//  Created by Jonas Nicklas on 2019-06-17.
//

import Foundation

public struct UnknownMessage {
    public var opcode: Data
    public var payload: Data
    public var sourceAddress: Data
    
    public init(withOpcode anOpcode: Data, andPayload aPayload: Data, andSourceAddress srcAddress: Data) {
        opcode = anOpcode
        payload = aPayload
        sourceAddress = srcAddress
    }
}
