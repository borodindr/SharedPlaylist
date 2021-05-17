//
//  PlaylistHost.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation
import MultipeerConnectivity

struct PlaylistHost: Hashable, Identifiable {
    var id: MCPeerID { peerID }
    let name: String
    let playlistName: String?
    private let peerID: MCPeerID
    
    internal init(name: String, playlistName: String?, peerID: MCPeerID) {
        self.name = name
        self.playlistName = playlistName
        self.peerID = peerID
    }
    
}
