//
//  UpperTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 27/02/2018.
//

import Foundation

public struct UpperTransportLayer {
    var stateManager                : MeshStateManager?
    let params                      : UpperTransportPDUParams
    let sslHelper                   : OpenSSLHelper
    private var encryptedPayload    : Data?
    private var decryptedPayload    : Data?

    public init(withIncomingPDU aPDU: Data, ctl isControl: Bool, akf isApplicationKey: Bool,
                aid applicationId: Data, seq aSEQ: Data, src aSRC: Data, dst aDST: Data,
                szMIC: Int, ivIndex anIVIndex: Data, andMeshState aStateManager: MeshStateManager) {
        stateManager = aStateManager
        sslHelper = OpenSSLHelper()
        var key: Data!
        var nonce: TransportNonce!
        
        if isApplicationKey {
            key = stateManager!.state().appKeys[0].values.first!
            nonce = TransportNonce(appNonceWithIVIndex: anIVIndex, isSegmented: true, seq: aSEQ, src: aSRC, dst: aDST)
        } else {
            key = stateManager!.state().deviceKeyForUnicast(aSRC)
            nonce = TransportNonce(deviceNonceWithIVIndex: anIVIndex, isSegmented: true, szMIC: UInt8(szMIC), seq: aSEQ, src: aSRC, dst: aDST)
        }

        if isControl {
            // Control messages aren't encrypted here, forward as is
            print("Control message, TBD")
            let strippedDSTPDU = Data(aPDU[2..<aPDU.count])
            let opcode = Data([aPDU[2]])
            params = UpperTransportPDUParams(withPayload: strippedDSTPDU, opcode: opcode, IVIndex: anIVIndex, key: key, ttl: Data([0x04]), seq: SequenceNumber(), src: aSRC, dst: aDST, nonce: nonce, ctl: isControl, afk: isApplicationKey, aid: applicationId)
        } else {
            let micLen = szMIC == 1 ? 8 : 4
            let dataSize = aPDU.count - micLen
            let pduData = aPDU[0..<dataSize]
            let mic = aPDU[aPDU.count - micLen..<aPDU.count]
            if let decryptedData = sslHelper.calculateDecryptedCCM(pduData, withKey: key, nonce: nonce.data, dataSize: 0, andMIC: mic) {
                decryptedPayload = Data(decryptedData)
            } else {
                print("Decryption failed")
            }
            var opcode = Data()
            if let payload = decryptedPayload {
                if payload.count > 0 {
                    if((payload[0] & 0x80) == 0) {
                        opcode.append(payload[0])
                    } else if((payload[0] & 0xC0) == 0x80) {
                        opcode.append(payload[0...1])
                    } else if((payload[0] & 0xC0) == 0xC0) {
                        opcode.append(payload[0...2])
                    }
                    params = UpperTransportPDUParams(withPayload: payload, opcode: opcode, IVIndex: anIVIndex, key: key, ttl: Data([0x04]), seq: SequenceNumber(), src: aSRC, dst: aDST, nonce: nonce, ctl: isControl, afk: isApplicationKey, aid: applicationId)
                } else {
                    //No payload, failed to decrypt
                    print("decryption failure, or no payload")
                    params = UpperTransportPDUParams(withPayload: Data(), opcode: Data(), IVIndex: anIVIndex, key: key, ttl: Data([0x04]), seq: SequenceNumber(), src: aSRC, dst: aDST, nonce: nonce, ctl: isControl, afk: isApplicationKey, aid: applicationId)
                }
            } else {
                //no payload, failed to decrypt
                print("decryption failure, or no payload")
                params = UpperTransportPDUParams(withPayload: Data(), opcode: Data(), IVIndex: anIVIndex, key: key, ttl: Data([0x04]), seq: SequenceNumber(), src: aSRC, dst: aDST, nonce: nonce, ctl: isControl, afk: isApplicationKey, aid: applicationId)
            }
        }
    }

    public init(withParams someParams: UpperTransportPDUParams) {
        params = someParams
        sslHelper = OpenSSLHelper()
    }

    public func assembleMessage() -> Any? {
        if params.ctl {
            //Assemble control message
            print("Assemble control message 0x\(params.opcode.hexString()), 0x\(params.payload.hexString())")
            return nil
        } else {
            //Assemble access message
            print("Assembling access message")
            print("opcode: 0x\(params.opcode.hexString())")
            let messageParser = AccessMessageParser()
            let payload = Data(decryptedPayload!.dropFirst(params.opcode.count))
            return messageParser.parseData(payload, withOpcode: params.opcode, sourceAddress: params.sourceAddress)
        }
    }

    public func decrypted() -> Data? {
        return decryptedPayload
    }
    public func rawData() -> Data? {
        return params.payload
    }

    public func encrypt() -> Data? {
        if let addressType = MeshAddressTypes(rawValue: params.destinationAddress) {
            switch addressType {
                case .Unicast, .Group, .Broadcast:
                    if params.nonce.type == .Device {
                        return encryptForDevice()
                    } else {
                        return encryptForUnicastOrGroupAddress()
                    }
            case .Virtual:
                return encryptForVirtualAddress()
            default:
                return nil
            }
        } else {
            return nil
        }
   }

    // MARK: - Encryption
    private func encryptForVirtualAddress() -> Data {
        //EncAccessPayload, TransMIC = AES-CCM (AppKey, Application Nonce, AccessPayload, Label UUID)
        return Data()
    }
   
    private func encryptForUnicastOrGroupAddress() -> Data {
        //EncAccessPayload, TransMIC = AES-CCM (AppKey, Application Nonce, AccessPayload)
        return sslHelper.calculateCCM(params.payload, withKey: params.key, nonce: params.nonce.data, dataSize: UInt8(params.payload.count), andMICSize: 4)
    }
   
    private func encryptForDevice() -> Data {
        //EncAccessPayload, TransMIC = AES-CCM (DevKey, Device Nonce, AccessPayload)
        return sslHelper.calculateCCM(params.payload, withKey: params.key, nonce: params.nonce.data, dataSize: UInt8(params.payload.count), andMICSize: 4)
    }
}
