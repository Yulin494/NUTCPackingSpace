import SwiftUI

struct LibraryView: View {
    private let catalogURL = URL(string: "https://elib.nutc.edu.tw/")!

    // 是否在開放時間
    private var isOpenNow: Bool {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=Sun
        let hour    = cal.component(.hour,    from: now)
        let minute  = cal.component(.minute,  from: now)
        let totalMin = hour * 60 + minute

        switch weekday {
        case 2...6: return totalMin >= 8*60 && totalMin < 22*60   // Mon-Fri 8:00-22:00
        case 7:     return totalMin >= 9*60 && totalMin < 17*60   // Sat 9:00-17:00
        default:    return false                                    // Sun 閉館
        }
    }

    var body: some View {
        List {
            // MARK: 開放狀態
            Section {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isOpenNow ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: isOpenNow ? "door.left.hand.open" : "door.left.hand.closed")
                            .font(.title3)
                            .foregroundColor(isOpenNow ? .green : .red)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isOpenNow ? "現在開放中" : "目前閉館")
                            .font(.headline)
                            .foregroundColor(isOpenNow ? .green : .red)
                        Text("台灣大道校區圖書館")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: 開放時間
            Section(header: Text("開放時間")) {
                hoursRow(days: "週一至週五", hours: "08:00 – 22:00")
                hoursRow(days: "週六",       hours: "09:00 – 17:00")
                hoursRow(days: "週日 / 國定假日", hours: "閉館")
            }

            // MARK: 各樓層
            Section(header: Text("樓層指引")) {
                floorRow(floor: "1F", name: "期刊 / 報紙",     icon: "newspaper.fill",      color: .orange)
                floorRow(floor: "2F", name: "參考書 / 視聽室", icon: "play.rectangle.fill",  color: .blue)
                floorRow(floor: "3F", name: "中文圖書區",      icon: "text.book.closed.fill", color: .green)
                floorRow(floor: "4F", name: "外文圖書 / 研究小間", icon: "globe.desk.fill",  color: .purple)
                floorRow(floor: "B1", name: "自修室 / 電子資源",   icon: "desktopcomputer",  color: .indigo)
            }

            // MARK: 服務
            Section(header: Text("主要服務")) {
                serviceRow(icon: "magnifyingglass",        color: .blue,   name: "館藏查詢",   desc: "書目搜尋、館位查詢")
                serviceRow(icon: "arrow.left.arrow.right", color: .green,  name: "館際互借",   desc: "他館借閱、文獻傳遞")
                serviceRow(icon: "printer.fill",           color: .orange, name: "複印 / 列印",desc: "黑白、彩色、A3")
                serviceRow(icon: "door.sliding.left.hand.closed", color: .purple, name: "討論室預約", desc: "需提前在線上預約")
                serviceRow(icon: "graduationcap.fill",     color: .teal,   name: "讀書指導",   desc: "文獻資料庫使用教學")
            }

            // MARK: 館藏搜尋
            Section {
                NavigationLink(destination: LibraryCatalogView(url: catalogURL)) {
                    Label("進入館藏查詢系統", systemImage: "books.vertical.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("圖書館")
        .navigationBarTitleDisplayMode(.large)
    }

    private func hoursRow(days: String, hours: String) -> some View {
        HStack {
            Text(days).foregroundColor(.primary)
            Spacer()
            Text(hours)
                .foregroundColor(hours == "閉館" ? .red : .secondary)
                .font(.subheadline)
        }
    }

    private func floorRow(floor: String, name: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(floor).font(.caption2).foregroundColor(.secondary)
                Text(name).font(.subheadline)
            }
        }
        .padding(.vertical, 2)
    }

    private func serviceRow(icon: String, color: Color, name: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.subheadline)
                Text(desc).font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Catalog WebView

struct LibraryCatalogView: View {
    let url: URL
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .top) {
            WebView(url: url, isLoading: $isLoading)
            if isLoading {
                ProgressView()
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.top, 8)
            }
        }
        .navigationTitle("館藏查詢")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Link(destination: url) { Image(systemName: "safari") }
            }
        }
    }
}

#Preview {
    NavigationStack { LibraryView() }
}
