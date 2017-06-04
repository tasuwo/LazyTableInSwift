//
//  IconDownloader.swift
//  LazyTableImagesInSwift
//
//  Created by 兎澤　佑　 on 2017/06/04.
//  Copyright © 2017年 tasuku tozawa. All rights reserved.
//

import Foundation
import UIKit

let kAppIconSize: CGFloat = 48

class IconDownloader: NSObject {
    var appRecord: AppRecord!
    var completionHandler: (() -> Void)!
    
    private var sessionTask: URLSessionDataTask!
    
    func startDownload() {
        let request = URLRequest(url: URL(string: self.appRecord.imageURLString)!)
        
        // create an session data task to obtain and download the app icon
        self.sessionTask = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            
            // in case we want to know the response status code
            //NSInteger HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];

            if let e = error {
                // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                // then your Info.plist has not been properly configured to match the target server.
                //
                if (e as NSError).code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                    abort()
                }
            }
            
            OperationQueue.main.addOperation {
                
                // Set appIcon and clear temporary data/image
                if let data = data,
                   let image = UIImage(data: data) {
                    if image.size.width != kAppIconSize || image.size.height != kAppIconSize {
                        let itemSize = CGSize(width: kAppIconSize, height: kAppIconSize)
                        UIGraphicsBeginImageContextWithOptions(itemSize, false, 0.0)
                        let imageRect = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
                        image.draw(in: imageRect)
                        self.appRecord.appIcon = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                    } else {
                        self.appRecord.appIcon = image
                    }
                }
                
                // call our completion handler to tell our client that our icon is ready for display
                if let handler = self.completionHandler {
                    handler()
                }
            }
        })
        self.sessionTask.resume()
    }
    
    func cancelDownload() {
        self.sessionTask?.cancel()
        self.sessionTask = nil
    }
}
