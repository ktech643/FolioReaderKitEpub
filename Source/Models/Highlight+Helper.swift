//
//  Highlight+Helper.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 06/07/16.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import RealmSwift

/**
 HighlightStyle type, default is .Yellow.
 */
public enum HighlightStyle: Int {
    case yellow
    case green
    case blue
    case pink
    case underline

    public init () {
        // Default style is `.yellow`
        self = .yellow
    }

    /**
     Return HighlightStyle for CSS class.
     */
    public static func styleForClass(_ className: String) -> HighlightStyle {
        switch className {
        case "highlight-yellow": return .yellow
        case "highlight-green": return .green
        case "highlight-blue": return .blue
        case "highlight-pink": return .pink
        case "highlight-underline": return .underline
        default: return .yellow
        }
    }

    /**
     Return CSS class for HighlightStyle.
     */
    public static func classForStyle(_ style: Int) -> String {

        let enumStyle = (HighlightStyle(rawValue: style) ?? HighlightStyle())
        switch enumStyle {
        case .yellow: return "highlight-yellow"
        case .green: return "highlight-green"
        case .blue: return "highlight-blue"
        case .pink: return "highlight-pink"
        case .underline: return "highlight-underline"
        }
    }

    /// Color components for the style
    ///
    /// - Returns: Tuple of all color compnonents.
    private func colorComponents() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        switch self {
        case .yellow: return (red: 255, green: 235, blue: 107, alpha: 0.9)
        case .green: return (red: 192, green: 237, blue: 114, alpha: 0.9)
        case .blue: return (red: 173, green: 216, blue: 255, alpha: 0.9)
        case .pink: return (red: 255, green: 176, blue: 202, alpha: 0.9)
        case .underline: return (red: 240, green: 40, blue: 20, alpha: 0.6)
        }
    }

    /**
     Return CSS class for HighlightStyle.
     */
    public static func colorForStyle(_ style: Int, nightMode: Bool = false) -> UIColor {
        let enumStyle = (HighlightStyle(rawValue: style) ?? HighlightStyle())
        let colors = enumStyle.colorComponents()
        return UIColor(red: colors.red/255, green: colors.green/255, blue: colors.blue/255, alpha: (nightMode ? colors.alpha : 1))
    }
}

/// :nodoc:
public typealias Completion = (_ error: NSError?) -> ()

extension HighlightIOS {

    /// Save a Highlight with completion block
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - completion: Completion block.
    public func persist(withConfiguration readerConfig: FolioReaderConfig, completion: Completion? = nil) {
        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            realm.beginWrite()
            realm.add(self, update: .all)
            try realm.commitWrite()
            completion?(nil)
        } catch let error as NSError {
            print("Error on persist highlight: \(error)")
            completion?(error)
        }
    }

    /// Remove a Highlight
    ///
    /// - Parameter readerConfig: Current folio reader configuration.
    public func remove(withConfiguration readerConfig: FolioReaderConfig) {
        do {
            guard let realm = try? Realm(configuration: readerConfig.realmConfiguration) else {
                return
            }
            try realm.write {
                realm.delete(self)
                try realm.commitWrite()
            }
        } catch let error as NSError {
            print("Error on remove highlight: \(error)")
        }
    }

    /// Remove a Highlight by ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    public static func removeById(withConfiguration readerConfig: FolioReaderConfig, highlightId: String) {
        var highlight: HighlightIOS?
        let predicate = NSPredicate(format:"highlightId = %@", highlightId)

        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            highlight = realm.objects(HighlightIOS.self).filter(predicate).toArray(HighlightIOS.self).first
            highlight?.remove(withConfiguration: readerConfig)
        } catch let error as NSError {
            print("Error on remove highlight by id: \(error)")
        }
    }
    
    /// Return a Highlight by ID
    ///
    /// - Parameter:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    ///   - page: Page number
    /// - Returns: Return a Highlight
    public static func getById(withConfiguration readerConfig: FolioReaderConfig, highlightId: String) -> HighlightIOS? {
        var highlight: HighlightIOS?
        let predicate = NSPredicate(format:"highlightId = %@", highlightId)

        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            highlight = realm.objects(HighlightIOS.self).filter(predicate).toArray(HighlightIOS.self).first
            return highlight
        } catch let error as NSError {
            print("Error getting Highlight : \(error)")
        }

        return highlight
    }

    /// Update a Highlight by ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - highlightId: The ID to be removed
    ///   - type: The `HighlightStyle`
    public static func updateById(withConfiguration readerConfig: FolioReaderConfig, highlightId: String, type: HighlightStyle) {
        var highlight: HighlightIOS?
        let predicate = NSPredicate(format:"highlightId = %@", highlightId)
        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            highlight = realm.objects(HighlightIOS.self).filter(predicate).toArray(HighlightIOS.self).first
            realm.beginWrite()

            highlight?.type = type.hashValue

            try realm.commitWrite()
            
        } catch let error as NSError {
            print("Error on updateById: \(error)")
        }

    }

    /// Return a list of Highlights with a given ID
    ///
    /// - Parameters:
    ///   - readerConfig: Current folio reader configuration.
    ///   - bookId: Book ID
    ///   - page: Page number
    /// - Returns: Return a list of Highlights
    public static func allByBookId(withConfiguration readerConfig: FolioReaderConfig, bookId: String, andPage page: NSNumber? = nil) -> [HighlightIOS] {
        var highlights: [HighlightIOS]?
        var predicate = NSPredicate(format: "bookId = %@", bookId)
        if let page = page {
            predicate = NSPredicate(format: "bookId = %@ && page = %@", bookId, page)
        }

        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            highlights = realm.objects(HighlightIOS.self).filter(predicate).toArray(HighlightIOS.self)
            return (highlights ?? [])
        } catch let error as NSError {
            print("Error on fetch all by book Id: \(error)")
            return []
        }
    }

    /// Return all Highlights
    ///
    /// - Parameter readerConfig: - readerConfig: Current folio reader configuration.
    /// - Returns: Return all Highlights
    public static func all(withConfiguration readerConfig: FolioReaderConfig) -> [HighlightIOS] {
        var highlights: [HighlightIOS]?
        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            highlights = realm.objects(HighlightIOS.self).toArray(HighlightIOS.self)
            return (highlights ?? [])
        } catch let error as NSError {
            print("Error on fetch all: \(error)")
            return []
        }
    }
}

