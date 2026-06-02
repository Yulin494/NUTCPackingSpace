//
//  AnnouncementService.swift
//  NUTCParkingSpace
//
//  NUTC 公告頁結構（實測）：
//  ・p/911-1000.php → 同一頁有三個 <table>：全校公告 / 學術活動 / 徵才訊息
//    每筆格式：
//      <td data-th="日期"><div class="d-txt">[2026-05-25]</div>   ← </td> 漏掉
//      <td data-th="標題"><div class="d-txt"><a href="http://...">標題</a></div></td>
//      <td data-th="發佈單位"><div class="d-txt">單位</div></td>
//  ・p/403-1000-17-1.php → 卡片格式（校園活動）
//      <div class="mtitle"><a href="...">標題</a><i class="mdate after">2026-06-01  09:00</i></div>
//

import Foundation

struct CrawledAnnouncement {
    let title: String
    let date: String
    let url: String
    let category: AnnouncementCategory
    let department: String
}

actor AnnouncementService {
    static let shared = AnnouncementService()

    private let baseURL = "https://www.nutc.edu.tw"

    // MARK: - Public

    func fetchAnnouncements() async throws -> [AnnouncementItem] {
        let crawled = try await fetchAll()
        return crawled.map { item in
            AnnouncementItem(
                id: UUID().uuidString,
                title: item.title,
                date: item.date,
                category: item.category,
                url: URL(string: item.url) ?? URL(string: baseURL)!
            )
        }
    }

    // MARK: - Fetch

    private func fetchAll() async throws -> [CrawledAnnouncement] {
        async let tableItems  = fetchTablePage()
        async let cardItems   = fetchCardPage()
        let all = try await tableItems + cardItems
        return all.sorted { $0.date > $1.date }
    }

    /// p/911-1000.php — 三個 table：全校公告 / 學術活動 / 徵才訊息
    private func fetchTablePage() async throws -> [CrawledAnnouncement] {
        let url = URL(string: "\(baseURL)/p/911-1000.php?Lang=zh-tw")!
        let html = try await fetch(url)
        return parseThreeTables(html)
    }

    /// p/403-1000-17-1.php — 卡片格式校園活動
    private func fetchCardPage() async throws -> [CrawledAnnouncement] {
        let url = URL(string: "\(baseURL)/p/403-1000-17-1.php?Lang=zh-tw")!
        let html = try await fetch(url)
        return parseCards(html)
    }

    private func fetch(_ url: URL) async throws -> String {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        let (data, _) = try await URLSession.shared.data(for: req)
        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
    }

    // MARK: - 表格解析（全校公告 / 學術活動 / 徵才訊息）

    private func parseThreeTables(_ html: String) -> [CrawledAnnouncement] {
        // 依照區塊標題切分 HTML，再對每個 table 套用 category
        let sections: [(marker: String, category: AnnouncementCategory)] = [
            ("全校公告", .all),
            ("學術活動", .academic),
            ("徵才訊息", .recruitment),
        ]

        var items: [CrawledAnnouncement] = []

        for (marker, category) in sections {
            guard let markerRange = html.range(of: marker) else { continue }
            // 找這個 marker 之後的第一個 <table ... </table>
            let after = String(html[markerRange.upperBound...])
            guard let tableStart = after.range(of: "<table"),
                  let tableEnd   = after.range(of: "</table>", range: tableStart.lowerBound..<after.endIndex)
            else { continue }
            let tableHTML = String(after[tableStart.lowerBound...tableEnd.upperBound])
            items.append(contentsOf: parseTable(tableHTML, category: category))
        }
        return items
    }

    private func parseTable(_ html: String, category: AnnouncementCategory) -> [CrawledAnnouncement] {
        guard let regex = try? NSRegularExpression(
            pattern: #"<td[^>]*data-th="日期"[^>]*>\s*<div[^>]*>\s*\[?(\d{4}-\d{2}-\d{2})\]?\s*</div>\s*<td[^>]*data-th="標題"[^>]*>\s*<div[^>]*>\s*<a\s[^>]*href="([^"]*)"[^>]*>([\s\S]*?)</a>[\s\S]*?<td[^>]*data-th="發佈單位"[^>]*>\s*<div[^>]*>\s*([\s\S]*?)\s*</div>"#,
            options: [.dotMatchesLineSeparators]
        ) else { return [] }

        var items: [CrawledAnnouncement] = []
        let ns = html as NSString
        for m in regex.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            guard m.numberOfRanges >= 5 else { continue }
            let date  = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
            let href  = ns.substring(with: m.range(at: 2))
            let title = ns.substring(with: m.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
            let dept  = ns.substring(with: m.range(at: 4)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            items.append(CrawledAnnouncement(title: title, date: date,
                                             url: resolveURL(href), category: category,
                                             department: dept))
        }
        return items
    }

    // MARK: - 卡片解析（校園活動）

    private func parseCards(_ html: String) -> [CrawledAnnouncement] {
        // <div class="mtitle">
        //   <a href="http://...">標題</a>
        //   <i class="mdate after">2026-06-01  09:00</i>
        guard let regex = try? NSRegularExpression(
            pattern: #"<div[^>]*class="mtitle"[^>]*>\s*<a\s[^>]*href="([^"]*)"[^>]*>\s*([\s\S]*?)\s*</a>\s*<i[^>]*class="mdate[^"]*"[^>]*>\s*(\d{4}-\d{2}-\d{2})"#,
            options: [.dotMatchesLineSeparators]
        ) else { return [] }

        var items: [CrawledAnnouncement] = []
        let ns = html as NSString
        for m in regex.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            guard m.numberOfRanges >= 4 else { continue }
            let href  = ns.substring(with: m.range(at: 1))
            let title = ns.substring(with: m.range(at: 2))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let date  = ns.substring(with: m.range(at: 3))
            guard !title.isEmpty else { continue }
            items.append(CrawledAnnouncement(title: title, date: date,
                                             url: resolveURL(href), category: .activity,
                                             department: "校園活動"))
        }
        return items
    }

    // MARK: - URL 解析

    private func resolveURL(_ href: String) -> String {
        let s = href.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("http://")  { return s.replacingOccurrences(of: "http://", with: "https://") }
        if s.hasPrefix("https://") { return s }
        if s.hasPrefix("//")       { return "https:" + s }
        if s.hasPrefix("/")        { return baseURL + s }
        return baseURL + "/" + s
    }
}
