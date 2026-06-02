import SwiftUI
import SwiftData
import UIKit
import NUTCParkingShared
import WidgetKit

struct HomeView: View {
    @Query(sort: \Course.weekday) var courses: [Course]
    @Query(sort: \HomeworkItem.dueDate) var homeworks: [HomeworkItem]
    @State private var weather: SharedWeatherData? = SharedWeatherCache.load()
    @State private var parkingLots: [ParkingLotData] = SharedParkingCache.load() ?? []

    private let periodTimes: [(Int, Int)] = [
        (8, 10), (9, 10), (10, 10), (11, 10), (12, 10), (13, 10), (14, 10),
        (15, 10), (16, 10), (17, 10), (18, 10), (19, 10), (20, 10), (21, 10)
    ]

    // 今天是 NUTC weekday (1=Mon..7=Sun)
    private var todayWeekday: Int {
        let w = Calendar.current.component(.weekday, from: Date())
        return w == 1 ? 7 : w - 1
    }

    private var todayCourses: [Course] {
        courses.filter { $0.weekday == todayWeekday }
               .sorted { $0.startPeriod < $1.startPeriod }
    }

    private var pendingHomework: [HomeworkItem] {
        let today = Calendar.current.startOfDay(for: Date())
        return homeworks.filter { !$0.isCompleted && $0.dueDate >= today }
                        .sorted { $0.dueDate < $1.dueDate }
                        .prefix(3).map { $0 }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "早安" }
        if h < 18 { return "午安" }
        return "晚安"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header greeting
                    headerSection

                    // Weather mini card
                    weatherSection

                    // Today's courses
                    if !courses.isEmpty {
                        todayCoursesSection
                    }

                    // Pending homework
                    if !pendingHomework.isEmpty {
                        homeworkSection
                    }

                    // Parking quick stats
                    if !parkingLots.isEmpty {
                        parkingSection
                    }

