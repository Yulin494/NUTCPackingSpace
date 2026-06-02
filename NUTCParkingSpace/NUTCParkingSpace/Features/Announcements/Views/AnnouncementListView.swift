//
//  AnnouncementListView.swift
//  NUTCParkingSpace
//

import SwiftUI
import UIKit

struct AnnouncementListView: View {
    @State private var selectedCategory: AnnouncementCategory = .all
    @StateObject private var viewModel = AnnouncementViewModel()

    var filteredAnnouncements: [AnnouncementItem] {
        selectedCategory == .all
            ? viewModel.announcements
            : viewModel.announcements.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 分類 Chip filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AnnouncementCategory.allCases, id: \.self) { cat in
                            CategoryChip(
                                label: cat.rawValue,
                                isSelected: selectedCategory == cat,
                                color: categoryColor(cat),
                                action: { withAnimation(.spring(response: 0.3)) { selectedCategory = cat } }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 內容
                if viewModel.isLoading {
                    loadingPlaceholder
                } else if let err = viewModel.errorMessage, viewModel.announcements.isEmpty {
                    errorView(err)
                } else if filteredAnnouncements.isEmpty {
                    emptyView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAnnouncements) { item in
                            NavigationLink(destination: AnnouncementDetailView(url: item.url)) {
                                AnnouncementCardRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("校園公告")
        .refreshable { await viewModel.fetchAnnouncements() }
        .task { if viewModel.announcements.isEmpty { await viewModel.fetchAnnouncements() } }
    }

    // MARK: - States
    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(height: 80)
                    .shimmer()
            }
        }
        .padding(.horizontal, 16)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40)).foregroundColor(.orange)
            Text("無法載入公告").font(.headline)
            Text(msg).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button {
                Task { await viewModel.fetchAnnouncements() }
            } label: {
                Label("重試", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Color.blue).foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "newspaper").font(.system(size: 40)).foregroundColor(.secondary)
            Text("沒有公告").foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }

    private func categoryColor(_ cat: AnnouncementCategory) -> Color {
        switch cat {
        case .all:         return .blue
        case .academic:    return .purple
        case .recruitment: return .orange
        case .activity:    return .green
        }
    }
}

// MARK: - 單筆公告卡片
struct AnnouncementCardRow: View {
    let item: AnnouncementItem

    private var accentColor: Color {
        switch item.category {
        case .all:         return .blue
        case .academic:    return .purple
        case .recruitment: return .orange
        case .activity:    return .green
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // 左側色條
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    HStack(spacing: 8) {
                        Text(item.date)
                            .font(.caption2).foregroundColor(.secondary)
                        Text(item.category.rawValue)
                            .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(accentColor.opacity(0.12))
                            .foregroundColor(accentColor)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(14)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        AnnouncementListView()
    }
}
