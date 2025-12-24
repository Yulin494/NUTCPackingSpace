import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    // 避免頻繁初始化
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactLightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let impactMediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    private init() {
        notificationGenerator.prepare()
        impactLightGenerator.prepare()
        impactMediumGenerator.prepare()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLightGenerator.impactOccurred()
        case .medium:
            impactMediumGenerator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .soft:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        case .rigid:
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        @unknown default:
            impactLightGenerator.impactOccurred()
        }
    }
}
