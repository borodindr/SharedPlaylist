//
//  NewPlaylistViewController.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 22.02.2021.
//

import UIKit
import MultipeerConnectivity

final class NewPlaylistViewController: UIViewController {
    // MARK: - Views
    var tableView: UITableView {
        view as! UITableView
    }
    
    // MARK: - Private properties
    private lazy var dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) { (tv, indexPath, item) -> UITableViewCell? in
        
        switch item {
        case .newSession:
            let cell = tv.dequeueReusableCell(withIdentifier: "NewSession", for: indexPath)
            cell.textLabel?.text = "Create New Playlist"
            return cell
        case .joinSession(let host):
            let cell = tv.dequeueReusableCell(withIdentifier: "JoinSession", for: indexPath)
            cell.textLabel?.text = "Join to \(host.name)"
            cell.detailTextLabel?.text = host.playlistName
            return cell
        }
    }
    
    private let hostBrowser = PlaylistHostBrowser()
    
    // MARK: - Lifecycle
    override func loadView() {
        view = UITableView(frame: .zero, style: .insetGrouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "New Playlist"
        view.backgroundColor = .systemGroupedBackground
        prepareTableView()
        createInitialSnapshot()
        hostBrowser.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hostBrowser.startBrowsing()
    }
    
    // MARK: - Private methods
    private func prepareTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NewSession")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "JoinSession")
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.rowHeight = 120
    }
    
    private func createInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.host])
        snapshot.appendItems([.newSession], toSection: .host)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func askPlaylistNameToCreateNew() {
        let alert = UIAlertController(title: "New Playlist", message: "Enter name for the playlist", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Playlist Name"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text else { return }
            print("Name:", name)
            self?.hostBrowser.stopBrowsing()
            let vc = ModifyPlaylistViewController(modifyPlaylistType: .host(playlistName: name))
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        alert.addAction(createAction)
        
        present(alert, animated: true)
    }
    
}

// MARK: - UITableViewDelegate
extension NewPlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        switch item {
        case .newSession:
            askPlaylistNameToCreateNew()
        case .joinSession(let host):
            let vc = ModifyPlaylistViewController(
                modifyPlaylistType: .guest(host: host, hostBrowser: hostBrowser)
            )
            navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        switch section {
        case .host:
            return nil
        case .guest:
            let label = UILabel()
            label.font = .preferredFont(forTextStyle: .headline)
            label.text = "Available sessions"
            label.frame = CGRect(
                x: 4,
                y: 4,
                width: tableView.frame.width - 8,
                height: 44
            )
            return label
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = dataSource.snapshot().sectionIdentifiers[section]
        switch section {
        case .host:
            return 0
        case .guest:
            return 44
        }
    }
    
}

// MARK: - PlaylistHostBrowserDelegate
extension NewPlaylistViewController: PlaylistHostBrowserDelegate {
    func playlistHostBrowser(_ browser: PlaylistHostBrowser, didAdd host: PlaylistHost) {
        var snapshot = dataSource.snapshot()
        if !snapshot.sectionIdentifiers.contains(.guest) {
            snapshot.appendSections([.guest])
        }
        snapshot.appendItems([.joinSession(host: host)], toSection: .guest)
        dataSource.apply(snapshot)
    }
    
    func playlistHostBrowser(_ browser: PlaylistHostBrowser, didRemoveHostWith id: PlaylistHost.ID) {
        var snapshot = dataSource.snapshot()
        let hosts = snapshot.itemIdentifiers(inSection: .guest).hosts
        guard let host = hosts.first(where: { $0.id == id }) else { return }
        let item = Item.joinSession(host: host)
        snapshot.deleteItems([item])
        if snapshot.numberOfItems(inSection: .guest) == 0 {
            snapshot.deleteSections([.guest])
        }
        dataSource.apply(snapshot)
    }
    
}

extension NewPlaylistViewController {
    enum Section {
        case host, guest
    }
    
    enum Item: Hashable {
        case newSession
        case joinSession(host: PlaylistHost)
    }
    
}

extension Array where Element == NewPlaylistViewController.Item {
    var hosts: [PlaylistHost] {
        compactMap { item in
            switch item {
            case .newSession: return nil
            case .joinSession(let host): return host
            }
        }
    }
}
