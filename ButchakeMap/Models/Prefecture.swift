//
//  Prefecture.swift
//  ButchakeMap
//

import CoreLocation
import Foundation

/// 47 都道府県（JIS の都道府県コード順）。rawValue は Post.prefecture に入れる日本語の名前で、表示言語によらずそのまま出す
nonisolated enum Prefecture: String, CaseIterable, Identifiable, Sendable {
    case hokkaido = "北海道"
    case aomori = "青森県"
    case iwate = "岩手県"
    case miyagi = "宮城県"
    case akita = "秋田県"
    case yamagata = "山形県"
    case fukushima = "福島県"
    case ibaraki = "茨城県"
    case tochigi = "栃木県"
    case gunma = "群馬県"
    case saitama = "埼玉県"
    case chiba = "千葉県"
    case tokyo = "東京都"
    case kanagawa = "神奈川県"
    case niigata = "新潟県"
    case toyama = "富山県"
    case ishikawa = "石川県"
    case fukui = "福井県"
    case yamanashi = "山梨県"
    case nagano = "長野県"
    case gifu = "岐阜県"
    case shizuoka = "静岡県"
    case aichi = "愛知県"
    case mie = "三重県"
    case shiga = "滋賀県"
    case kyoto = "京都府"
    case osaka = "大阪府"
    case hyogo = "兵庫県"
    case nara = "奈良県"
    case wakayama = "和歌山県"
    case tottori = "鳥取県"
    case shimane = "島根県"
    case okayama = "岡山県"
    case hiroshima = "広島県"
    case yamaguchi = "山口県"
    case tokushima = "徳島県"
    case kagawa = "香川県"
    case ehime = "愛媛県"
    case kochi = "高知県"
    case fukuoka = "福岡県"
    case saga = "佐賀県"
    case nagasaki = "長崎県"
    case kumamoto = "熊本県"
    case oita = "大分県"
    case miyazaki = "宮崎県"
    case kagoshima = "鹿児島県"
    case okinawa = "沖縄県"

    var id: Self { self }

    /// 都道府県のローマ字（ヘボン式で長音の記号を付けない大文字。「都」「府」「県」は付けない）。
    /// 駅名標の英字の行に出す。表示言語によらず同じ英字で、翻訳しない（Discussion #77 の Q6）
    var romanizedName: String {
        switch self {
        case .hokkaido:
            "HOKKAIDO"
        case .aomori:
            "AOMORI"
        case .iwate:
            "IWATE"
        case .miyagi:
            "MIYAGI"
        case .akita:
            "AKITA"
        case .yamagata:
            "YAMAGATA"
        case .fukushima:
            "FUKUSHIMA"
        case .ibaraki:
            "IBARAKI"
        case .tochigi:
            "TOCHIGI"
        case .gunma:
            "GUNMA"
        case .saitama:
            "SAITAMA"
        case .chiba:
            "CHIBA"
        case .tokyo:
            "TOKYO"
        case .kanagawa:
            "KANAGAWA"
        case .niigata:
            "NIIGATA"
        case .toyama:
            "TOYAMA"
        case .ishikawa:
            "ISHIKAWA"
        case .fukui:
            "FUKUI"
        case .yamanashi:
            "YAMANASHI"
        case .nagano:
            "NAGANO"
        case .gifu:
            "GIFU"
        case .shizuoka:
            "SHIZUOKA"
        case .aichi:
            "AICHI"
        case .mie:
            "MIE"
        case .shiga:
            "SHIGA"
        case .kyoto:
            "KYOTO"
        case .osaka:
            "OSAKA"
        case .hyogo:
            "HYOGO"
        case .nara:
            "NARA"
        case .wakayama:
            "WAKAYAMA"
        case .tottori:
            "TOTTORI"
        case .shimane:
            "SHIMANE"
        case .okayama:
            "OKAYAMA"
        case .hiroshima:
            "HIROSHIMA"
        case .yamaguchi:
            "YAMAGUCHI"
        case .tokushima:
            "TOKUSHIMA"
        case .kagawa:
            "KAGAWA"
        case .ehime:
            "EHIME"
        case .kochi:
            "KOCHI"
        case .fukuoka:
            "FUKUOKA"
        case .saga:
            "SAGA"
        case .nagasaki:
            "NAGASAKI"
        case .kumamoto:
            "KUMAMOTO"
        case .oita:
            "OITA"
        case .miyazaki:
            "MIYAZAKI"
        case .kagoshima:
            "KAGOSHIMA"
        case .okinawa:
            "OKINAWA"
        }
    }

    /// 都道府県庁の所在地の座標。投稿作成で位置を選ぶ地図を、選んだ都道府県の辺りから始めるのに使う
    var capitalCoordinate: CLLocationCoordinate2D? {
        Self.capitalCoordinates[self].map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private static let capitalCoordinates: [Self: (latitude: Double, longitude: Double)] = [
        .hokkaido: (latitude: 43.0642, longitude: 141.3469),
        .aomori: (latitude: 40.8244, longitude: 140.7400),
        .iwate: (latitude: 39.7036, longitude: 141.1527),
        .miyagi: (latitude: 38.2688, longitude: 140.8721),
        .akita: (latitude: 39.7186, longitude: 140.1024),
        .yamagata: (latitude: 38.2404, longitude: 140.3633),
        .fukushima: (latitude: 37.7503, longitude: 140.4676),
        .ibaraki: (latitude: 36.3418, longitude: 140.4468),
        .tochigi: (latitude: 36.5657, longitude: 139.8836),
        .gunma: (latitude: 36.3912, longitude: 139.0608),
        .saitama: (latitude: 35.8570, longitude: 139.6489),
        .chiba: (latitude: 35.6051, longitude: 140.1233),
        .tokyo: (latitude: 35.6895, longitude: 139.6917),
        .kanagawa: (latitude: 35.4478, longitude: 139.6425),
        .niigata: (latitude: 37.9026, longitude: 139.0236),
        .toyama: (latitude: 36.6953, longitude: 137.2113),
        .ishikawa: (latitude: 36.5947, longitude: 136.6256),
        .fukui: (latitude: 36.0652, longitude: 136.2216),
        .yamanashi: (latitude: 35.6642, longitude: 138.5684),
        .nagano: (latitude: 36.6513, longitude: 138.1810),
        .gifu: (latitude: 35.3912, longitude: 136.7223),
        .shizuoka: (latitude: 34.9769, longitude: 138.3831),
        .aichi: (latitude: 35.1802, longitude: 136.9066),
        .mie: (latitude: 34.7303, longitude: 136.5086),
        .shiga: (latitude: 35.0045, longitude: 135.8686),
        .kyoto: (latitude: 35.0214, longitude: 135.7556),
        .osaka: (latitude: 34.6863, longitude: 135.5200),
        .hyogo: (latitude: 34.6913, longitude: 135.1830),
        .nara: (latitude: 34.6851, longitude: 135.8329),
        .wakayama: (latitude: 34.2260, longitude: 135.1675),
        .tottori: (latitude: 35.5039, longitude: 134.2377),
        .shimane: (latitude: 35.4723, longitude: 133.0505),
        .okayama: (latitude: 34.6618, longitude: 133.9344),
        .hiroshima: (latitude: 34.3966, longitude: 132.4596),
        .yamaguchi: (latitude: 34.1859, longitude: 131.4714),
        .tokushima: (latitude: 34.0658, longitude: 134.5593),
        .kagawa: (latitude: 34.3401, longitude: 134.0434),
        .ehime: (latitude: 33.8416, longitude: 132.7657),
        .kochi: (latitude: 33.5597, longitude: 133.5311),
        .fukuoka: (latitude: 33.6064, longitude: 130.4181),
        .saga: (latitude: 33.2494, longitude: 130.2988),
        .nagasaki: (latitude: 32.7448, longitude: 129.8737),
        .kumamoto: (latitude: 32.7898, longitude: 130.7417),
        .oita: (latitude: 33.2382, longitude: 131.6126),
        .miyazaki: (latitude: 31.9111, longitude: 131.4239),
        .kagoshima: (latitude: 31.5602, longitude: 130.5581),
        .okinawa: (latitude: 26.2124, longitude: 127.6809)
    ]
}
