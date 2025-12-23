import SwiftUI

struct OnboardingView: View {
    @Binding var hasShownOnboarding: Bool
    
    // 直接從 AppIcon.appiconset 載入 1024.png
    private var appIconImage: Image {
        if let uiImage = UIImage(named: "AppIcon") {
            return Image(uiImage: uiImage)
        }
        // Fallback
        return Image(systemName: "parkingsign.circle.fill")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 40) {
                    
                    VStack(spacing: 10) {
                        appIconImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                            .shadow(radius: 10)
                        
                        Text("歡迎使用\n中科大車位通")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)

                    // 功能列表
                    VStack(alignment: .leading, spacing: 30) {
                        FeatureRow(
                            icon: "apps.iphone",
                            title: "桌面小工具",
                            description: "在主畫面新增小工具，無需開啟 App 也能隨時查看最愛停車場的剩餘車位。"
                        )
                        
                        FeatureRow(
                            icon: "hand.tap.fill",
                            title: "久按動態追蹤",
                            description: "在列表長按任一停車場，即可開啟「動態島」或「通知列」即時追蹤該車位變化。"
                        )
                        
                        FeatureRow(
                            icon: "location.fill",
                            title: "智慧到校推播",
                            description: "進入學校周邊 1000 公尺自動推播機車位資訊，支援背景執行。"
                        )
                        
                        FeatureRow(
                            icon: "arrow.clockwise",
                            title: "自動更新資訊",
                            description: "App 開啟時每分鐘自動更新，確保您掌握最新車位狀況。"
                        )
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 40)
            }

            // 底部按鈕
            Button(action: {
                withAnimation {
                    hasShownOnboarding = true
                }
            }) {
                Text("開始使用")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemBackground))
        .ignoresSafeArea()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingView(hasShownOnboarding: .constant(false))
}
