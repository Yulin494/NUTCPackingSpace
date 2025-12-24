import SwiftUI

struct FriendlyErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill") // 使用系統圖示或自定義插圖
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.orange)
            
            Text("伺服器去喝咖啡了")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("暫時無法取得最新車位資訊\n請稍後再試或是檢查您的網路連線")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
            
            Button(action: {
                HapticManager.shared.impact(style: .medium)
                retryAction()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("重試")
                }
                .fontWeight(.semibold)
                .padding()
                .frame(minWidth: 120)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 2)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .padding()
    }
}

struct FriendlyErrorView_Previews: PreviewProvider {
    static var previews: some View {
        FriendlyErrorView(message: "連線逾時 (404)", retryAction: {})
    }
}
