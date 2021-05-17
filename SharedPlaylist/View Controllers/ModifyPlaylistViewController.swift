//
//  ModifyPlaylistViewController.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 22.02.2021.
//

import UIKit
import CoreData

class ModifyPlaylistViewController: UIViewController {
    var tableView: UITableView {
        view as! UITableView
    }
    
    lazy var dataSource = EditableTableViewDiffableDataSource<PlaylistSection, Song>(tableView: tableView) { (tv, indexPath, song) -> UITableViewCell? in
        let cell = tv.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell
        cell.trackNameLabel.text = song.trackName
        cell.artistNameLabel.text = song.artistName
        let artwork: UIImage?
        cell.artworkImageView.sd_setImage(with: song.artworkURL,
                                          placeholderImage: UIImage(systemName: "music.quarternote.3"))
        return cell
    }
    
    var searchController: UISearchController!
    var searchResultsController: SearchSongsViewController!
    private let modifyPlaylistService: ModifyPlaylistService
    
    init(modifyPlaylistType type: ModifyPlaylistType) {
        modifyPlaylistService = type.service
        super.init(nibName: nil, bundle: nil)
        modifyPlaylistService.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UITableView(frame: .zero, style: .insetGrouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
        prepareSearchController()
        prepareTableView()
        addLeftBarButtonItem()
        addSavePlaylistBarButtonItemIfNeeded()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        modifyPlaylistService.start()
        DispatchQueue.main.async { [weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    private func prepareSearchController() {
        searchResultsController = SearchSongsViewController()
        searchResultsController.delegate = self
        
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func prepareTableView() {
        tableView.register(SongCell.self, forCellReuseIdentifier: "SongCell")
        tableView.dataSource = dataSource
//        tableView.dragInteractionEnabled = true
//        tableView.dragDelegate = self
//        tableView.dropDelegate = self
        tableView.delegate = self
        tableView.rowHeight = 80
    }
    
    private func addLeftBarButtonItem() {
        let barButtonItem = UIBarButtonItem(
            title: modifyPlaylistService.dismissButtonTitle,
            style: .plain,
            target: self,
            action: #selector(leftBarButtonItemTapped)
        )
        navigationItem.leftBarButtonItem = barButtonItem
    }
    
    private func addSavePlaylistBarButtonItemIfNeeded() {
        guard modifyPlaylistService.canSavePlaylist else { return }
        let barButtonItem = UIBarButtonItem(
            title: "SavePlaylist",
            style: .plain,
            target: self,
            action: #selector(savePlaylistTapped)
        )
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    // MARK: - Actions
    
    @objc
    private func leftBarButtonItemTapped(_ sender: UIBarButtonItem) {
        modifyPlaylistService.dismissPlaylist()
    }
    
    @objc
    private func savePlaylistTapped(_ sender: UIBarButtonItem) {
        modifyPlaylistService.savePlaylist()
    }
    
}

extension ModifyPlaylistViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        searchResultsController.searchSongs(query: query)
    }
    
    
}

extension ModifyPlaylistViewController: SearchSongsViewControllerDelegate {
    func searchSongsViewController(_ searchSongsViewController: SearchSongsViewController,
                                   isSongAlreadyAdded song: Song) -> Bool {
        modifyPlaylistService.isSongAlreadyAdded(song)
    }
    
    func searchSongsViewController(_ searchSongsViewController: SearchSongsViewController,
                                   didAddSong song: Song,
                                   completion: @escaping (Bool) -> ()) {
        modifyPlaylistService.addNewSong(song, completion: completion)
    }
    
}

extension ModifyPlaylistViewController: ModifyPlaylistServiceDelegate {
    func modifyPlaylistService(_ modifyPlaylistService: ModifyPlaylistService,
                               didChangeContentWith snapshot: NSDiffableDataSourceSnapshot<PlaylistSection, Song>) {
        self.dataSource.apply(snapshot)
        searchResultsController.reload()
    }
    
    func modifyPlaylistServiceDidEnd(_ modifyPlaylistService: ModifyPlaylistService) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension ModifyPlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let song = self?.dataSource.itemIdentifier(for: indexPath) else { return }
            self?.modifyPlaylistService.removeSong(song, completion: completion)
        }
        action.backgroundColor = .systemRed
        action.image = UIImage(systemName: "trash")
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
    
}

//extension ModifyPlaylistViewController: UITableViewDragDelegate {
//    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
//        let itemProvider = NSItemProvider(
//        UIDragItem(itemProvider: <#T##NSItemProvider#>)
//    }
//
//}
//
//extension ModifyPlaylistViewController: UITableViewDropDelegate {
//    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
//        <#code#>
//    }
//
//}
