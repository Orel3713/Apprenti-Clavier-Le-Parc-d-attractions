//
//  VoiceOverAnnouncer.swift
//  Apprenti Clavier
//
//  Annonces VoiceOver centralisées.
//

import Foundation
import AppKit

enum VoiceOverAnnouncer {

    static func textePourPrononciation(
        _ texte: String
    ) -> String {
        texte
            .replacingOccurrences(
                of: "Rangée",
                with: "Rangé"
            )
            .replacingOccurrences(
                of: "rangée",
                with: "rangé"
            )
            .replacingOccurrences(
                of: "Triangle",
                with: "Triangueule"
            )
            .replacingOccurrences(
                of: "triangle",
                with: "triangueule"
            )
    }

    static func annoncerTexte(
        _ texte: String,
        apres delai: Double = 0
    ) {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delai
        ) {
            guard let fenetre = NSApp.mainWindow else {
                return
            }

            NSAccessibility.post(
                element: fenetre,
                notification: .announcementRequested,
                userInfo: [
                    .announcement:
                        textePourPrononciation(texte)
                ]
            )
        }
    }

    static func annoncerTexteRestant(
        _ texte: String,
        apres delai: Double = 0
    ) {
        guard AppSettings.shared.annoncerTexteRestant else {
            return
        }

        annoncerTexte(
            texte,
            apres: delai
        )
    }

    static func epeler(
        _ texte: String,
        apres delai: Double = 0
    ) {
        let texteEpele = texte
            .filter { caractere in
                caractere.isLetter
            }
            .uppercased()
            .map { caractere in
                String(caractere)
            }
            .joined(separator: ", ")

        annoncerTexte(
            texteEpele,
            apres: delai
        )
    }

    static func descriptionNaturelle(
        de phrase: String
    ) -> String {
        var resultat = phrase

        if let premiereLettre = phrase.first,
           String(premiereLettre) == String(premiereLettre).uppercased(),
           String(premiereLettre) != String(premiereLettre).lowercased() {
            resultat =
                "Première lettre en majuscule. "
                + phrase
        }

        if phrase.contains(",") {
            resultat += " Virgule."
        }

        if phrase.contains(".") {
            resultat += " Point."
        }

        if phrase.contains("!") {
            resultat += " Point d’exclamation."
        }

        if phrase.contains("?") {
            resultat += " Point d’interrogation."
        }

        return resultat
    }
}




