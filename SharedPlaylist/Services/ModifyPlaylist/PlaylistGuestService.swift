//
//  ModifyPlaylistGuestService.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation
import UIKit
import MultipeerConnectivity

final class PlaylistGuestService: NSObject {
    // MARK: - Public properties
    weak var delegate: ModifyPlaylistServiceDelegate?
    
    // MARK: - Private properties
    private let browserService: MultipeerBrowserService
    private let host: PlaylistHost
    private var addSongsCompletions = [Song: ((Bool) -> ())]()
    private var playlist: Playlist? {
        didSet {
            guard let playlist = playlist else { return }
            createNewSnapshot(from: playlist)
            completeAddSongCompletions(playlist: playlist)
        }
    }
    
    // MARK: - Init
    init(host: PlaylistHost, hostBrowser: PlaylistHostBrowser) {
        self.browserService = MultipeerBrowserService(
            serviceType: .newPlaylist,
            peerID: hostBrowser.peerID,
            browser: hostBrowser.browser
        )
        self.host = host
        super.init()
        self.browserService.sessionDelegate = self
    }
    
}

// MARK: - ModifyPlaylistService
extension PlaylistGuestService: ModifyPlaylistService {
    var canSavePlaylist: Bool { false }
    
    var dismissButtonTitle: String { "Leave" }
    
    
    func start() {
        browserService.invitePeer(host.id)
    }
    
    func addNewSong(_ song: Song, completion: @escaping (Bool) -> ()) {
        browserService.send(.addSong(song, atIndex: 0), to: [host.id])
        addSongsCompletions[song] = completion
        scheduleAddSongTimeout(song: song)
    }
    
    func removeSong(_ song: Song, completion: @escaping (Bool) -> ()) {
        // TODO
    }
    
    func isSongAlreadyAdded(_ song: Song) -> Bool {
        playlist?.songs.contains(song) ?? false
    }
    
    func savePlaylist() {
        print("Error: method savePlaylist() is not implemented in ModifyPlaylistGuestService. This class is not supposed to save playlist. Please check `canSavePlaylist` property before calling savePlaylist() method")
    }
    
    func dismissPlaylist() {
        browserService.disconnect()
    }
    
}

// MARK: - Private methods
private extension PlaylistGuestService {
    func handleReceived(_ data: MultipeerData, from peerID: MCPeerID) {
        switch data {
        case .playlist(let playlist):
            self.playlist = playlist
        case .addSong:
            break
        case .request:
            break
        case .none:
            break
        }
    }
    
    func createNewSnapshot(from playlist: Playlist) {
        var snapshot = NSDiffableDataSourceSnapshot<PlaylistSection, Song>()
        snapshot.appendSections([.songs])
        snapshot.appendItems(playlist.songs, toSection: .songs)
        delegate?.modifyPlaylistService(self, didChangeContentWith: snapshot)
    }
    
    func completeAddSongCompletions(playlist: Playlist) {
        for song in playlist.songs {
            guard let completion = addSongsCompletions.removeValue(forKey: song) else { continue }
            completion(true)
        }
    }
    
    func scheduleAddSongTimeout(song: Song) {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] (_) in
            guard let self = self,
                  let completion = self.addSongsCompletions.removeValue(forKey: song) else {
                return
            }
            completion(false)
        }
    }
    
}

// MARK: - MCSessionDelegate
extension PlaylistGuestService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            print("PlaylistGuestService - Not connected")
            DispatchQueue.main.async { [delegate] in
                delegate?.modifyPlaylistServiceDidEnd(self)
            }
        case .connecting:
            print("PlaylistGuestService - Connecting")
        case .connected:
            print("PlaylistGuestService - Connected")
            let requestPlaylist = MultipeerData.request(type: .initialPlaylist)
            do {
                let data = try JSONEncoder().encode(requestPlaylist)
                try session.send(data, toPeers: [host.id], with: .reliable)
            } catch {
                print("Error sending request to peers")
            }
            
        @unknown default:
            print("PlaylistGuestService - Unknown state")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let data = try JSONDecoder().decode(MultipeerData.self, from: data)
            DispatchQueue.main.async { [weak self] in
                self?.handleReceived(data, from: peerID)
            }
        } catch {
            print("Error decoding received data:", error)
        }
    }
    
    func session(_ session: MCSession,
                 didReceiveCertificate certificate: [Any]?,
                 fromPeer peerID: MCPeerID,
                 certificateHandler: @escaping (Bool) -> Void) {
        guard peerID == host.id else {
            print("Received certificate from different peer")
            certificateHandler(false)
            return
        }
        certificateHandler(true)
    }
    
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) { }
    
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) { }
    
}
