//
//  RootViewController.swift
//  LazyTableImagesInSwift
//
//  Created by 兎澤　佑　 on 2017/06/03.
//  Copyright © 2017年 tasuku tozawa. All rights reserved.
//

import Foundation
import UIKit

let kCustomRowcount = 7
let CellIdentifier = "LazyTableCell"
let PlaceholderCellIdentifier  = "PlaceholderCell"

class RootViewController: UITableViewController {
    var entries: [AppRecord] = []
    // the set of IconDownloader objects for each app
    private var imageDownloadsInProgress: Dictionary<IndexPath, IconDownloader> = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func terminateAllDownloads() {
        // terminate all pending download connections
        let allDownloads: NSArray = Array(self.imageDownloadsInProgress.values) as NSArray
        allDownloads.enumerateObjects({ (obj, idx, stop) in
            if let o = obj as? IconDownloader {
                o.cancelDownload()
            }
        })
        self.imageDownloadsInProgress.removeAll()
    }
    
    // -------------------------------------------------------------------------------
    //	dealloc
    //  If this view controller is going away, we need to cancel all outstanding downloads.
    // -------------------------------------------------------------------------------
    deinit {
        // terminate all pending download connections
        self.terminateAllDownloads()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // terminate all pending download connections
        self.terminateAllDownloads()
    }
    
    func startIconDownload(appRecord: AppRecord, forIndexPath: IndexPath) {
        var iconDownloader = self.imageDownloadsInProgress[forIndexPath]
        if iconDownloader == nil {
            iconDownloader = IconDownloader()
            iconDownloader?.appRecord = appRecord
            iconDownloader?.completionHandler = { () in
                let cell = self.tableView.cellForRow(at: forIndexPath)
                
                // Display the newly loaded image
                cell?.imageView?.image = appRecord.appIcon
                
                // Remove the IconDownloader from the in progress list.
                // This will result in it being deallocated.
                self.imageDownloadsInProgress.removeValue(forKey: forIndexPath)
            }
            self.imageDownloadsInProgress[forIndexPath] = iconDownloader
            iconDownloader?.startDownload()
        }
    }
    
    // -------------------------------------------------------------------------------
    //	loadImagesForOnscreenRows
    //  This method is used in case the user scrolled into a set of cells that don't
    //  have their app icons yet.
    // -------------------------------------------------------------------------------
    func loadImagesForOnscreenRows() {
        if self.entries.count > 0 {
            if let visiblePaths = self.tableView.indexPathsForVisibleRows {
                for indexPath in visiblePaths {
                    let appRecord = self.entries[indexPath.row]
                    if appRecord.appIcon == nil {
                        // Avoid the app icon download if the app already has an icon
                        self.startIconDownload(appRecord: appRecord, forIndexPath: indexPath)
                    }
                }
            }
        }
    }
}

// UITableViewDataSource
extension RootViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.entries.count
        // if there's no data yet, return enough rows to fill the screen
        if count == 0 { return kCustomRowcount }
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        
        let nodeCount = self.entries.count
        
        if nodeCount == 0 && indexPath.row == 0 {
            // add a placeholder cell while waiting on table data
            cell = tableView.dequeueReusableCell(withIdentifier: PlaceholderCellIdentifier, for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
            
            // Leave cells empty if there's no data yet
            if nodeCount > 0 {
                // Set up the cell representing the app
                let appRecord = self.entries[indexPath.row]
                cell?.textLabel!.text = appRecord.appName
                //cell?.detailTextLabel!.text = appRecord.artist
                
                // Only load cached images; defer new downloads until scrolling ends
                if let appIcon = appRecord.appIcon {
                    cell!.imageView!.image = appIcon
                } else {
                    if self.tableView.isDragging == false && self.tableView.isDecelerating == false {
                        self.startIconDownload(appRecord: appRecord, forIndexPath: indexPath)
                    }
                    // if a download is deferred or in progress, return a placeholder image
                    cell!.imageView!.image = UIImage(named: "Placeholder.png")
                }
            }
        }
        
        return cell!
    }
}

// UIScrollViewDelegate
extension RootViewController {
    
    // -------------------------------------------------------------------------------
    //	scrollViewDidEndDragging:willDecelerate:
    //  Load images for all onscreen rows when scrolling is finished.
    // -------------------------------------------------------------------------------
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.loadImagesForOnscreenRows()
        }
    }
    
    // -------------------------------------------------------------------------------
    //	scrollViewDidEndDecelerating:scrollView
    //  When scrolling stops, proceed to load the app icons that are on screen.
    // -------------------------------------------------------------------------------
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
    }
}
