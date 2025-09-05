//
//  LinkTester.TestCase.swift
//  dreimetadaten
//
//  Created by YourMJK on 05.09.25.
//

extension LinkTester {
	struct TestCase {
		let valid: String
		let invalid: String
		
		static let all: [LinkType: Self] = [
			.cover_itunes: .init(
				valid:   "http://a1.mzstatic.com/us/r30/Music60/v4/24/bc/06/24bc0600-02b8-1f37-dc33-7a30f9634ebd/source",
				invalid: "http://a1.mzstatic.com/us/r30/Music60/v4/24/bc/06/24bc0600-02b8-1f37-dc33-7a30f9634ebe/source"
			),
			.cover_kosmos: .init(
				valid:   "http://web.archive.org/web/20220115135349if_/https://s3.eu-central-1.amazonaws.com/kosmos.de/media/image/a0/2a/de/0743218420627.jpg",
				invalid: "http://web.archive.org/web/20220115135349if_/https://s3.eu-central-1.amazonaws.com/kosmos.de/media/image/a0/2a/de/0743218420628.jpg"
			),
			.dreifragezeichen: .init(
				valid:   "https://dreifragezeichen.de/produktwelt/details/toteninsel",
				invalid: "https://dreifragezeichen.de/produktwelt/details/toteninsem"
			),
			.appleMusic: .init(
				valid:   "https://music.apple.com/de/album/1112996835",
				invalid: "https://music.apple.com/de/album/1112996836"
			),
			.spotify: .init(
				valid:   "https://open.spotify.com/intl-de/album/6zwBnyiy9Hy9TAser0DOuL",
				invalid: "https://open.spotify.com/intl-de/album/6zwBnyiy9Hy9TAser0DOuM"
			),
			.bookbeat: .init(
				valid:   "https://www.bookbeat.com/de/book/534766",
				invalid: "https://www.bookbeat.com/de/book/0"
			),
			.amazonMusic: .init(
				valid:   "https://music.amazon.de/albums/B01FIM4KKU",
				invalid: "https://music.amazon.de/albums/B01FIM4KKV"
			),
			.amazon: .init(
				valid:   "https://www.amazon.de/gp/product/B00005OBYS",
				invalid: "https://www.amazon.de/gp/product/B00005OBY"
			),
			.youTubeMusic: .init(
				valid:   "https://music.youtube.com/browse/MPREb_rTJZ10YuZau",
				invalid: "https://music.youtube.com/browse/MPREb_rTJZ10YuZav"
			),
			.deezer: .init(
				valid:   "https://www.deezer.com/de/album/13731970",
				invalid: "https://www.deezer.com/de/album/13731971"
			),
		]
	}
}
