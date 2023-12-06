//
//  HelpDetailsViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

@objc(OAHelpDetailsViewController)
@objcMembers
class HelpDetailsViewController: OABaseNavbarViewController {
    var helpDataManager: HelpDataManager?
    var telegramChats: [TelegramChat] = []
    
    override func commonInit() {
        helpDataManager = HelpDataManager.sharedInstance
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadAndParseJson()
    }
    
    override func getTitle() -> String? {
        return localizedString("telegram_chats")
    }
    
    override func getNavbarColorScheme() -> EOABaseNavbarColorScheme {
        .orange
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    func generateTelegramChatsData() {
        tableData.clearAllData()
        let telegramChatsSection = tableData.createNewSection()
        for chat in telegramChats {
            let title = removeTextInBrackets(from: chat.title)
            let url = chat.url
            let chatRow = telegramChatsSection.createNewRow()
            chatRow.cellType = OASimpleTableViewCell.getIdentifier()
            chatRow.key = "telegramChats"
            chatRow.title = title
            chatRow.descr = url
            chatRow.iconName = "ic_custom_logo_telegram"
            chatRow.setObj(url, forKey: "url")
        }
    }
    
    func loadAndParseJson() {
        HelpDataManager.sharedInstance.loadAndParseJson(from: kPopularArticlesAndTelegramChats) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.telegramChats = HelpDataManager.sharedInstance.getTelegramChats()
                    self?.generateTelegramChatsData()
                    self?.tableView.reloadData()
                } else {
                    print(localizedString("osm_failed_uploads"))
                }
            }
        }
    }
    
    override func sectionsCount() -> Int {
        return Int(tableData.sectionCount())
    }
    
    override func rowsCount(_ section: Int) -> Int {
        Int(tableData.rowCount(UInt(section)))
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath = indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
        if cell == nil {
            let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
            cell = nib?.first as? OASimpleTableViewCell
            cell?.leftIconView.tintColor = .iconColorDefault
        }
        if let cell = cell {
            cell.titleLabel.text = item.title
            cell.descriptionLabel.text = item.descr
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
        }
        return cell
    }
    
    override func onRowSelected(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        let item = tableData.item(for: indexPath)
        if item.key == "telegramChats" {
            if let urlString = item.obj(forKey: "url") as? String,
               let url = URL(string: urlString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func removeTextInBrackets(from string: String) -> String {
        let pattern = "\\s*\\(.*?\\)"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(string.startIndex..., in: string)
            return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
        } catch {
            return string
        }
    }
}
