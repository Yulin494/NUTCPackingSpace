//
//  PixelYouBikeView.swift
//  NUTCParkingSpace
//
//  像素模式 YouBike 站點：每站一張像素卡（可借 / 可還像素數字 + 像素進度條 + 狀態章）。
//  載入、錯誤重試、空結果擴大半徑、下拉重新整理皆由 YouBikeView 傳入並沿用。
//

import SwiftUI

struct PixelYouBikeView: View {
    let stations: [YouBikeStation]
    let isLoading: Bool
    let errorMessage: String?
    let radiusKM: Double
    let reload: () async -> Void
    let expandRadius: () async -> Void

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(PixelPalette.ink)
                    Text("載入中…")
                        .font(.system(size: 17))
                        .foregroundStyle(PixelPalette.ink)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                messageCard(glyph: .globe, text: err, buttonTitle: "重試") { await reload() }
            } else if stations.isEmpty {
                messageCard(glyph: .bike,
                            text: "附近 \(Int(radiusKM * 1000)) 公尺內無 YouBike 站點",
                            buttonTitle: "擴大至 2 公里") { await expandRadius() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(stations) { station in
                            PixelYouBikeRow(station: station)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .refreshable { await reload() }
            }
        }
        .pixelInfoPage(title: "YouBike 站點")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isLoading {
                    NamePlate(text: "\(stations.count) 站", fill: PixelPalette.gold,
                              textColor: PixelPalette.ink)
                }
            }
        }
    }

    private func messageCard(glyph: PixelInfoGlyphKind, text: String, buttonTitle: String,
                             action: @escaping () async -> Void) -> some View {
        VStack(spacing: 16) {
            PixelInfoCard {
                VStack(spacing: 12) {
                    PixelInfoGlyph(kind: glyph, scale: 4)
                    Text(text)
                        .font(.system(size: 17))
                        .foregroundStyle(PixelPalette.ink)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            Button {
                Task { await action() }
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PixelPalette.ink)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(PixelButtonStyle(fill: PixelPalette.gold))
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PixelYouBikeRow: View {
    let station: YouBikeStation

    // 有車 / 偏少 / 無車：形狀 + 文字 + 底色（比例門檻同標準版進度條）
    private enum Availability {
        case plenty, few, empty

        var label: String {
            switch self {
            case .plenty: return "有車"
            case .few: return "偏少"
            case .empty: return "無車"
            }
        }
        var icon: PixelIconKind {
            switch self {
            case .plenty: return .dot
            case .few: return .triangle
            case .empty: return .cross
            }
        }
        var fill: Color {
            switch self {
            case .plenty: return PixelPalette.grass
            case .few: return PixelPalette.orange
            case .empty: return PixelPalette.ink
            }
        }
        var foreground: Color { self == .empty ? PixelPalette.paper : PixelPalette.ink }
        var barStatus: PixelStatus {
            switch self {
            case .plenty: return .plenty
            case .few: return .tight
            case .empty: return .full
            }
        }
    }

    private var availability: Availability {
        if station.availableBikes <= 0 { return .empty }
        return station.occupancyRatio > 0.5 ? .plenty : .few
    }

    private var distanceString: String {
        station.distance < 1000
            ? "\(Int(station.distance)) m"
            : String(format: "%.1f km", station.distance / 1000)
    }

    var body: some View {
        let a = availability
        PixelInfoCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text(station.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PixelPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    PixelTagLabel(text: distanceString, fill: PixelPalette.paper)
                }
                HStack(alignment: .top, spacing: 4) {
                    PixelInfoGlyph(kind: .pin, scale: 1, color: PixelPalette.muted)
                    Text(station.address.isEmpty ? station.district : station.address)
                        .font(.system(size: 15))
                        .foregroundStyle(PixelPalette.muted)
                        .lineLimit(2)
                }
                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    countBlock(value: station.availableBikes, caption: "可借")
                    countBlock(value: station.emptyDocks, caption: "可還")
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        PixelIcon(kind: a.icon, scale: 1)
                        Text(a.label).pixelFont(size: PixelMetrics.FontSize.small)
                    }
                    .foregroundStyle(a.foreground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .pixelFrame(fill: a.fill)
                }
                // 有總量才顯示進度條（比例 = 可借 / 總格數）
                if station.totalDocks > 0 {
                    PixelOccupancyBar(ratio: station.occupancyRatio, status: a.barStatus)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(station.name)，\(station.availableBikes) 台可借，\(station.emptyDocks) 格可還，\(a.label)，距離 \(distanceString)")
    }

    private func countBlock(value: Int, caption: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text("\(value)")
                .pixelFont(size: PixelMetrics.FontSize.medium)
                .foregroundStyle(PixelPalette.ink)
            Text(caption)
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
        }
    }
}
