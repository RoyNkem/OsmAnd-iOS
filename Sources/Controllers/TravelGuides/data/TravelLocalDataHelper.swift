//
//  TravelLocalDataHelper.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class TravelLocalDataHelper {
    
    private static let HISTORY_ITEMS_LIMIT = 300
    private let dbHelper: OATravelLocalDataDbHelper
    private var historyMap: [String : TravelSearchHistoryItem] = [:]
    private var savedArticles: [TravelArticle] = []
    var observable: OAObservable
    
    init() {
        dbHelper = OATravelLocalDataDbHelper()
        observable = OAObservable()
    }
    
    func refreshCachedData() {
        historyMap = dbHelper.getAllHistoryMap();
        savedArticles = dbHelper.readSavedArticles();
    }
    
    func getAllHistory() -> [TravelSearchHistoryItem] {
        return historyMap.values.sorted { a, b in
            return a.lastAccessed < b.lastAccessed
        }
    }
    
    func clearHistory() {
        historyMap = [:]
        dbHelper.clearAllHistory()
    }
    
    func addToHistory(article: TravelArticle) {
        var item = TravelSearchHistoryItem()
        item.articleFile = article.file
        item.articleTitle = article.title ?? ""
        item.lang = article.lang ?? ""
        item.isPartOf = article.isPartOf ?? ""
        item.lastAccessed = Date().timeIntervalSince1970
        
        let key = item.getKey()
        let exists = historyMap[key] != nil
        if !exists {
            dbHelper.add(item)
            historyMap[key] = item
        } else {
            dbHelper.update(item)
        }
        if historyMap.count > TravelLocalDataHelper.HISTORY_ITEMS_LIMIT {
            let allHistory = getAllHistory()
            let lastItem = allHistory[allHistory.count - 1]
            dbHelper.remove(lastItem)
            historyMap.removeValue(forKey: key)
        }
    }
    
    func hasSavedArticles() -> Bool {
        return !savedArticles.isEmpty || dbHelper.hasSavedArticles()
    }
    
    func getSavedArticles() -> [TravelArticle] {
        return Array(savedArticles)
    }
    
    func addArticleToSaved(article: TravelArticle) {
        if !isArticleSaved(article: article) {
            savedArticles.append(article)
            dbHelper.addSavedArticle(article)
            notifySavedUpdated()
        }
    }
    
    func removeArticleFromSaved(article: TravelArticle) {
        let savedArticle = getArticle(title: article.title ?? "", lang: article.lang ?? "")
        if let savedArticle {
            if let index = savedArticles.firstIndex(of: savedArticle) {
                savedArticles.remove(at: index)
            }
            dbHelper.removeSavedArticle(savedArticle)
            notifySavedUpdated()
        }
    }
    
    func isArticleSaved(article: TravelArticle) -> Bool {
        return getArticle(title: article.title ?? "", lang: article.lang ?? "") != nil
    }
    
    func notifySavedUpdated() {
        observable.notifyEvent()
    }
    
    func getArticle(title: String, lang: String) -> TravelArticle? {
        for article in savedArticles {
            if article.title == title && article.lang == lang {
                return article
            }
        }
        return nil
    }
    
    func getSavedArticle(file: String, routeId: String, lang: String) -> TravelArticle? {
        for article in savedArticles {
            if article.file == file && article.routeId == routeId && article.lang == lang {
                return article
            }
        }
        return nil
    }
    
    func getSavedArticles(file: String, routeId: String) -> [TravelArticle] {
        var articles: [TravelArticle] = []
        for article in savedArticles {
            if article.file == file && article.routeId == routeId {
                articles.append(article)
            }
        }
        return articles
    }
    
}
