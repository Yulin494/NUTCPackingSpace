//
//  AcademicCalendarView.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI

struct AcademicCalendarView: View {
    let events = AcademicCalendarData.events

    var body: some View {
        List(events) { event in
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                HStack {
                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(event.type.rawValue)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("學術行事曆")
    }
}

#Preview {
    NavigationStack {
        AcademicCalendarView()
    }
}
