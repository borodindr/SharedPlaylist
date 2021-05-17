//
//  EditableTableViewDiffableDataSource.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 02.03.2021.
//

import UIKit

class EditableTableViewDiffableDataSource<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>:
    UITableViewDiffableDataSource<SectionIdentifierType,ItemIdentifierType> {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
}
