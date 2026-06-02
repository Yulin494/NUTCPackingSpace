import SwiftUI
import UIKit

// MARK: - Page Model

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let gradient: [Color]
    let icon: String
    let iconIsApp: Bool
    let title: String
    let subtitle: String
    let features: [String]
}

// MARK: - Main Onboarding

struct OnboardingView: View {
    @Binding var hasShownOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            gradient: [Color(red: 0.28, green: 0.33, blue: 0.95), Color(red: 0.55, green: 0.28, blue: 0.92)],
            icon: "AppIcon", iconIsApp: true,
            title: "歡迎使用\n中科大校園通",
            subtitle: "停車、課表、公告、天氣\n全部整合在一個 App",
            features: []
        ),
        OnboardingPage(
            gradient: [Color(red: 0.10, green: 0.60, blue: 0.90), Color(red: 0.05, green: 0.40, blue: 0.75)],
            icon: "parkingsign.circle.fill", iconIsApp: false,
            title: "即時車位查詢",
            subtitle: "秒查台中科大各停車場\n機車、汽車剩餘車位",
            features: ["每分鐘自動更新", "動態島即時追蹤", "桌面小工具支援", "到校自動推播通知"]
        ),
        OnboardingPage(
            gradient: [Color(red: 0.20, green: 0.70, blue: 0.50), Color(red: 0.10, green: 0.52, blue: 0.38)],
            icon: "building.2.fill", iconIsApp: false,
            title: "校園服務一站搞定",
            subtitle: "圖書館、公告、天氣、YouBike\n學校系統都在這裡",
            features: ["校園公告即時推送", "圖書館開放時間", "台中即時天氣", "學術行事曆倒數"]
        ),
        OnboardingPage(
            gradient: [Color(red: 0.95, green: 0.50, blue: 0.20), Color(red: 0.85, green: 0.28, blue: 0.15)],
            icon: "book.fill", iconIsApp: false,
            title: "課表與作業管理",
            subtitle: "新增課表、追蹤作業\n到期提醒不漏接",
            features: ["課程衝堂自動偵測", "作業到期前通知", "課表小工具", "行事曆匯出"]
        ),
        OnboardingPage(
            gradient: [Color(red: 0.55, green: 0.33, blue: 0.90), Color(red: 0.35, green: 0.18, blue: 0.75)],
            icon: "apps.iphone", iconIsApp: false,
            title: "小工具與通知",
            subtitle: "把重要資訊放到主畫面\n鎖定畫面隨時查看",
            features: ["停車場小工具", "天氣小工具", "課表小工具", "行事曆倒數小工具"]
        ),
    ]

    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack(spacing: 0) {
                // Skip 按鈕
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("跳過") {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
                .frame(height: 44)

                // 分頁內容
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        pageContent(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // 底部：進度點 + 按鈕
                bottomBar
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Page Content

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // 圖示
            iconView(page)
                .padding(.bottom, 36)

            // 標題
            Text(page.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 32)

            Text(page.subtitle)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.80))
                .padding(.horizontal, 40)
                .padding(.top, 12)

            // 功能列表
            if !page.features.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(page.features, id: \.self) { f in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            Text(f)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.90))
                        }
                    }
                }
                .padding(.top, 28)
                .padding(.horizontal, 48)
            }

            Spacer()
            Spacer()
        }
    }

    @ViewBuilder
    private func iconView(_ page: OnboardingPage) -> some View {
        if page.iconIsApp {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.18))
                    .frame(width: 120, height: 120)
                if let ui = UIImage(named: page.icon) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                }
            }
        } else {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 20) {
            // 進度點
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(.white.opacity(i == currentPage ? 1 : 0.35))
                        .frame(width: i == currentPage ? 22 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }

            // 主按鈕
            Button(action: advance) {
                HStack(spacing: 8) {
                    Text(currentPage < pages.count - 1 ? "下一步" : "開始使用")
                        .font(.headline)
                        .fontWeight(.semibold)
                    if currentPage < pages.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                }
                .foregroundColor(pages[currentPage].gradient.first ?? .blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            }
            .padding(.horizontal, 32)
        }
    }

    private func advance() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4)) {
                currentPage += 1
            }
        } else {
            withAnimation(.easeInOut(duration: 0.35)) {
                hasShownOnboarding = true
            }
        }
    }
}

#Preview {
    OnboardingView(hasShownOnboarding: .constant(false))
}
