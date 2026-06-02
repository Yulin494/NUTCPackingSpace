//
//  AnnouncementViewModel.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI
import Combine

class AnnouncementViewModel: ObservableObject {
    @Published var announcements: [AnnouncementItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = AnnouncementService.shared

    func fetchAnnouncements() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let items = try await service.fetchAnnouncements()
            await MainActor.run {
                announcements = items
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "無法載入公告：\(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func filteredAnnouncements(for category: AnnouncementCategory) -> [AnnouncementItem] {
        if category == .all {
            return announcements
        }
        return announcements.filter { $0.category == category }
    }
}
