//
//  SharedLogicTests.swift
//  NUTCParkingSharedTests
//
//  純邏輯單元測試:確定性、零網路、零 I/O,適合在 CI 上以 `swift test` 快速執行。
//  使用 Swift Testing(`import Testing`),可在僅有 Command Line Tools 的環境跑。
//  對應原始碼:NUTCParkingShared/Sources/NUTCParkingShared/Models/*
//

import Testing
import Foundation
@testable import NUTCParkingShared

// MARK: - 天氣代碼對應(WMO weather code → 中文描述 / SF Symbol)

@Suite struct SharedWeatherDataTests {

    @Test func descriptionDiscreteCases() {
        #expect(SharedWeatherData.weatherDescription(for: 0) == "晴天")
        #expect(SharedWeatherData.weatherDescription(for: 1) == "大致晴朗")
        #expect(SharedWeatherData.weatherDescription(for: 2) == "局部多雲")
        #expect(SharedWeatherData.weatherDescription(for: 3) == "陰天")
        #expect(SharedWeatherData.weatherDescription(for: 45) == "霧")
        #expect(SharedWeatherData.weatherDescription(for: 48) == "霧")
        #expect(SharedWeatherData.weatherDescription(for: 51) == "毛毛雨")
        #expect(SharedWeatherData.weatherDescription(for: 53) == "毛毛雨")
        #expect(SharedWeatherData.weatherDescription(for: 55) == "濃毛毛雨")
        #expect(SharedWeatherData.weatherDescription(for: 61) == "降雨")
        #expect(SharedWeatherData.weatherDescription(for: 65) == "大雨")
        #expect(SharedWeatherData.weatherDescription(for: 71) == "降雪")
        #expect(SharedWeatherData.weatherDescription(for: 75) == "大雪")
        #expect(SharedWeatherData.weatherDescription(for: 80) == "陣雨")
        #expect(SharedWeatherData.weatherDescription(for: 82) == "強陣雨")
        #expect(SharedWeatherData.weatherDescription(for: 95) == "雷暴")
        #expect(SharedWeatherData.weatherDescription(for: 96) == "冰雹雷暴")
        #expect(SharedWeatherData.weatherDescription(for: 99) == "冰雹雷暴")
    }

    @Test func descriptionDefaultFallback() {
        // description 用「離散 case」,未列出的碼一律落到 default「多雲」
        #expect(SharedWeatherData.weatherDescription(for: 52) == "多雲")   // 51、53 才是毛毛雨
        #expect(SharedWeatherData.weatherDescription(for: 97) == "多雲")   // 只有 96、99 是冰雹雷暴
        #expect(SharedWeatherData.weatherDescription(for: 100) == "多雲")
        #expect(SharedWeatherData.weatherDescription(for: -1) == "多雲")
    }

    @Test func symbolRangeCases() {
        #expect(SharedWeatherData.weatherSymbol(for: 0) == "sun.max.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 1) == "sun.haze.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 2) == "cloud.sun.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 3) == "cloud.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 45) == "cloud.fog.fill")
        // symbol 用「範圍」:51...55 全部是 drizzle
        #expect(SharedWeatherData.weatherSymbol(for: 51) == "cloud.drizzle.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 52) == "cloud.drizzle.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 55) == "cloud.drizzle.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 61) == "cloud.rain.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 65) == "cloud.rain.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 71) == "cloud.snow.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 77) == "cloud.snow.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 80) == "cloud.heavyrain.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 82) == "cloud.heavyrain.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 85) == "cloud.snow.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 95) == "cloud.bolt.rain.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 99) == "cloud.bolt.rain.fill")
        #expect(SharedWeatherData.weatherSymbol(for: 100) == "cloud.fill")   // default
    }

    @Test func descriptionAndSymbolCanDiverge() {
        // 同一個碼,description 用離散、symbol 用範圍,可能給出「不一致」的結果。
        // 這是刻意記錄現況行為(characterization),避免日後改動悄悄改變語意。
        #expect(SharedWeatherData.weatherDescription(for: 52) == "多雲")
        #expect(SharedWeatherData.weatherSymbol(for: 52) == "cloud.drizzle.fill")

        #expect(SharedWeatherData.weatherDescription(for: 85) == "多雲")
        #expect(SharedWeatherData.weatherSymbol(for: 85) == "cloud.snow.fill")
    }

    @Test func instanceComputedPropertiesDelegateToStatic() {
        let w = SharedWeatherData(
            temperature: 25, apparentTemperature: 26, humidity: 60, windSpeed: 3,
            weatherCode: 65, fetchedAt: Date(timeIntervalSince1970: 0),
            hourlyTemps: [], hourlyCodes: [], hourlyHours: []
        )
        #expect(w.description == "大雨")
        #expect(w.symbolName == "cloud.rain.fill")
    }

    @Test func codableRoundTrip() throws {
        let w = SharedWeatherData(
            temperature: 25.5, apparentTemperature: 27.1, humidity: 72, windSpeed: 4.2,
            weatherCode: 3, fetchedAt: Date(timeIntervalSince1970: 1_700_000_000),
            hourlyTemps: [25, 26, 27], hourlyCodes: [0, 1, 2], hourlyHours: [8, 9, 10]
        )
        let decoded = try JSONDecoder().decode(
            SharedWeatherData.self, from: JSONEncoder().encode(w)
        )
        #expect(abs(decoded.temperature - w.temperature) < 1e-9)
        #expect(decoded.weatherCode == w.weatherCode)
        #expect(decoded.hourlyCodes == w.hourlyCodes)
        #expect(decoded.hourlyHours == w.hourlyHours)
    }
}

