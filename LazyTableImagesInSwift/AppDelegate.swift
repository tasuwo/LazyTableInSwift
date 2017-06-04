//
//  AppDelegate.swift
//  LazyTableImagesInSwift
//
//  Created by 兎澤　佑　 on 2017/06/03.
//  Copyright © 2017年 tasuku tozawa. All rights reserved.
//

import UIKit

// the http URL used for fetching the top iOS paid apps on the App Store
let TopPaidAppsFeed = "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/xml"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    // the queue to run our "ParseOperation"
    var queue: OperationQueue?
    // the NSOperation driving the parsing of the RSS feed
    var parser: ParseOperation?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let request = URLRequest(url: URL(string: TopPaidAppsFeed)!)
        
        // create an session data task to obtain and the XML feed
        let sessionTask = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            OperationQueue.main.addOperation {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                // in case we want to know the response status code
                //NSInteger HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
                
                if let error = error {
                    OperationQueue.main.addOperation {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        if (error as NSError).code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                            // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                            // then your Info.plist has not been properly configured to match the target server.
                            //
                            abort();
                        } else {
                            self.handleError(error: error)
                        }
                    }
                    return
                }
                
                // ParseOperation のためのキュー
                self.queue = OperationQueue()
                // UI がブロックされないように、NSOperation のサブクラスである ParseOperation を生成する
                self.parser = ParseOperation(data: data!)
                
                weak var weakSelf = self
                
                self.parser!.errorHandler = { (error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        weakSelf?.handleError(error: error)
                    }
                }
                
                // referencing parser from within its completionBlock would create a retain cycle
                weak var weakParser = self.parser
                
                self.parser!.completionBlock = {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if let list = weakParser!.appRecordList {
                        // The completion block may execute on any thread.  Because operations
                        // involving the UI are about to be performed, make sure they execute on the main thread.
                        //
                        DispatchQueue.main.async {
                            // The root rootViewController is the only child of the navigation
                            // controller, which is the window's rootViewController.
                            //
                            let rootViewController = (weakSelf!.window!.rootViewController as! UINavigationController).topViewController as! RootViewController
                            rootViewController.entries = list
                            
                            // tell our table view to reload its data, now that parsing has completed
                            rootViewController.tableView.reloadData()
                        }
                    }
                    // we are finished with the queue and our ParseOperation
                    weakSelf!.queue = nil
                }
                self.queue!.addOperation(self.parser!)
            }
        })
        
        sessionTask.resume()
        
        // show in the status bar that network activity is starting
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        return true
    }
    
    // -------------------------------------------------------------------------------
    //	handleError:error
    //  Reports any error with an alert which was received from connection or loading failures.
    // -------------------------------------------------------------------------------
    func handleError(error: Error) {
        let errorMessage = error.localizedDescription
        
        // alert user that our current record was deleted, and then we leave this view controller
        //
        let alert = UIAlertController(title: "Cannot show top paied apps", message: errorMessage, preferredStyle: .actionSheet)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: {(action) in})
        
        alert.addAction(OKAction)
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}

