//
//  MockData.swift
//  ButchakeMap
//
//  起動時に MockDataRepository へ入れる初期データ。永続化しないので、再起動のたびにこの内容に戻る。
//  投稿の中身（店名・コメント）は日本語のまま持つ。
//

import Foundation

nonisolated enum MockData {
    /// アプリを使う「自分」のニックネーム。認証が無いので固定にする
    static let currentUserName = "ぶっちゃけトラベラー"

    /// 初期の投稿（公開済み 5 件・自分の下書き 1 件）
    static func posts(now: Date = Date()) -> [Post] {
        [
            kanazawaSushi(now: now),
            disappointments(now: now),
            sapporoParfait(now: now),
            kyotoMorningWalk(now: now),
            yokohamaSunset(now: now),
            tokyoRetroCafeDraft(now: now)
        ]
    }

    private static let day: TimeInterval = 60 * 60 * 24

    private static func kanazawaSushi(now: Date) -> Post {
        Post(
            authorName: "金沢のすし好き",
            authorType: .local,
            title: "金沢市民が本気で教える三大回転寿司",
            prefecture: "石川県",
            city: "金沢市",
            category: .gourmet,
            spots: [
                Spot(
                    order: 1,
                    name: "すし食いねぇ！ 県庁前店",
                    address: "石川県金沢市西念",
                    latitude: 36.5832,
                    longitude: 136.6398,
                    recommendation: "ランチのコスパと鮮度は県内トップクラス。平日の開店直後なら待たずに入れる。"
                ),
                Spot(
                    order: 2,
                    name: "もりもり寿し 近江町店",
                    address: "石川県金沢市上近江町",
                    latitude: 36.5717,
                    longitude: 136.6565,
                    recommendation: "白えびとガスエビは絶対に頼んで。市場帰りの観光客で混むので夕方が狙い目。"
                ),
                Spot(
                    order: 3,
                    name: "金沢まいもん寿司 本店",
                    address: "石川県金沢市西念",
                    latitude: 36.5795,
                    longitude: 136.6437,
                    recommendation: "回転寿司なのに職人の握り。パリッとした海苔の軍艦は地元民も通う理由。"
                )
            ],
            likeCount: 128,
            starCount: 54,
            createdAt: now.addingTimeInterval(-1 * day)
        )
    }

    private static func disappointments(now: Date) -> Post {
        Post(
            authorName: "がっかり巡礼者",
            authorType: .traveler,
            title: "愛あるツッコミ！全国三大がっかり名所の真実",
            prefecture: "高知県",
            city: "高知市",
            category: .disappointment,
            spots: [
                Spot(
                    order: 1,
                    name: "はりまや橋",
                    address: "高知県高知市はりまや町",
                    latitude: 33.5611,
                    longitude: 133.5424,
                    recommendation: "実はすぐ横の公園に、復元された朱塗りの橋と記念館がある。そっちまで見て完成。"
                ),
                Spot(
                    order: 2,
                    name: "札幌市時計台",
                    address: "北海道札幌市中央区北1条西2丁目",
                    latitude: 43.0626,
                    longitude: 141.3536,
                    recommendation: "ビルに囲まれて小さく見えるけど、向かいのビルの 2 階テラスから撮ると絶景。"
                ),
                Spot(
                    order: 3,
                    name: "オランダ坂",
                    address: "長崎県長崎市東山手町",
                    latitude: 32.7392,
                    longitude: 129.8730,
                    recommendation: "坂そのものより、周りの洋館カフェとセットで楽しむのが正解。"
                )
            ],
            likeCount: 342,
            starCount: 97,
            createdAt: now.addingTimeInterval(-2 * day)
        )
    }

    private static func sapporoParfait(now: Date) -> Post {
        Post(
            authorName: "すすきの夜更かし部",
            authorType: .local,
            title: "札幌市民が夜中に通う三大シメパフェ",
            prefecture: "北海道",
            city: "札幌市",
            category: .gourmet,
            spots: [
                Spot(
                    order: 1,
                    name: "パフェ、珈琲、酒、佐藤",
                    address: "北海道札幌市中央区南2条西1丁目",
                    latitude: 43.0573,
                    longitude: 141.3545,
                    recommendation: "シメパフェ文化の代表格。季節のパフェは見た目も味も一軍。"
                ),
                Spot(
                    order: 2,
                    name: "パフェテリア パル",
                    address: "北海道札幌市中央区南4条西2丁目",
                    latitude: 43.0557,
                    longitude: 141.3530,
                    recommendation: "深夜まで開いていて、飲んだ後に駆け込める安心感。ナッツ系が絶品。"
                ),
                Spot(
                    order: 3,
                    name: "夜パフェ専門店 パフェテリア ベル",
                    address: "北海道札幌市中央区南5条西3丁目",
                    latitude: 43.0546,
                    longitude: 141.3522,
                    recommendation: "お酒と合わせるパフェという発想。カウンターで一人でも入りやすい。"
                )
            ],
            likeCount: 215,
            starCount: 88,
            createdAt: now.addingTimeInterval(-3 * day)
        )
    }

    private static func kyotoMorningWalk(now: Date) -> Post {
        Post(
            authorName: "京都通いの朝型",
            authorType: .repeater,
            title: "京都リピーターが選ぶ三大朝さんぽ",
            prefecture: "京都府",
            city: "京都市",
            category: .hiddenGem,
            spots: [
                Spot(
                    order: 1,
                    name: "伏見稲荷大社",
                    address: "京都府京都市伏見区深草藪之内町",
                    latitude: 34.9671,
                    longitude: 135.7727,
                    recommendation: "朝 7 時前の千本鳥居はほぼ貸し切り。昼の混雑がうそみたい。"
                ),
                Spot(
                    order: 2,
                    name: "哲学の道",
                    address: "京都府京都市左京区",
                    latitude: 35.0230,
                    longitude: 135.7945,
                    recommendation: "観光客が来る前の静けさが本番。途中の神社に寄り道するのが楽しい。"
                ),
                Spot(
                    order: 3,
                    name: "下鴨神社 糺の森",
                    address: "京都府京都市左京区下鴨泉川町",
                    latitude: 35.0390,
                    longitude: 135.7728,
                    recommendation: "朝の森の空気が別格。参拝の後は近くのパン屋で朝ごはん。"
                )
            ],
            likeCount: 76,
            starCount: 41,
            createdAt: now.addingTimeInterval(-5 * day)
        )
    }

    private static func yokohamaSunset(now: Date) -> Post {
        Post(
            authorName: currentUserName,
            authorType: .traveler,
            title: "旅好きが推す横浜の三大夕景スポット",
            prefecture: "神奈川県",
            city: "横浜市",
            category: .scenery,
            spots: [
                Spot(
                    order: 1,
                    name: "横浜港大さん橋国際客船ターミナル",
                    address: "神奈川県横浜市中区海岸通1丁目",
                    latitude: 35.4517,
                    longitude: 139.6476,
                    recommendation: "屋上の芝生デッキから、みなとみらいに沈む夕日を正面で見られる。"
                ),
                Spot(
                    order: 2,
                    name: "港の見える丘公園",
                    address: "神奈川県横浜市中区山手町",
                    latitude: 35.4381,
                    longitude: 139.6510,
                    recommendation: "ベイブリッジ側の夕焼けがきれい。バラの季節はさらに推せる。"
                ),
                Spot(
                    order: 3,
                    name: "横浜ランドマークタワー スカイガーデン",
                    address: "神奈川県横浜市西区みなとみらい2丁目",
                    latitude: 35.4547,
                    longitude: 139.6316,
                    recommendation: "晴れた日は富士山のシルエットまで見える。日没 30 分前に入るのがコツ。"
                )
            ],
            likeCount: 23,
            starCount: 9,
            createdAt: now.addingTimeInterval(-7 * day)
        )
    }

    private static func tokyoRetroCafeDraft(now: Date) -> Post {
        Post(
            authorName: currentUserName,
            authorType: .traveler,
            title: "東京の三大レトロ喫茶（書きかけ）",
            prefecture: "東京都",
            city: "台東区",
            category: .gourmet,
            spots: [
                Spot(
                    order: 1,
                    name: "上野の老舗喫茶",
                    address: "東京都台東区上野",
                    recommendation: "固めのプリンが最高。"
                ),
                Spot.empty(order: 2),
                Spot.empty(order: 3)
            ],
            likeCount: 0,
            starCount: 0,
            createdAt: now.addingTimeInterval(-1 * day / 2),
            isDraft: true
        )
    }
}