// MARK: - HTML Methods

extension HighlightIOS {

    public struct MatchingHighlight {
        var text: String
        var id: String
        var startOffset: String
        var endOffset: String
        var bookId: String
        var currentPage: Int
    }

    /**
     Match a highlight on string.
     */
    public static func matchHighlight(_ matchingHighlight: MatchingHighlight) -> HighlightIOS? {
        let pattern = "<highlight id=\"\(matchingHighlight.id)\" onclick=\".*?\" class=\"(.*?)\">((.|\\s)*?)</highlight>"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: matchingHighlight.text, options: [], range: NSRange(location: 0, length: matchingHighlight.text.utf16.count))
        let str = (matchingHighlight.text as NSString)

        let mapped = matches?.map { (match) -> HighlightIOS in
            var contentPre = str.substring(with: NSRange(location: match.range.location-kHighlightRange, length: kHighlightRange))
            var contentPost = str.substring(with: NSRange(location: match.range.location + match.range.length, length: kHighlightRange))

            // Normalize string before save
            contentPre = HighlightIOS.subString(ofContent: contentPre, fromRangeOfString: ">", withPattern: "((?=[^>]*$)(.|\\s)*$)")
            contentPost = HighlightIOS.subString(ofContent: contentPost, fromRangeOfString: "<", withPattern: "^((.|\\s)*?)(?=<)")

            let highlight = HighlightIOS()
            highlight.highlightId = matchingHighlight.id
            highlight.type = HighlightStyle.styleForClass(str.substring(with: match.range(at: 1))).rawValue
            highlight.date = Date()
            highlight.content = HighlightIOS.removeSentenceSpam(str.substring(with: match.range(at: 2)))
            highlight.contentPre = HighlightIOS.removeSentenceSpam(contentPre)
            highlight.contentPost = HighlightIOS.removeSentenceSpam(contentPost)
            highlight.page = matchingHighlight.currentPage
            highlight.bookId = matchingHighlight.bookId
            highlight.startOffset = (Int(matchingHighlight.startOffset) ?? -1)
            highlight.endOffset = (Int(matchingHighlight.endOffset) ?? -1)

            return highlight
        }

        return mapped?.first
    }

    private static func subString(ofContent content: String, fromRangeOfString rangeString: String, withPattern pattern: String) -> String {
        var updatedContent = content
        if updatedContent.range(of: rangeString) != nil {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let searchString = regex?.firstMatch(in: updatedContent, options: .reportProgress, range: NSRange(location: 0, length: updatedContent.count))

            if let string = searchString, (string.range.location != NSNotFound) {
                updatedContent = (updatedContent as NSString).substring(with: string.range)
            }
        }

        return updatedContent
    }

    /// Remove a Highlight from HTML by ID
    ///
    /// - Parameters:
    ///   - page: The page containing the HTML.
    ///   - highlightId: The ID to be removed
    /// - Returns: The removed id
    @discardableResult public static func removeFromHTMLById(withinPage page: FolioReaderPage?, highlightId: String) -> String? {
        guard let currentPage = page else { return nil }
        
        if let removedId = currentPage.webView?.js("removeHighlightById('\(highlightId)')") {
            return removedId
        } else {
            print("Error removing Highlight from page")
            return nil
        }
    }
    
    /**
     Remove span tag before store the highlight, this span is added on JavaScript.
     <span class=\"sentence\"></span>
     
     - parameter text: Text to analise
     - returns: Striped text
     */
    public static func removeSentenceSpam(_ text: String) -> String {
        
        // Remove from text
        func removeFrom(_ text: String, withPattern pattern: String) -> String {
            var locator = text
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.matches(in: locator, options: [], range: NSRange(location: 0, length: locator.utf16.count))
            let str = (locator as NSString)
            
            var newLocator = ""
            matches?.forEach({ (match: NSTextCheckingResult) in
                newLocator += str.substring(with: match.range(at: 1))
            })
            
            if (matches?.count > 0 && newLocator.isEmpty == false) {
                locator = newLocator
            }
            
            return locator
        }
        
        let pattern = "<span class=\"sentence\">((.|\\s)*?)</span>"
        let cleanText = removeFrom(text, withPattern: pattern)
        return cleanText
    }
}
