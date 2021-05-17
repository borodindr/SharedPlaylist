//
//  MultipeerBrowserService.swift
//  PartySound
//
//  Created by Dmitry Borodin on 17.01.2021.
//

import Foundation
import MultipeerConnectivity

typealias MultipeerBrowserServiceDelegate = MCNearbyServiceBrowserDelegate & MCSessionDelegate

final class MultipeerBrowserService: NSObject {
    // MARK: - Public properties
    var browserDelegate: MCNearbyServiceBrowserDelegate? {
        get { browser.delegate }
        set { browser.delegate = newValue }
    }
    
    var sessionDelegate: MCSessionDelegate? {
        get { session.delegate }
        set { session.delegate = newValue }
    }
    
    func setDelegate(_ delegate: MultipeerBrowserServiceDelegate) {
        browser.delegate = delegate
        session.delegate = delegate
    }
    
    // MARK: - Private properties
    private let peerID: MCPeerID
    private let session: MCSession
    private let browser: MCNearbyServiceBrowser
    
    // MARK: - Init
    init(serviceType: MultipeerServiceType, peerID: MCPeerID, browser: MCNearbyServiceBrowser) {
        self.peerID = peerID
        self.browser = browser
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        addAppWillTerminateHandler()
    }
    
    convenience init(serviceType: MultipeerServiceType) {
        let name = UIDevice.current.name
        let peerID = MCPeerID(displayName: name)
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType.rawValue)
        self.init(serviceType: serviceType, peerID: peerID, browser: browser)
        addAppWillTerminateHandler()
    }
    
    // MARK: - Public methods
    func startBrowsing() {
        browser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
    }
    
    func disconnect() {
        session.disconnect()
    }
    
    func invitePeer(_ peerID: MCPeerID) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 5)
    }
    
    func send(_ data: MultipeerData) {
        let peers = session.connectedPeers
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
    
    // MARK: - Private methods
    private func addAppWillTerminateHandler() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { [weak self] (_) in
            self?.disconnect()
            self?.stopBrowsing()
        }
    }
    
}


