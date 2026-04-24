//
//  FavoritesStore.swift
//  SecretMBTICounselor
//
//  "단짝" 상담사 관리. 단짝/기타 섹션의 순서를 UserDefaults에 영속.
//

import Foundation
import SwiftUI

@Observable
final class FavoritesStore {
    static let shared = FavoritesStore()

    private let bestiesKey = "bestiesOrder"
    private let othersKey = "othersOrder"

    var besties: [MBTIType] = []
    var others: [MBTIType] = []

    private init() {
        load()
    }

    // MARK: - Queries

    func isBestie(_ type: MBTIType) -> Bool {
        besties.contains(type)
    }

    var hasAnyBestie: Bool { !besties.isEmpty }

    // MARK: - Mutations

    /// 드롭 대상 타입 앞(또는 뒤)으로 이동
    func move(_ type: MBTIType, toBestiesBefore target: MBTIType?) {
        remove(type)
        if let target, let idx = besties.firstIndex(of: target) {
            besties.insert(type, at: idx)
        } else {
            besties.append(type)
        }
        persist()
    }

    func move(_ type: MBTIType, toOthersBefore target: MBTIType?) {
        remove(type)
        if let target, let idx = others.firstIndex(of: target) {
            others.insert(type, at: idx)
        } else {
            others.append(type)
        }
        persist()
    }

    /// 단짝 섹션 끝에 추가(또는 이동)
    func appendToBesties(_ type: MBTIType) {
        move(type, toBestiesBefore: nil)
    }

    /// 기타 섹션 끝에 추가(또는 이동)
    func appendToOthers(_ type: MBTIType) {
        move(type, toOthersBefore: nil)
    }

    // MARK: - Persistence

    private func remove(_ type: MBTIType) {
        besties.removeAll { $0 == type }
        others.removeAll { $0 == type }
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(besties.map(\.rawValue), forKey: bestiesKey)
        defaults.set(others.map(\.rawValue), forKey: othersKey)
    }

    private func load() {
        let defaults = UserDefaults.standard
        let bestieRaws = (defaults.array(forKey: bestiesKey) as? [String]) ?? []
        let otherRaws = (defaults.array(forKey: othersKey) as? [String]) ?? []

        besties = bestieRaws.compactMap { MBTIType(rawValue: $0) }
        others = otherRaws.compactMap { MBTIType(rawValue: $0) }

        // 누락된 MBTI는 기타 섹션 끝에 채워 넣기
        let existing = Set(besties + others)
        let missing = MBTIType.allCases.filter { !existing.contains($0) }
        if !missing.isEmpty {
            others.append(contentsOf: missing)
            persist()
        }
    }
}
