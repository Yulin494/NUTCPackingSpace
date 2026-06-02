//
//  AnnouncementDetailView.swift
//  NUTCParkingSpace
//

import SwiftUI
import WebKit

// MARK: - WKWebView wrapper

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 不重複載入，只在 makeUIView 做初始載入
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        init(isLoading: Binding<Bool>) { _isLoading = isLoading }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
            isLoading = true
        }
        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            isLoading = false
        }
        func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError _: Error) {
            isLoading = false
        }
    }
}

// MARK: - Detail View

struct AnnouncementDetailView: View {
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Link(destination: url) {
                    Image(systemName: "safari")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnnouncementDetailView(url: URL(string: "https://www.nutc.edu.tw")!)
    }
}
