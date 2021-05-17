//
//  ModifyPlaylistHostService.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation
import CoreData
import UIKit
import MultipeerConnectivity

final class PlaylistHostService: NSObject {
    // MARK: - Public properties
    weak var delegate: ModifyPlaylistServiceDelegate?
    
    // MARK: - Private properties
    private let advertiserService: MultipeerAdvertiserService
    private let draftContext = CoreDataStack.shared.newChildContext()
    private var playlist: PlaylistEntity
    private lazy var fetchedResultsController: NSFetchedResultsController<SongEntity> = {
        let fetchRequest: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "playlist.id == %@", playlist.id! as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SongEntity.indexInPlaylist, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: draftContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    // MARK: - Init
    init(playlistName: String) {
        playlist = PlaylistEntity(name: playlistName, insertInto: draftContext)
        advertiserService = MultipeerAdvertiserService(
            serviceType: .newPlaylist,
            discoveryInfo: [
                .playlistName: playlist.name ?? "Unknown playlist"
            ]
        )
        super.init()
        advertiserService.setDelegate(self)
    }
    
}

// MARK: - ModifyPlaylistService
extension PlaylistHostService: ModifyPlaylistService {
    var canSavePlaylist: Bool { true }
    var dismissButtonTitle: String { "Discard" }
    
    func start() {
        do {
            try draftContext.save()
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching songs:", error)
        }
        advertiserService.startAdvertising()
    }
    
    
    func addNewSong(_ song: Song, completion: @escaping (Bool) -> ()) {
        saveSong(song, completion: completion)
    }
    
    func removeSong(_ song: Song, completion: @escaping (Bool) -> ()) {
        let songEntities = playlist.songs as! Set<SongEntity>
        guard let songEntity = songEntities.first(where: { $0.trackId == song.trackId }) else {
            print("Oops")
            return
        }
        draftContext.delete(songEntity)
        playlist.updateSongIndices()
        do {
            try draftContext.save()
            completion(true)
            updateGuestPlaylist()
        } catch {
            print("Error saving song:", error)
            completion(false)
        }
    }
    
    func isSongAlreadyAdded(_ song: Song) -> Bool {
        fetchedResultsController.fetchedObjects?.contains { $0.trackId == song.trackId } ?? false
    }
    
    func savePlaylist() {
        CoreDataStack.shared.saveContext()
        delegate?.modifyPlaylistServiceDidEnd(self)
    }
    
    func dismissPlaylist() {
        advertiserService.disconnect()
        advertiserService.stopAdvertising()
        CoreDataStack.shared.viewContext.rollback()
        delegate?.modifyPlaylistServiceDidEnd(self)
    }
    
}

// MARK: - Private methods
private extension PlaylistHostService {
    private func handleReceived(_ data: MultipeerData, from peerID: MCPeerID) {
        switch data {
        case .request(let type):
            switch type {
            case .initialPlaylist:
                let playlist = self.playlist.asPlaylist
                let data = MultipeerData.playlist(playlist)
                advertiserService.send(data, to: [peerID])
            }
        case .addSong(let song, _):
            saveSong(song) { _ in }
        case .playlist, .none:
            break
        }
    }
    
    private func saveSong(_ song: Song, completion: @escaping (Bool) -> ()) {
        let entity = SongEntity.entity()
        let songEntity = SongEntity(entity: entity, insertInto: draftContext)
        songEntity.trackId = Int64(song.trackId)
        songEntity.trackName = song.trackName
        songEntity.artistId = Int64(song.artistId)
        songEntity.artistName = song.artistName
        songEntity.artworkURL = song.artworkURL
        songEntity.playlist = playlist
        let index = fetchedResultsController.sections?[0].numberOfObjects ?? 0
        songEntity.indexInPlaylist = Int16(index)
        
        do {
            try draftContext.save()
            completion(true)
            updateGuestPlaylist()
        } catch {
            print("Error saving song:", error)
            completion(false)
        }
    }
    
    private func updateGuestPlaylist() {
        let playlist = self.playlist.asPlaylist
        let data = MultipeerData.playlist(playlist)
        advertiserService.send(data)
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension PlaylistHostService: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        guard let sectionIdentifier = snapshot.sectionIdentifiers.first else { return }
        let songs = snapshot.itemIdentifiers(inSection: sectionIdentifier)
            .compactMap { snapshot.indexOfItem($0) } // get indices of IDs
            .map { IndexPath(row: $0, section: 0) } // convert indices to index paths
            .map { fetchedResultsController.object(at: $0) } // get objects by its index paths
            .compactMap { $0.asSong }
        
        var targetSnapshot = NSDiffableDataSourceSnapshot<PlaylistSection, Song>()
        targetSnapshot.appendSections([.songs])
        targetSnapshot.appendItems(songs, toSection: .songs)
        
        delegate?.modifyPlaylistService(self, didChangeContentWith: targetSnapshot)
    }
    
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension PlaylistHostService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let canAccept = advertiserService.session.connectedPeers.count < 7
        invitationHandler(canAccept, advertiserService.session)
    }
    
    
}

// MARK: - MCSessionDelegate
extension PlaylistHostService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            print("Not connected")
        case .connecting:
            print("Connecting")
        case .connected:
            print("Connected")
        @unknown default:
            print("Unknown state")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let data = try JSONDecoder().decode(MultipeerData.self, from: data)
            handleReceived(data, from: peerID)
        } catch {
            print("Error decoding received data:", error)
        }
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
    
    func session(_ session: MCSession,
                 didReceiveCertificate certificate: [Any]?,
                 fromPeer peerID: MCPeerID,
                 certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
}
