//
//  EmergencyView.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI

struct EmergencyView: View {
    let emergencyContacts = [
        ("校安中心", "04-2219-5678"),
        ("健康中心", "04-2219-5679"),
        ("警衛室", "04-2219-5680"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("緊急聯絡電話")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(emergencyContacts, id: \.0) { name, phone in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.headline)
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: "-", with: ""))")!) {
                        Image(systemName: "phone.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(white: 0.95))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("緊急聯絡")
    }
}

#Preview {
    NavigationStack {
        EmergencyView()
    }
}
