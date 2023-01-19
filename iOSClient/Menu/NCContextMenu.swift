//
//  NCContextMenu.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 10/01/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import NextcloudKit

class NCContextMenu: NSObject {

    func viewMenu(ocId: String, viewController: UIViewController, image: UIImage?) -> UIMenu {

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else {
            return UIMenu()
        }

        var titleDeleteConfirmFile = NSLocalizedString("_delete_file_", comment: "")
        if metadata.directory { titleDeleteConfirmFile = NSLocalizedString("_delete_folder_", comment: "") }

        var titleSave: String = NSLocalizedString("_save_selected_files_", comment: "")
        let metadataMOV = NCManageDatabase.shared.getMetadataLivePhoto(metadata: metadata)
        if metadataMOV != nil {
            titleSave = NSLocalizedString("_livephoto_save_", comment: "")
        }

        let detail = UIAction(title: NSLocalizedString("_details_", comment: ""), image: UIImage(systemName: "info")) { _ in
            NCFunctionCenter.shared.openShare(viewController: viewController, metadata: metadata, indexPage: .activity)
        }

        let favorite = UIAction(title: metadata.favorite ? NSLocalizedString("_remove_favorites_", comment: "") : NSLocalizedString("_add_favorites_", comment: ""),
                                image: NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite)) { _ in
            NCNetworking.shared.favoriteMetadata(metadata) { error in
                if error != .success {
                    NCContentPresenter.shared.showError(error: error)
                }
            }
        }

        let openIn = UIAction(title: NSLocalizedString("_open_in_", comment: ""), image: UIImage(systemName: "square.and.arrow.up") ) { _ in
            NCFunctionCenter.shared.openDownload(metadata: metadata, selector: NCGlobal.shared.selectorOpenIn)
        }

        let viewInFolder = UIAction(title: NSLocalizedString("_view_in_folder_", comment: ""), image: UIImage(systemName: "arrow.forward.square")) { _ in
            NCFunctionCenter.shared.openFileViewInFolder(serverUrl: metadata.serverUrl, fileNameBlink: metadata.fileName, fileNameOpen: nil)
        }

        let save = UIAction(title: titleSave, image: UIImage(systemName: "square.and.arrow.down")) { _ in
            if metadataMOV != nil {
                NCFunctionCenter.shared.saveLivePhoto(metadata: metadata, metadataMOV: metadataMOV!)
            } else {
                if CCUtility.fileProviderStorageExists(metadata) {
                    NCFunctionCenter.shared.saveAlbum(metadata: metadata)
                } else {
                    NCOperationQueue.shared.download(metadata: metadata, selector: NCGlobal.shared.selectorSaveAlbum)
                }
            }
        }

        let copy = UIAction(title: NSLocalizedString("_copy_file_", comment: ""), image: UIImage(systemName: "doc.on.doc")) { _ in
            NCFunctionCenter.shared.copyPasteboard(pasteboardOcIds: [metadata.ocId], hudView: viewController.view)
        }

        let modify = UIAction(title: NSLocalizedString("_modify_", comment: ""), image: UIImage(systemName: "pencil.tip.crop.circle")) { _ in
            NCFunctionCenter.shared.openDownload(metadata: metadata, selector: NCGlobal.shared.selectorLoadFileQuickLook)
        }

        let deleteConfirmFile = UIAction(title: titleDeleteConfirmFile, image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            NCNetworking.shared.deleteMetadata(metadata, onlyLocalCache: false) { error in
                if error != .success {
                    NCContentPresenter.shared.showError(error: error)
                }
            }
        }
        let deleteConfirmLocal = UIAction(title: NSLocalizedString("_remove_local_file_", comment: ""), image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            NCNetworking.shared.deleteMetadata(metadata, onlyLocalCache: true) { _ in
            }
        }
        let deleteSubMenu = UIMenu(title: NSLocalizedString("_delete_file_", comment: ""), image: UIImage(systemName: "trash"), options: .destructive, children: [deleteConfirmLocal, deleteConfirmFile])

        // ------ MENU -----

        var menu: [UIMenuElement] = []

        if metadata.directory {

            let isDirectoryE2EE = NCUtility.shared.isDirectoryE2EE(metadata: metadata)
            if isDirectoryE2EE || metadata.e2eEncrypted {
                menu.append(favorite)
            } else {
                menu.append(favorite)
                menu.append(deleteConfirmFile)
            }
            return UIMenu(title: "", children: [detail, UIMenu(title: "", options: .displayInline, children: menu)])

        } else {

            if metadata.lock {
                menu.append(favorite)
                if metadata.sharePermissionsCollaborationServices == NCGlobal.shared.permissionViewOnly {
                    //
                } else {
                    menu.append(openIn)
                    menu.append(save)
                    menu.append(copy)
                }
            } else {
                menu.append(favorite)
                if (metadata.sharePermissionsCollaborationServices == NCGlobal.shared.permissionViewOnly) && (metadata.classFile == NKCommon.typeClassFile.document.rawValue) {
                    if viewController is NCMedia {
                        menu.append(viewInFolder)
                    }
                } else {
                    menu.append(openIn)
                    menu.append(save)
                    if viewController is NCMedia {
                        menu.append(viewInFolder)
                    }
                    menu.append(copy)
                    menu.append(modify)
                }
                if viewController is NCMedia {
                    menu.append(deleteConfirmFile)
                } else {
                    menu.append(deleteSubMenu)
                }
            }
            return UIMenu(title: "", children: [detail, UIMenu(title: "", options: .displayInline, children: menu)])
        }
    }
}