                    // Academic calendar shortcut
                    calendarSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting)，同學 \(greetingEmoji)")
                    .font(.largeTitle).bold()
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            NavigationLink(destination: AcademicCalendarView()) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .padding(10)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
            }
        }
        .padding(.top, 8)
    }

    private var greetingEmoji: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "☀️" }
        if h < 18 { return "🌤" }
        return "🌙"
    }

    // MARK: - Weather

    private var weatherSection: some View {
        NavigationLink(destination: WeatherView()) {
            ZStack(alignment: .topTrailing) {
                // 背景漸層
                LinearGradient(
                    colors: weatherGradientColors,
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )

                // 裝飾性大圓
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 160, height: 160)
                    .offset(x: 50, y: -50)

                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 100, height: 100)
                    .offset(x: 30, y: 60)

                if let w = weather {
                    filledWeatherCard(w)
                } else {
                    emptyWeatherCard
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: (weatherGradientColors.first ?? .blue).opacity(0.35), radius: 16, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func filledWeatherCard(_ w: SharedWeatherData) -> some View {
        VStack(spacing: 0) {
            // 頂部：地點
            HStack {
                Label("台中科大", systemImage: "location.fill")
                    .font(.caption).fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer()

            // 主要資訊
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(w.temperature.rounded()))°C")
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(w.description)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: w.symbolName)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.12), radius: 4)
            }
            .padding(.horizontal, 20)

            Spacer()

            // 底部 stats
            HStack(spacing: 0) {
                weatherStat(icon: "thermometer.medium", label: "體感", value: "\(Int(w.apparentTemperature.rounded()))°")
                Divider().frame(height: 18).background(.white.opacity(0.3))
                weatherStat(icon: "humidity", label: "濕度", value: "\(w.humidity)%")
                Divider().frame(height: 18).background(.white.opacity(0.3))
                weatherStat(icon: "wind", label: "風速", value: "\(Int(w.windSpeed)) km/h")
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
    }

    private func weatherStat(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.65))
                Text(value)
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyWeatherCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("台中天氣")
                    .font(.headline).fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("點擊查看即時天氣")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }
            Spacer()
            Image(systemName: "cloud.sun.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 52))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    private var weatherGradientColors: [Color] {
        guard let w = weather else {
            return [Color(red: 0.55, green: 0.65, blue: 0.80), Color(red: 0.40, green: 0.50, blue: 0.70)]
        }
        switch w.weatherCode {
        case 0, 1:    // 晴天
            let h = Calendar.current.component(.hour, from: Date())
            if h >= 6 && h < 18 {
                return [Color(red: 0.30, green: 0.60, blue: 0.95), Color(red: 0.15, green: 0.45, blue: 0.85)]
            } else {
                return [Color(red: 0.10, green: 0.12, blue: 0.35), Color(red: 0.20, green: 0.15, blue: 0.50)]
            }
        case 2, 3:    // 多雲
            return [Color(red: 0.45, green: 0.55, blue: 0.75), Color(red: 0.30, green: 0.40, blue: 0.65)]
        case 45...65: // 霧/雨
            return [Color(red: 0.35, green: 0.40, blue: 0.50), Color(red: 0.25, green: 0.30, blue: 0.42)]
        case 80...99: // 大雨
            return [Color(red: 0.20, green: 0.30, blue: 0.60), Color(red: 0.12, green: 0.18, blue: 0.45)]
        default:
            return [Color(red: 0.30, green: 0.55, blue: 0.90), Color(red: 0.20, green: 0.40, blue: 0.78)]
        }
    }

    // MARK: - Today Courses
    private var todayCoursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "今日課程",
                actionLabel: "完整課表",
                action: nil
            )

            if todayCourses.isEmpty {
                NUTCCard {
                    HStack {
                        Image(systemName: "sun.max.fill").foregroundColor(.yellow)
                        Text("今天沒有課，好好休息！").foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(todayCourses) { course in
                            homeCourseCard(course)
                        }
                    }
                }
            }
        }
    }

    private func homeCourseCard(_ course: Course) -> some View {
        let accent = Color(courseHex: course.color) ?? .blue
        let time = course.startPeriod >= 1 && course.startPeriod <= 14
            ? periodTimes[course.startPeriod - 1]
            : (0, 0)
        return VStack(alignment: .leading, spacing: 8) {
            Text(String(format: "%02d:%02d", time.0, time.1))
                .font(.caption2.monospacedDigit()).foregroundColor(accent)
            Text(course.name)
                .font(.headline).lineLimit(2)
            Spacer(minLength: 4)
            HStack(spacing: 4) {
                Image(systemName: "location.fill").font(.caption2)
                Text(course.room).font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 130, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.4), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: accent.opacity(0.15), radius: 8, y: 3)
    }

    // MARK: - Homework
    private var homeworkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "待辦作業")
            NUTCCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(pendingHomework.enumerated()), id: \.element.id) { i, hw in
                        homeHomeworkRow(hw)
                        if i < pendingHomework.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    private func homeHomeworkRow(_ hw: HomeworkItem) -> some View {
        let days = Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: hw.dueDate)).day ?? 0
        let urgency: Color = days == 0 ? .red : days <= 2 ? .orange : .primary

        return HStack(spacing: 14) {
            Circle()
                .fill(urgency.opacity(0.15))
                .overlay(Image(systemName: "circle").foregroundColor(urgency).font(.caption))
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(hw.title).font(.subheadline).fontWeight(.medium)
                Text(hw.courseName).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(days == 0 ? "今天" : days == 1 ? "明天" : "\(days) 天後")
                .font(.caption).fontWeight(.semibold).foregroundColor(urgency)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Parking
    private var parkingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "機車車位")
            let moto = Array(
                parkingLots
                    .filter { $0.type == .motorcycle }
                    .sorted { $0.availableCount > $1.availableCount }
                    .prefix(4)
            )
            HStack(spacing: 10) {
                ForEach(moto) { lot in
                    StatBadge(
                        value: "\(lot.availableCount)",
                        label: lot.name,
                        color: lot.availableCount > 20 ? .green
                             : lot.availableCount > 0  ? .orange : .red
                    )
                }
            }
        }
    }

    // MARK: - Calendar
    private var calendarSection: some View {
        NavigationLink(destination: AcademicCalendarView()) {
            let next = SharedAcademicCalendar.nextEvent()
            HStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text("學術行事曆").font(.subheadline).bold().foregroundColor(.primary)
                    if let event = next {
                        let days = SharedAcademicCalendar.daysUntil(event)
                        Text("\(event.title) · \(days == 0 ? "今天" : "\(days) 天後")")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}
