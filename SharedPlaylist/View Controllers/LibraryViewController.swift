//
//  LibraryViewController.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 22.02.2021.
//

import UIKit
import CoreData

final class LibraryViewController: UIViewController {
    
    // MARK: - Views
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.text = "Create playlists to see them here"
        label.font = .preferredFont(forTextStyle: .title2)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Private properties
    private lazy var dataSource = EditableTableViewDiffableDataSource<String, NSManagedObjectID>(
        tableView: tableView
    ) { [weak self] (tv, indexPath, objectID) -> UITableViewCell? in
        let cell = tv.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as! PlaylistCell
        let playlist = self?.fetchedResultController.object(at: indexPath)
        cell.textLabel?.text = playlist?.name
        return cell
    }
    
    private lazy var fetchRequest: NSFetchRequest<PlaylistEntity> = {
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        let sortDescriptor = NSSortDescriptor(keyPath: \PlaylistEntity.dateCreated, ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.includesPendingChanges = false
        return fetchRequest
    }()
    
    private lazy var fetchedResultController = NSFetchedResultsController(
        fetchRequest: fetchRequest,
        managedObjectContext: context,
        sectionNameKeyPath: nil,
        cacheName: nil)
    
    private var context: NSManagedObjectContext {
        CoreDataStack.shared.viewContext
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Library"
        view.backgroundColor = .systemGroupedBackground
        prepareTableView()
        view.addSubview(hintLabel)
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
        } catch {
            print("Error fetching library:", error)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        let labelWidth = view.bounds.width - 32
        hintLabel.frame = CGRect(
            x: (view.bounds.width - labelWidth) / 2,
            y: view.safeAreaInsets.top + 24,
            width: labelWidth,
            height: 150
        )
    }
    
    // MARK: - Private methods
    private func prepareTableView() {
        view.addSubview(tableView)
        tableView.register(PlaylistCell.self, forCellReuseIdentifier: "PlaylistCell")
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.rowHeight = 80
    }
    
    private func setHintHiddenState(to isHidden: Bool) {
        hintLabel.isHidden = isHidden
    }
    
}

// MARK: - UITableViewDelegate
extension LibraryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] (action, view, completion) in
            guard let self = self else { return }
            let playlist = self.fetchedResultController.object(at: indexPath)
            self.context.delete(playlist)
            CoreDataStack.shared.saveContext()
        }
        action.backgroundColor = .systemRed
        action.image = UIImage(systemName: "trash")
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let playlist = fetchedResultController.object(at: indexPath)
        let songs = playlist.asPlaylist.songs
        let vc = PlaylistViewController(songs: songs)
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension LibraryViewController: NSFetchedResultsControllerDelegate {
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        let shouldShowHint = snapshot.numberOfItems == 0
        setHintHiddenState(to: !shouldShowHint)
        DispatchQueue.main.async { [weak self] in
            self?.dataSource.apply(snapshot)
        }
    }
    
}