// MARK: - 學曆事件(下一個事件 / 距今天數)

@Suite struct SharedAcademicCalendarTests {

    @Test func eventsAreSortedAscending() {
        let dates = SharedAcademicCalendar.events.map { $0.date }
        #expect(!dates.isEmpty)
        #expect(dates == dates.sorted())   // 應已依日期由早到晚排序
    }

    @Test func nextEventDistantPastReturnsFirst() {
        let next = SharedAcademicCalendar.nextEvent(from: .distantPast)
        #expect(next?.date == SharedAcademicCalendar.events.first?.date)
        #expect(next?.title == SharedAcademicCalendar.events.first?.title)
    }

    @Test func nextEventDistantFutureReturnsNil() {
        #expect(SharedAcademicCalendar.nextEvent(from: .distantFuture) == nil)
    }

    @Test func nextEventBoundaryIncludesSameDay() throws {
        // nextEvent 用 `>=`(startOfDay 比較),所以「當天」也算下一個事件
        let firstDate = try #require(SharedAcademicCalendar.events.first).date
        #expect(SharedAcademicCalendar.nextEvent(from: firstDate)?.date == firstDate)
    }

    @Test func daysUntilSameDayIsZero() throws {
        let cal = Calendar.current
        let now = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        let event = SharedAcademicEvent(title: "t", date: now, type: "考試")
        #expect(SharedAcademicCalendar.daysUntil(event, from: now) == 0)
    }

    @Test func daysUntilFutureCountsCalendarDays() throws {
        let cal = Calendar.current
        let now = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        let plus7 = try #require(cal.date(byAdding: .day, value: 7, to: now))
        let event = SharedAcademicEvent(title: "t", date: plus7, type: "考試")
        #expect(SharedAcademicCalendar.daysUntil(event, from: now) == 7)
    }

    @Test func daysUntilPastClampedToZero() throws {
        let cal = Calendar.current
        let now = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        let minus3 = try #require(cal.date(byAdding: .day, value: -3, to: now))
        let event = SharedAcademicEvent(title: "t", date: minus3, type: "放假")
        #expect(SharedAcademicCalendar.daysUntil(event, from: now) == 0)   // 過去事件 clamp 成 0
    }
}

// MARK: - 課程節次 → 上課時間

@Suite struct SharedCourseTests {

    private func course(period: Int) -> SharedCourse {
        SharedCourse(id: "1", name: "n", instructor: "i", room: "r",
                     weekday: 1, startPeriod: period, endPeriod: period, color: "#000000")
    }

    @Test func startTimeValidPeriods() {
        #expect(course(period: 1).startTime?.hour == 8)
        #expect(course(period: 1).startTime?.minute == 10)
        #expect(course(period: 5).startTime?.hour == 12)    // 第 5 節 → 12:10
        #expect(course(period: 14).startTime?.hour == 21)   // 第 14 節 → 21:10
        #expect(course(period: 14).startTime?.minute == 10)
    }

    @Test func startTimeOutOfRangeIsNil() {
        #expect(course(period: 0).startTime == nil)
        #expect(course(period: 15).startTime == nil)
        #expect(course(period: -1).startTime == nil)
    }

    @Test func periodStartTimesHas14Entries() {
        #expect(SharedCourse.periodStartTimes.count == 14)
    }
}

// MARK: - 停車場資料模型(enum raw value / Codable)

@Suite struct ParkingLotDataTests {

    @Test func parkingTypeRawValues() {
        #expect(ParkingType.motorcycle.rawValue == "機車停車場")
        #expect(ParkingType.car.rawValue == "汽車停車場")
        #expect(ParkingType(rawValue: "汽車停車場") == .car)
        #expect(ParkingType(rawValue: "腳踏車") == nil)
        #expect(ParkingType.allCases.count == 2)
    }

    @Test func parkingLotDataCodableRoundTrip() throws {
        let original = ParkingLotData(
            name: "第一停車場", totalCapacity: 100, availableCount: 40,
            latitude: 24.149691, longitude: 120.683974,
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000), type: .car
        )
        let decoded = try JSONDecoder().decode(
            ParkingLotData.self, from: JSONEncoder().encode(original)
        )
        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.totalCapacity == original.totalCapacity)
        #expect(decoded.availableCount == original.availableCount)
        #expect(abs(decoded.latitude - original.latitude) < 1e-9)
        #expect(abs(decoded.longitude - original.longitude) < 1e-9)
        #expect(abs(decoded.lastUpdated.timeIntervalSince1970
                    - original.lastUpdated.timeIntervalSince1970) < 0.001)
        #expect(decoded.type == original.type)
    }
}

// MARK: - LiteLot(Codable / Hashable / Equatable)

@Suite struct LiteLotTests {

    @Test func codableRoundTrip() throws {
        let lot = LiteLot(name: "機車A", available: 5, total: 10)
        let decoded = try JSONDecoder().decode(LiteLot.self, from: JSONEncoder().encode(lot))
        #expect(decoded == lot)
    }

    @Test func equatableAndHashable() {
        let a = LiteLot(name: "機車A", available: 5, total: 10)
        let b = LiteLot(name: "機車A", available: 5, total: 10)
        let c = LiteLot(name: "機車A", available: 6, total: 10)
        #expect(a == b)
        #expect(a != c)
        #expect(Set([a, b, c]).count == 2)   // a 與 b 相等,Set 內應只剩 2 個
    }
}
