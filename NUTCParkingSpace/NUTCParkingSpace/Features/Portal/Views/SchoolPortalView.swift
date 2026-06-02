import SwiftUI

struct PortalItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: Color
    let urlString: String
}

struct SchoolPortalView: View {
    private let portals: [PortalItem] = [
        PortalItem(name: "學生入口網站",     description: "選課、成績、請假、繳費",
                   icon: "person.crop.rectangle.fill", color: .blue,
                   urlString: "https://sso.nutc.edu.tw/eportal/"),
        PortalItem(name: "圖書館館藏查詢",   description: "書籍搜尋、借閱紀錄",
                   icon: "books.vertical.fill",        color: .orange,
                   urlString: "https://elib.nutc.edu.tw/"),
        PortalItem(name: "教務處",           description: "學籍、課程、行事曆",
                   icon: "graduationcap.fill",         color: .green,
                   urlString: "https://aca.nutc.edu.tw/"),
        PortalItem(name: "學校官網",         description: "最新消息、招生資訊",
                   icon: "globe",                      color: .teal,
                   urlString: "https://www.nutc.edu.tw"),
        PortalItem(name: "學務處",           description: "學生事務、社團、獎懲",
                   icon: "person.3.fill",              color: .purple,
                   urlString: "https://stud.nutc.edu.tw/"),
        PortalItem(name: "計算機中心",       description: "帳號申請、軟體下載、VPN",
                   icon: "desktopcomputer",            color: .indigo,
                   urlString: "https://cc.nutc.edu.tw/"),
    ]

    var body: some View {
        List(portals) { item in
            NavigationLink(destination: PortalWebView(item: item)) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(item.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: item.icon)
                            .font(.title3)
                            .foregroundColor(item.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.headline)
                        Text(item.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("學校系統")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - In-app browser

struct PortalWebView: View {
    let item: PortalItem
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .top) {
            if let url = URL(string: item.urlString) {
                WebView(url: url, isLoading: $isLoading)
                if isLoading {
                    ProgressView()
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.top, 8)
                }
            } else {
                Text("無效連結").foregroundColor(.secondary)
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let url = URL(string: item.urlString) {
                    Link(destination: url) {
                        Image(systemName: "safari")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { SchoolPortalView() }
}
