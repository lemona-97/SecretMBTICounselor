//
//  NotionService.swift
//  SecretMBTICounselor
//
//  Notion DB에서 신조어/단어 목록을 fetch해 AI 컨텍스트에 주입한다.
//  컬럼 구조: 줄임말(title, optional) | 원어(rich_text) | 설명(rich_text, optional)
//

import Foundation
import SwiftUI

struct NotionTerm: Codable, Equatable, Hashable {
    let abbreviation: String?   // 줄임말 (optional)
    let original: String        // 원어
    let description: String?    // 설명 (optional)

    /// Instructions에 주입할 한 줄 표현
    var instructionLine: String {
        var parts: [String] = []
        if let abbr = abbreviation { parts.append(abbr) }
        parts.append(original)
        if let desc = description, !desc.isEmpty {
            parts.append("(\(desc))")
        }
        return "- " + parts.joined(separator: " = ")
    }
}

private struct NotionTermsKey: EnvironmentKey {
    static let defaultValue: [NotionTerm] = []
}
extension EnvironmentValues {
    var notionTerms: [NotionTerm] {
        get { self[NotionTermsKey.self] }
        set { self[NotionTermsKey.self] = newValue }
    }
}

final class NotionService {
    static let shared = NotionService()

    private let token = "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"
    private let databaseID = "345670b83b1a8031825be2da9fceb8e3"
    private let notionVersion = "2022-06-28"
    private let lastFetchKey = "notionLastFetchDate"  // SettingsView @AppStorage key와 일치
    private let cachedTermsKey = "notionCachedTerms"

    private init() {}

    /// 앱 시작 시 하루 1회만 실제 API 호출, 결과는 캐시에 저장한다.
    func fetchTermsIfNeeded() async throws -> [NotionTerm] {
        let now = Date()
        let ts = UserDefaults.standard.double(forKey: lastFetchKey)
        let lastFetch = ts > 0 ? Date(timeIntervalSince1970: ts) : nil

        if let last = lastFetch, Calendar.current.isDate(last, inSameDayAs: now) {
            return cachedTerms()
        }

        let terms = try await fetchTerms()
        saveCachedTerms(terms)
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastFetchKey)
        return terms
    }

    func cachedTerms() -> [NotionTerm] {
        guard let data = UserDefaults.standard.data(forKey: cachedTermsKey) else { return [] }
        return (try? JSONDecoder().decode([NotionTerm].self, from: data)) ?? []
    }

    private func saveCachedTerms(_ terms: [NotionTerm]) {
        guard let data = try? JSONEncoder().encode(terms) else { return }
        UserDefaults.standard.set(data, forKey: cachedTermsKey)
    }

    func fetchTerms() async throws -> [NotionTerm] {
        let url = URL(string: "https://api.notion.com/v1/databases/\(databaseID)/query")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let results = json?["results"] as? [[String: Any]] ?? []

        print("[Notion] 총 \(results.count)개 페이지 응답")
        let terms = results.compactMap { page -> NotionTerm? in
            guard let props = page["properties"] as? [String: Any] else { return nil }

            // 원어 (필수)
            let original = richText(from: props["원어"])
            guard !original.isEmpty else { return nil }

            // 줄임말 (optional, title 타입)
            let abbreviation: String? = {
                guard let prop = props["줄임말"] as? [String: Any],
                      let titleArr = prop["title"] as? [[String: Any]],
                      let text = titleArr.first?["plain_text"] as? String,
                      !text.isEmpty else { return nil }
                return text
            }()

            // 설명 (optional)
            let description: String? = {
                let text = richText(from: props["설명"])
                return text.isEmpty ? nil : text
            }()

            return NotionTerm(abbreviation: abbreviation, original: original, description: description)
        }
        print("[Notion] 파싱된 NotionTerm: \(terms.count)개")
        if let first = terms.first { print("[Notion] 첫 항목: \(first.instructionLine)") }
        return terms
    }

    // MARK: - Helpers

    private func richText(from prop: Any?) -> String {
        guard let dict = prop as? [String: Any],
              let arr = dict["rich_text"] as? [[String: Any]] else { return "" }
        return arr.compactMap { $0["plain_text"] as? String }.joined()
    }
}
