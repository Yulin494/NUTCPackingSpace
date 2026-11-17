//
//  FontLicenseView.swift
//  NUTCParkingSpace
//
//  開放原始碼授權：顯示 Cubic 11 的名稱、版本、授權與 OFL.txt 全文（從 bundle 讀取）。
//

import SwiftUI

struct FontLicenseView: View {
    private let licenseText: String = {
        guard let url = Bundle.main.url(forResource: "OFL", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "找不到授權檔 OFL.txt"
        }
        return text
    }()

    var body: some View {
        List {
            Section("字型") {
                LabeledContent("名稱", value: "俐方體 11 號（Cubic 11）")
                LabeledContent("版本", value: "1.500")
                LabeledContent("授權", value: "SIL Open Font License 1.1")
            }
            Section("授權全文") {
                Text(licenseText)
                    .font(.footnote)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("開放原始碼授權")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { FontLicenseView() }
}
