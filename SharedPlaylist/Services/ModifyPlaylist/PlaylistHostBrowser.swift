//
//  GuestPlaylistModifier.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 26.02.2021.
//

import Foundation
import MultipeerConnectivity

final class PlaylistHostBrowser: NSObject {
    weak var delegate: PlaylistHostBrowserDelegate?
    
    let peerID: MCPeerID
    let browser: MCNearbyServiceBrowser
    
    override init() {
        let name = UIDevice.current.name
        self.peerID = MCPeerID(displayName: name)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: MultipeerServiceType.newPlaylist.rawValue)
        super.init()
        browser.delegate = self
    }
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
    }
    
}

extension PlaylistHostBrowser: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        let playlistName = info?[MultypeerServiceDiscoveryInfoKey.playlistName.rawValue]
        let host = PlaylistHost(name: peerID.displayName,
                                playlistName: playlistName,
                                peerID: peerID)
        delegate?.playlistHostBrowser(self, didAdd: host)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        delegate?.playlistHostBrowser(self, didRemoveHostWith: peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) { }
    
}
