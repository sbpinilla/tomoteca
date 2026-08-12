//
//  Genre.swift
//  tomoteca
//

import Foundation

/// The closed list of genres a book can belong to. Exactly one per book.
///
/// Raw values are stable identifiers, never display text: they are what gets written to the
/// store, so renaming a genre in the UI must not touch them. `other` exists so that no book
/// can ever be impossible to file.
enum Genre: String, CaseIterable, Identifiable, Sendable {

    // Fiction
    case novel
    case scienceFiction = "science_fiction"
    case fantasy
    case horror
    case mysteryThriller = "mystery_thriller"
    case romance
    case historicalFiction = "historical_fiction"
    case adventure
    case poetry
    case theatre
    case comics
    case childrenAndYoungAdult = "children_young_adult"

    // Non-fiction
    case philosophy
    case history
    case biography
    case essay
    case science
    case psychology
    case personalDevelopment = "personal_development"
    case business
    case technology
    case health
    case art
    case travel
    case religion
    case cooking

    case other

    var id: String { rawValue }

    /// The two groups the picker splits the list into, so 27 options stay scannable.
    enum Section: CaseIterable, Identifiable {
        case fiction
        case nonFiction
        case other

        var id: Self { self }

        var genres: [Genre] {
            switch self {
            case .fiction:
                return [
                    .novel, .scienceFiction, .fantasy, .horror, .mysteryThriller, .romance,
                    .historicalFiction, .adventure, .poetry, .theatre, .comics,
                    .childrenAndYoungAdult,
                ]
            case .nonFiction:
                return [
                    .philosophy, .history, .biography, .essay, .science, .psychology,
                    .personalDevelopment, .business, .technology, .health, .art, .travel,
                    .religion, .cooking,
                ]
            case .other:
                return [.other]
            }
        }
    }
}
