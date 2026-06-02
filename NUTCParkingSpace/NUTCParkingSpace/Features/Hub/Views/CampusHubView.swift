//
//  CampusHubView.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI

struct CampusHubView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: AnnouncementListView()) {
                    Label("校園公告", systemImage: "megaphone.fill")
                }

                NavigationLink(destination: AcademicCalendarView()) {
                    Label("學術行事曆", systemImage: "calendar")
                }

                NavigationLink(destination: DiningView()) {
                    Label("一中街美食", systemImage: "fork.knife")
                }

                NavigationLink(destination: EmergencyView()) {
                    Label("緊急聯絡", systemImage: "phone.fill")
                }
            }
            .navigationTitle("校園服務")
        }
    }
}

#Preview {
    CampusHubView()
}
