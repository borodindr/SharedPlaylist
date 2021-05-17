//
//  MultipeerAdvertiserService.swift
//  PartySound
//
//  Created by Dmitry Borodin on 17.01.2021.
//

import Foundation
import MultipeerConnectivity

typealias MultipeerAdvertiserServiceDelegate = MCNearbyServiceAdvertiserDelegate & MCSessionDelegate

final class MultipeerAdvertiserService: NSObject {
    // MARK: - Public properties
    let peerID: MCPeerID
    let session: MCSession
    let advertiser: MCNearbyServiceAdvertiser
    var mcAdvertiserAssistant: MCAdvertiserAssistant?
    
    // MARK: - Init
    init(serviceType: MultipeerServiceType, discoveryInfo: [MultypeerServiceDiscoveryInfoKey: String]) {
        let name = UIDevice.current.name
        self.peerID = MCPeerID(displayName: name)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo.raw,
            serviceType: serviceType.rawValue
        )
        super.init()
        addAppWillTerminateHandler()
        
    }
    
    // MARK: - Public methods
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
    }
    
    func disconnect() {
        session.disconnect()
    }
    
    func send(_ data: MultipeerData) {
        let peers = session.connectedPeers
        print("Connected peers count:", peers.count)
        send(data, to: peers)
    }
    
    func send(_ data: MultipeerData, to peerIDs: [MCPeerID]) {
        do {
            let encoded = try JSONEncoder().encode(data)
            try session.send(encoded, toPeers: peerIDs, with: .reliable)
        } catch {
            print("Error encoding data:", error)
        }
    }
    
    func setDelegate(_ delegate: MultipeerAdvertiserServiceDelegate) {
        advertiser.delegate = delegate
        session.delegate = delegate
    }
    
    // MARK: - Private methods
    private func addAppWillTerminateHandler() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { [weak self] (_) in
            self?.disconnect()
            self?.stopAdvertising()
        }
    }
}




