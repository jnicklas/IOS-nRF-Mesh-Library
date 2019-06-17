//
//  AccessMessageParser.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 04/04/2018.
//

import Foundation

public struct AccessMessageParser {
    public func parseData(_ someData: Data, withOpcode anOpcode: Data, sourceAddress aSourceAddress: Data) -> Any? {
        switch anOpcode {
            //Configuration Messages
        case Data([0x02]):
            return CompositionStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x03]):
            return AppKeyStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x3E]):
            return ModelAppStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x19]):
            return ModelPublicationStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x1F]):
            return ModelSubscriptionStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x0E]):
            return DefaultTTLStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x4A]):
            return NodeResetStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            //Generic Model Messages
        case Data([0x82, 0x04]):
            return GenericOnOffStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x82, 0x08]):
            return GenericLevelStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x2A]):
            return ModelSubscriptionListMessage(modelType: .sig, withPayload: someData, andSourceAddress: aSourceAddress)
        case Data([0x80, 0x2C]):
            return ModelSubscriptionListMessage(modelType: .vendor, withPayload: someData, andSourceAddress: aSourceAddress)
        default:
            return UnknownMessage(withOpcode: anOpcode, andPayload: someData, andSourceAddress: aSourceAddress)
        }
    }
}
