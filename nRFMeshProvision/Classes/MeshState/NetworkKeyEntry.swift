//
//  NetworkKeyEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 05/12/2018.
//

import Foundation

public class NetworkKeyEntry: Codable {
    public var name         : String
    public var index        : Int
    public var key          : Data
    public var phase        : Int
    public var minSecurity  : Int
    public var timestamp    : Data
}
