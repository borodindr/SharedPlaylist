//
//  MultypeerServiceDiscoveryInfoKey.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation

enum MultypeerServiceDiscoveryInfoKey: String {
    case playlistName
}

extension Dictionary where Key == MultypeerServiceDiscoveryInfoKey, Value == String {
    var raw: [String: String] {
        var newDict = [String: String]()
        for (key, value) in self {
            newDict[key.rawValue] = value
        }
        return newDict
    }
}
