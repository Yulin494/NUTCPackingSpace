//
//  PixelAnnouncementDetailView.swift
//  NUTCParkingSpace
//
//  像素模式公告內文：網頁內容以紙色邊框容器呈現，載入中與錯誤狀態為像素樣式。
//  沿用 WebView（WKWebView 包裝）、重試重建機制與「在 Safari 開啟」。
//

import SwiftUI

struct PixelAnnouncementDetailView: View {
    let url: URL

    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadID = UUID()

    var body: some View {
        ZStack(alignment: .top) {
            WebView(url: url, isLoading: $isLoading, loadFailed: $loadFailed)
                .id(reloadID)
                .opacity(loadFailed ? 0 : 1)

            if loadFailed {
                errorView
            } else if isLoading {
                NamePlate(text: "載入中")
                    .padding(.top, 8)
                    .accessibilityLabel("頁面載入中")
            }
        }
        .foregroundStyle(PixelPalette.ink)
        .background(PixelPalette.paper2.ignoresSafeArea())
        .navigationTitle("公告內文")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PixelPalette.paper2, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("公告內文").pixelFont(size: PixelMetrics.FontSize.medium)
                    .foregroundStyle(PixelPalette.ink)
                    .accessibilityHidden(true)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Link(destination: url) {
                    Text("網頁").pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(PixelPalette.ink)
                        .frame(minWidth: 44, minHeight: 28)
                        .padding(.horizontal, 4)
                        .pixelFrame(fill: PixelPalette.gold)
                }
                .accessibilityLabel("在 Safari 開啟")
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            NamePlate(text: "無法載入頁面", fill: PixelPalette.red)
            PixelIcon(kind: .alert, scale: 4, color: PixelPalette.red)
            Text("請檢查您的網路連線後再試一次")
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
                .multilineTextAlignment(.center)
            Button {
                loadFailed = false
                isLoading = true
                reloadID = UUID()
            } label: {
                Text("重試").pixelFont(size: PixelMetrics.FontSize.medium)
                    .frame(minWidth: 96, minHeight: 28)
            }
            .buttonStyle(PixelButtonStyle(fill: PixelPalette.gold))
        }
        .padding(24)
        .pixelFrame()
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PixelPalette.paper)
    }
}

#Preview {
    NavigationStack {
        PixelAnnouncementDetailView(url: URL(string: "https://www.nutc.edu.tw")!)
    }
}
