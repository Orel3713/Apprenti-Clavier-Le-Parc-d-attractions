//
//  AppSettings.swift
//  Apprenti Clavier
//
//  Réglages partagés de l’application.
//

import Foundation
import Combine

final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    @Published var annoncerTexteRestant: Bool {
        didSet {
            UserDefaults.standard.set(
                annoncerTexteRestant,
                forKey: cleAnnonceTexteRestant
            )
        }
    }


    @Published var sonsExercicesActifs: Bool {
        didSet {
            UserDefaults.standard.set(
                sonsExercicesActifs,
                forKey: cleSonsExercices
            )
        }
    }

    @Published var delaiAnnonce: Double {
        didSet {
            UserDefaults.standard.set(
                delaiAnnonce,
                forKey: cleDelaiAnnonce
            )
        }
    }

    private let cleAnnonceTexteRestant =
        "annoncerTexteRestantVoiceOver"

    private let cleDelaiAnnonce =
        "delaiAnnonceVoiceOver"

    private let cleSonsExercices =
        "sonsExercicesActifs"

    private init() {
        let defaults =
            UserDefaults.standard

        if defaults.object(
            forKey: cleAnnonceTexteRestant
        ) == nil {
            annoncerTexteRestant = true
        } else {
            annoncerTexteRestant =
                defaults.bool(
                    forKey: cleAnnonceTexteRestant
                )
        }

        if defaults.object(
            forKey: cleSonsExercices
        ) == nil {
            sonsExercicesActifs = true
        } else {
            sonsExercicesActifs =
                defaults.bool(
                    forKey: cleSonsExercices
                )
        }

        let valeurSauvegardee =
            defaults.double(
                forKey: cleDelaiAnnonce
            )

        if valeurSauvegardee > 0 {
            delaiAnnonce =
                valeurSauvegardee
        } else {
            delaiAnnonce = 1.0
        }
    }
}


