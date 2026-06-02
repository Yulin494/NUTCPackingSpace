//
//  AnnouncementItem.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import Foundation

struct AnnouncementItem: Identifiable, Codable {
    let id: String
    let title: String
    let date: String
    let category: AnnouncementCategory
    let url: URL

    enum CodingKeys: String, CodingKey {
        case id, title, date, category
        case url = "urlString"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(category, forKey: .category)
        try container.encode(url.absoluteString, forKey: .url)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(String.self, forKey: .date)
        category = try container.decode(AnnouncementCategory.self, forKey: .category)
        let urlString = try container.decode(String.self, forKey: .url)
        url = URL(string: urlString) ?? URL(string: "https://www.nutc.edu.tw")!
    }

    init(id: String, title: String, date: String, category: AnnouncementCategory, url: URL) {
        self.id = id
        self.title = title
        self.date = date
        self.category = category
        self.url = url
    }
}

enum AnnouncementCategory: String, CaseIterable, Codable {
    case all = "全校公告"
    case academic = "學術活動"
    case recruitment = "徵才訊息"
    case activity = "校園活動"
}
