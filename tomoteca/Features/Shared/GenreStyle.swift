//
//  GenreStyle.swift
//  tomoteca
//

import Foundation

/// The display name of each genre, translated through the string catalog.
///
/// Kept apart from `Genre` itself so the domain stays free of presentation concerns, and shared
/// across features because both the list and the form show genre names.
extension Genre {

    var title: LocalizedStringResource {
        switch self {
        case .novel: return .genreNovel
        case .scienceFiction: return .genreScienceFiction
        case .fantasy: return .genreFantasy
        case .horror: return .genreHorror
        case .mysteryThriller: return .genreMysteryThriller
        case .romance: return .genreRomance
        case .historicalFiction: return .genreHistoricalFiction
        case .adventure: return .genreAdventure
        case .poetry: return .genrePoetry
        case .theatre: return .genreTheatre
        case .comics: return .genreComics
        case .childrenAndYoungAdult: return .genreChildrenYoungAdult
        case .philosophy: return .genrePhilosophy
        case .history: return .genreHistory
        case .biography: return .genreBiography
        case .essay: return .genreEssay
        case .science: return .genreScience
        case .psychology: return .genrePsychology
        case .personalDevelopment: return .genrePersonalDevelopment
        case .business: return .genreBusiness
        case .technology: return .genreTechnology
        case .health: return .genreHealth
        case .art: return .genreArt
        case .travel: return .genreTravel
        case .religion: return .genreReligion
        case .cooking: return .genreCooking
        case .other: return .genreOther
        }
    }
}

extension Genre.Section {

    var title: LocalizedStringResource {
        switch self {
        case .fiction: return .genreSectionFiction
        case .nonFiction: return .genreSectionNonFiction
        case .other: return .genreSectionOther
        }
    }
}
