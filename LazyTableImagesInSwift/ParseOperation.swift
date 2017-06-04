//
//  ParseOperation.swift
//  LazyTableImagesInSwift
//
//  Created by 兎澤　佑　 on 2017/06/03.
//  Copyright © 2017年 tasuku tozawa. All rights reserved.
//

import Foundation

class ParseOperation: Operation {
    let kIDStr = "id"
    let kNameStr = "im:name"
    let kImageStr = "im:image"
    let kArtistStr = "im:artist"
    let kEntryStr = "entry"
    
    var appRecordList: [AppRecord]?
    var errorHandler: ((_ error: Error)->Void)?
    
    var dataToParse: Data!
    var elementsToParse: NSArray!
    
    var workingArray: [AppRecord]?
    var workingEntry: AppRecord?
    var workingPropertyString: NSMutableString?
    var storingCharacterData: Bool?
    
    override init() {
        super.init()
    }
    
    convenience init(data: Data) {
        self.init()
        self.dataToParse = data
        self.elementsToParse = [kIDStr, kNameStr, kImageStr, kArtistStr]
    }
    
    override func main() {
        // The default implemetation of the -start method sets up an autorelease pool
        // just before invoking -main however it does NOT setup an excption handler
        // before invoking -main.  If an exception is thrown here, the app will be
        // terminated.
        
        self.workingArray = []
        self.workingPropertyString = ""
        
        // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not
        // desirable because it gives less control over the network, particularly in responding to
        // connection errors.
        //
        let parser = XMLParser(data: self.dataToParse!)
        parser.delegate = self
        parser.parse()
        
        if !self.isCancelled {
            // Set appRecordList to the result of our parsing
            self.appRecordList = self.workingArray
        }
        
        self.workingArray = nil
        self.workingPropertyString = nil
        self.dataToParse = nil
    }
}

extension ParseOperation: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // entry: { id (link), im:name (app name), im:image (variable height) }
        //
        if elementName == kEntryStr {
            self.workingEntry = AppRecord()
        }
        self.storingCharacterData = self.elementsToParse!.contains(elementName)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if self.workingEntry != nil {
            if self.storingCharacterData! {
                let trimmedString = self.workingPropertyString!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                self.workingPropertyString!.setString("")
                
                if elementName == kIDStr {
                    self.workingEntry!.appURLString = trimmedString
                } else if elementName == kNameStr {
                    self.workingEntry!.appName = trimmedString
                } else if elementName == kImageStr {
                    self.workingEntry!.imageURLString = trimmedString
                } else if elementName == kArtistStr {
                    self.workingEntry!.artist = trimmedString
                }
            } else if elementName == kEntryStr {
                self.workingArray!.append(self.workingEntry!)
                self.workingEntry = nil
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if self.storingCharacterData! {
            self.workingPropertyString?.append(string)
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        if let handler = self.errorHandler {
            handler(parseError)
        }
    }
}
