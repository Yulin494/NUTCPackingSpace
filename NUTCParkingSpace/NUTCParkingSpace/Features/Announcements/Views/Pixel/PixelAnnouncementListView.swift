//
//  PixelAnnouncementListView.swift
//  NUTCParkingSpace
//
//  像素模式校園公告列表。資料來源、篩選、下拉更新、導覽沿用 AnnouncementListView。
//

import SwiftUI

private func pixelCategoryFill(_ cat: AnnouncementCategory) -> Color {
    switch cat {
    case .all:         return PixelPalette.water
    case .academic:    return PixelPalette.gold
    case .recruitment: return PixelPalette.orange
    case .activity:    return PixelPalette.grass
    }
}

struct PixelAnnouncementListView: View {
    @State private var selectedCategory: AnnouncementCategory = .all
    @StateObject private var viewModel = AnnouncementViewModel()

    private var filteredAnnouncements: [AnnouncementItem] {
        selectedCategory == .all
            ? viewModel.announcements
            : viewModel.announcements.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                segmented

                if viewModel.isLoading && viewModel.announcements.isEmpty {
                    loadingView
                } else if let err = viewModel.errorMessage, viewModel.announcements.isEmpty {
                    errorView(err)
                } else if filteredAnnouncements.isEmpty {
                    emptyView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAnnouncements) { item in
                            NavigationLink(destination: AnnouncementDetailView(url: item.url)) {
                                PixelAnnouncementRow(item: item)
                            }
                            .buttonStyle(PixelButtonStyle(
                                contentPadding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)))
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 16)
        }
        .foregroundStyle(PixelPalette.ink)
        .background(PixelPalette.paper2.ignoresSafeArea())
        .navigationTitle("校園公告")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PixelPalette.paper2, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("校園公告").pixelFont(size: PixelMetrics.FontSize.medium)
                    .foregroundStyle(PixelPalette.ink)
                    .accessibilityHidden(true)
            }
        }
        .refreshable { await viewModel.fetchAnnouncements() }
        .task { if viewModel.announcements.isEmpty { await viewModel.fetchAnnouncements() } }
    }

    // MARK: 分類分段

    private var segmented: some View {
        HStack(spacing: 6) {
            ForEach(AnnouncementCategory.allCases, id: \.self) { cat in
                let selected = selectedCategory == cat
                Button {
                    selectedCategory = cat
                } label: {
                    HStack(spacing: 2) {
                        if selected { PixelIcon(kind: .check, scale: 1) }
                        Text(cat.rawValue)
                            .pixelFont(size: PixelMetrics.FontSize.small)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(PixelButtonStyle(
                    fill: selected ? pixelCategoryFill(cat) : PixelPalette.paper,
                    contentPadding: EdgeInsets(top: 6, leading: 2, bottom: 6, trailing: 2)))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    // MARK: 狀態

    private var loadingView: some View {
        VStack(spacing: 12) {
            NamePlate(text: "載入公告中")
            ForEach(0..<4, id: \.self) { _ in
                Rectangle()
                    .fill(PixelPalette.paper)
                    .frame(height: 72)
                    .pixelFrame(fill: PixelPalette.paper)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("載入公告中")
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 14) {
            NamePlate(text: "無法載入公告", fill: PixelPalette.red)
            PixelIcon(kind: .alert, scale: 4, color: PixelPalette.red)
            Text(msg)
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.fetchAnnouncements() }
            } label: {
                Text("重試").pixelFont(size: PixelMetrics.FontSize.medium)
                    .frame(minWidth: 96, minHeight: 28)
            }
            .buttonStyle(PixelButtonStyle(fill: PixelPalette.gold))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .pixelFrame()
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            NamePlate(text: "沒有公告")
            Text("這個分類目前沒有公告")
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .pixelFrame()
    }
}

// MARK: - 單筆公告

private struct PixelAnnouncementRow: View {
    let item: AnnouncementItem

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(PixelPalette.ink)
                HStack(spacing: 8) {
                    Text(item.date)
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(PixelPalette.muted)
                    Text(item.category.rawValue)
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(PixelPalette.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .pixelFrame(fill: pixelCategoryFill(item.category))
                }
            }
            Spacer(minLength: 4)
            // 進入內文的指示箭頭：三角轉 90 度成 ▶，避免與「緊張」狀態的 ▲ 混淆
            PixelIcon(kind: .triangle, scale: 1, color: PixelPalette.ink)
                .rotationEffect(.degrees(90))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { PixelAnnouncementListView() }
}
