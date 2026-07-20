//
//  AnnouncementDetailView.swift
//  NUTCParkingSpace
//

import SwiftUI
import UIKit
import WebKit

// MARK: - WKWebView wrapper

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 不重複載入，只在 makeUIView 做初始載入。
        // 重試由父層以 .id() 重建整個 WebView 觸發。
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, loadFailed: $loadFailed)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var loadFailed: Bool

        init(isLoading: Binding<Bool>, loadFailed: Binding<Bool>) {
            _isLoading = isLoading
            _loadFailed = loadFailed
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
            isLoading = true
            loadFailed = false
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            isLoading = false
        }

        // 頁面載入中途失敗
        func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            finishWithError(error)
        }

        // 初次連線／導向失敗（沒網路時走這裡，先前未實作會導致無限轉圈）
        func webView(_ webView: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            finishWithError(error)
        }

        private func finishWithError(_ error: Error) {
            isLoading = false
            // 使用者主動取消（例如快速返回）不算載入失敗
            if (error as NSError).code == NSURLErrorCancelled { return }
            loadFailed = true
        }
    }
}

// MARK: - 可重試的網頁容器（公告、圖書館、學校系統共用）

struct WebPageContainer: View {
    let url: URL
    var navigationTitle: String? = nil

    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadID = UUID()

    var body: some View {
        ZStack(alignment: .top) {
            WebView(url: url, isLoading: $isLoading, loadFailed: $loadFailed)
                .id(reloadID)
                .opacity(loadFailed ? 0 : 1)

            if loadFailed {
                WebLoadErrorView { retry() }
            } else if isLoading {
                ProgressView()
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.top, 8)
            }
        }
        .navigationTitle(navigationTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Link(destination: url) { Image(systemName: "safari") }
            }
        }
    }

    private func retry() {
        loadFailed = false
        isLoading = true
        reloadID = UUID()   // 重建 WebView → 重新載入
    }
}

struct WebLoadErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("無法載入頁面")
                .font(.headline)
            Text("請檢查您的網路連線後再試一次")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                onRetry()
            } label: {
                Label("重試", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Color.blue).foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Detail View

struct AnnouncementDetailView: View {
    let url: URL

    var body: some View {
        WebPageContainer(url: url)
    }
}

#Preview {
    NavigationStack {
        AnnouncementDetailView(url: URL(string: "https://www.nutc.edu.tw")!)
    }
}
