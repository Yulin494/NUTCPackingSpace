//
//  Restaurant.swift
//  NUTCParkingSpace
//
//  資料來源：育才街實際店家（台中科大正門前方）
//  營業時間如有變動請以 Google Maps 為準
//

import Foundation

struct Restaurant: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let address: String
    let hours: String
    let tags: [String]
    let note: String?
}

struct RestaurantData {
    static let restaurants: [Restaurant] = [
        Restaurant(
            name: "全方位自助餐",
            category: "自助餐",
            address: "育才街6巷3之2號",
            hours: "11:00-14:00, 17:00-20:00",
            tags: ["平價", "份量大", "學生首選"],
            note: "料多便宜，深受學生歡迎"
        ),
        Restaurant(
            name: "一中古早味便當",
            category: "便當",
            address: "育才街（上和園旁）",
            hours: "11:00-19:00",
            tags: ["平價", "台式"],
            note: "傳統台式便當，份量實在"
        ),
        Restaurant(
            name: "忠武飯捲",
            category: "韓式料理",
            address: "育才街6巷15號",
            hours: "11:00-21:00",
            tags: ["韓式", "平價"],
            note: "韓式飯捲、部隊鍋、烤肉"
        ),
        Restaurant(
            name: "阿田滷味",
            category: "滷味",
            address: "育才街31-27號",
            hours: "11:00-22:00",
            tags: ["老店", "滷味"],
            note: "六十年老店，人氣必吃"
        ),
        Restaurant(
            name: "上和園滷味",
            category: "滷味 / 冰品",
            address: "育才街4號",
            hours: "11:00-22:00",
            tags: ["滷味", "冰品"],
            note: "滷味與冰品皆有"
        ),
        Restaurant(
            name: "丁香深海旗魚串",
            category: "串燒 / 小吃",
            address: "育才街27之1號",
            hours: "11:00-21:00",
            tags: ["小吃", "旗魚串"],
            note: "特色旗魚串，校門口必吃"
        ),
        Restaurant(
            name: "一中豐仁冰",
            category: "冰品",
            address: "育才街3巷4-6號",
            hours: "10:00-22:00",
            tags: ["台中名產", "冰品"],
            note: "台中知名豐仁冰，一中正門口旁"
        ),
        Restaurant(
            name: "沐 Muweichai",
            category: "義大利麵 / 咖啡",
            address: "育才街3巷5號",
            hours: "10:00-20:00",
            tags: ["輕食", "咖啡", "貝果"],
            note: "義大利麵、貝果、調飲"
        ),
        Restaurant(
            name: "一中福州包",
            category: "包子 / 早餐",
            address: "育才街8-2號",
            hours: "07:00-19:00",
            tags: ["早餐", "包子"],
            note: "傳統福州包，早餐首選"
        ),
        Restaurant(
            name: "焼肉スマイル",
            category: "燒肉",
            address: "育才街3號1樓",
            hours: "11:30-21:30",
            tags: ["聚餐", "燒肉"],
            note: "平價燒肉，聚餐好去處"
        ),
        Restaurant(
            name: "老窗白糖粿",
            category: "點心 / 甜食",
            address: "育才街19號",
            hours: "11:00-22:00",
            tags: ["甜食", "紅豆餅"],
            note: "白糖粿、紅豆餅等傳統點心"
        ),
    ]
}
