//
//  StudyHubView.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI

struct StudyHubView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: ScheduleView()) {
                    Label("課表", systemImage: "calendar.badge.clock")
                }

                NavigationLink(destination: HomeworkView()) {
                    Label("作業追蹤", systemImage: "checklist")
                }
            }
            .navigationTitle("課業管理")
        }
    }
}

#Preview {
    StudyHubView()
}
