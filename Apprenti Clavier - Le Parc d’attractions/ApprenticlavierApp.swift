//
//  ApprenticlavierApp.swift
//  Apprenticlavier
//
//  Created by Aurélien on 28/07/2026.
//

import SwiftUI
import Foundation
import AppKit
import UniformTypeIdentifiers
import Sparkle

@MainActor
private final class SparkleUpdaterDelegate:
    NSObject,
    SPUUpdaterDelegate {

    func feedURLString(
        for updater: SPUUpdater
    ) -> String? {
        "https://raw.githubusercontent.com/Orel3713/Apprenti-Clavier-Le-Parc-d-attractions/main/appcast.xml"
    }
}


@MainActor
final class GestionnaireApparence {

    static func appliquer(
        _ valeur: String
    ) {
        switch valeur {
        case "clair":
            NSApp.appearance =
                NSAppearance(
                    named: .aqua
                )

        case "sombre":
            NSApp.appearance =
                NSAppearance(
                    named: .darkAqua
                )

        default:
            NSApp.appearance = nil
        }
    }
}

@MainActor
final class GestionnaireFenetresAuxiliaires {

    static let shared =
        GestionnaireFenetresAuxiliaires()

    private var fenetreAPropos: NSWindow?
    private var fenetreCentreAide: NSWindow?
    private var fenetreStatistiques: NSWindow?

    private init() {
    }

    func ouvrirAPropos() {
        if let fenetre = fenetreAPropos,
           fenetre.isVisible {
            afficherAuPremierPlan(fenetre)
            return
        }

        let contenu = AboutView()
            .environment(
                \.locale,
                Locale(identifier: "fr_FR")
            )

        let controleur =
            NSHostingController(rootView: contenu)

        let fenetre = NSWindow(
            contentViewController: controleur
        )

        fenetre.title =
            "À propos d’Apprenti Clavier - Le Parc d’attractions"
        fenetre.styleMask = [
            .titled,
            .closable
        ]
        fenetre.setContentSize(
            NSSize(width: 480, height: 560)
        )
        fenetre.isReleasedWhenClosed = false
        fenetre.isRestorable = false
        fenetre.center()

        fenetreAPropos = fenetre
        afficherAuPremierPlan(fenetre)
    }

    func ouvrirCentreAide() {
        if let fenetre = fenetreCentreAide,
           fenetre.isVisible {
            afficherAuPremierPlan(fenetre)
            return
        }

        let contenu = HelpCenterView()
            .environment(
                \.locale,
                Locale(identifier: "fr_FR")
            )

        let controleur =
            NSHostingController(rootView: contenu)

        let fenetre = NSWindow(
            contentViewController: controleur
        )

        fenetre.title = "Centre d’aide"
        fenetre.styleMask = [
            .titled,
            .closable,
            .resizable
        ]
        fenetre.setContentSize(
            NSSize(width: 560, height: 460)
        )
        fenetre.minSize =
            NSSize(width: 520, height: 420)
        fenetre.isReleasedWhenClosed = false
        fenetre.isRestorable = false
        fenetre.center()

        fenetreCentreAide = fenetre
        afficherAuPremierPlan(fenetre)
    }

    func ouvrirStatistiques() {
        if let fenetre = fenetreStatistiques,
           fenetre.isVisible {
            afficherAuPremierPlan(fenetre)
            return
        }

        let contenu = StatistiquesView()
            .environment(
                \.locale,
                Locale(identifier: "fr_FR")
            )

        let controleur =
            NSHostingController(rootView: contenu)

        let fenetre = NSWindow(
            contentViewController: controleur
        )

        fenetre.title = "Mes statistiques"
        fenetre.styleMask = [
            .titled,
            .closable,
            .resizable
        ]
        fenetre.setContentSize(
            NSSize(width: 680, height: 620)
        )
        fenetre.minSize =
            NSSize(width: 560, height: 460)
        fenetre.isReleasedWhenClosed = false
        fenetre.isRestorable = false
        fenetre.center()

        fenetreStatistiques = fenetre
        afficherAuPremierPlan(fenetre)
    }

    private func afficherAuPremierPlan(
        _ fenetre: NSWindow
    ) {
        NSApp.activate(ignoringOtherApps: true)
        fenetre.makeKeyAndOrderFront(nil)
    }
}

@main
struct ApprenticlavierApp: App {

    @StateObject private var progression =
        ProgressionManager.shared

    private let sparkleUpdaterDelegate: SparkleUpdaterDelegate
    private let updaterController: SPUStandardUpdaterController

    init() {
        let delegate = SparkleUpdaterDelegate()
        sparkleUpdaterDelegate = delegate
        updaterController =
            SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: delegate,
                userDriverDelegate: nil
            )

        UserDefaults.standard.set(
            false,
            forKey: "NSQuitAlwaysKeepsWindows"
        )

        let apparence =
            UserDefaults.standard.string(
                forKey: "apparenceApplication"
            ) ?? "automatique"

        DispatchQueue.main.async {
            GestionnaireApparence.appliquer(
                apparence
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: "fr_FR"))
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("À propos d’Apprenti Clavier - Le Parc d’attractions") {
                    GestionnaireFenetresAuxiliaires
                        .shared
                        .ouvrirAPropos()
                }
            }

            CommandGroup(after: .appSettings) {
                Button("Rechercher les mises à jour…") {
                    updaterController.checkForUpdates(nil)
                }
            }

            CommandGroup(replacing: .appTermination) {
                Button("Quitter Apprenti Clavier - Le Parc d’attractions") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }

            CommandGroup(replacing: .newItem) {
                Button("Importer un profil…") {
                    ouvrirPanneauImport()
                }

                Button("Exporter mon profil…") {
                    exporterProfilDansTelechargements()
                }
                .disabled(
                    progression.utilisateurActif == nil
                )
            }

            CommandMenu("Profil") {
                Button(
                    progression.utilisateurActif.map {
                        "Profil actuel : \($0)"
                    } ?? "Aucun profil sélectionné"
                ) {
                }
                .disabled(true)

                Divider()

                Button("Changer de profil…") {
                    progression.fermerSessionUtilisateur()

                    NSApp.activate(
                        ignoringOtherApps: true
                    )
                }
                .disabled(
                    progression.utilisateurActif == nil
                )

                Button("Mes statistiques") {
                    GestionnaireFenetresAuxiliaires
                        .shared
                        .ouvrirStatistiques()
                }
                .disabled(
                    progression.utilisateurActif == nil
                )
            }


            CommandMenu("Contact") {
                Button("Signaler un problème…") {
                    ouvrirCourrielDeContact(
                        objet: "Problème dans Apprenti Clavier - Le Parc d’attractions",
                        message:
                            "Bonjour,\n\n"
                            + "Je souhaite signaler un problème "
                            + "dans Apprenti Clavier - Le Parc d’attractions.\n\n"
                            + "Description :\n\n"
                            + "Version de macOS :\n\n"
                            + "VoiceOver utilisé : oui ou non\n"
                    )
                }

                Button("Proposer une amélioration…") {
                    ouvrirCourrielDeContact(
                        objet: "Suggestion pour Apprenti Clavier - Le Parc d’attractions",
                        message:
                            "Bonjour,\n\n"
                            + "Je souhaite proposer une amélioration "
                            + "pour Apprenti Clavier - Le Parc d’attractions.\n\n"
                            + "Suggestion :\n"
                    )
                }
            }

            CommandGroup(replacing: .help) {
                Button("Centre d’aide…") {
                    // Sur macOS Monterey, VoiceOver peut encore être en train
                    // d’interroger le menu Aide au moment de son activation.
                    // On laisse donc le menu se fermer avant de créer la fenêtre.
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 0.3
                    ) {
                        GestionnaireFenetresAuxiliaires
                            .shared
                            .ouvrirCentreAide()
                    }
                }
            }
        }

        Settings {
            ParametresView()
                .environment(\.locale, Locale(identifier: "fr_FR"))
        }
    }

    private func ouvrirCourrielDeContact(
        objet: String,
        message: String
    ) {
        var composants =
            URLComponents()

        composants.scheme = "mailto"
        composants.path =
            "contactdevapcb@gmail.com"

        composants.queryItems = [
            URLQueryItem(
                name: "subject",
                value: objet
            ),
            URLQueryItem(
                name: "body",
                value: message
            )
        ]

        guard let adresse =
                composants.url else {
            afficherAlerte(
                titre: "Contact impossible",
                message:
                    "Le message n’a pas pu être préparé."
            )
            return
        }

        NSWorkspace.shared.open(adresse)
    }

    private func exporterProfilDansTelechargements() {
        DispatchQueue.main.async {
            guard let utilisateur =
                progression.utilisateurActif else {
                afficherAlerte(
                    titre: "Exportation impossible",
                    message:
                        "Aucun utilisateur n’est sélectionné."
                )
                return
            }

            do {
                let donnees =
                    try progression.donneesDuProfilActif()

                let dossier =
                    try dossierTelechargements()

                let nomFichier =
                    nomDeFichierSecurise(utilisateur)
                    + "-Apprenti-Clavier-Parc-attractions.json"

                let adresse =
                    adresseDisponible(
                        dans: dossier,
                        nomFichier: nomFichier
                    )

                try donnees.write(
                    to: adresse,
                    options: .atomic
                )

                NSWorkspace.shared
                    .activateFileViewerSelecting(
                        [adresse]
                    )

                afficherAlerte(
                    titre: "Profil exporté",
                    message:
                        "Le profil \(utilisateur) "
                        + "a été exporté avec sa progression et ses statistiques "
                        + "du Parc dans le dossier Téléchargements. "
                        + "Le fichier est sélectionné dans le Finder."
                )
            } catch {
                afficherAlerte(
                    titre: "Exportation impossible",
                    message:
                        error.localizedDescription
                )
            }
        }
    }

    private func dossierTelechargements() throws -> URL {
        guard let dossier =
            FileManager.default.urls(
                for: .downloadsDirectory,
                in: .userDomainMask
            ).first else {
            throw NSError(
                domain: "ApprentiClavier",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Le dossier Téléchargements est introuvable."
                ]
            )
        }

        return dossier
    }

    private func adresseDisponible(
        dans dossier: URL,
        nomFichier: String
    ) -> URL {
        let gestionnaire =
            FileManager.default

        let nomSansExtension =
            (nomFichier as NSString)
                .deletingPathExtension

        let extensionFichier =
            (nomFichier as NSString)
                .pathExtension

        var adresse =
            dossier.appendingPathComponent(
                nomFichier,
                isDirectory: false
            )

        var numero = 2

        while gestionnaire.fileExists(
            atPath: adresse.path
        ) {
            let nouveauNom =
                "\(nomSansExtension)-\(numero).\(extensionFichier)"

            adresse =
                dossier.appendingPathComponent(
                    nouveauNom,
                    isDirectory: false
                )

            numero += 1
        }

        return adresse
    }

    private func ouvrirPanneauImport() {
        DispatchQueue.main.async {
            let panneau = NSOpenPanel()
            panneau.title =
                "Importer un profil"

            panneau.message =
                "Choisissez un fichier JSON de profil provenant "
                + "d’Apprenti Clavier ou du Parc d’attractions."

            panneau.prompt = "Importer"
            panneau.canChooseFiles = true
            panneau.canChooseDirectories = false
            panneau.allowsMultipleSelection = false
            panneau.allowedContentTypes = [.json]

            panneau.begin { reponse in
                guard reponse == .OK,
                      let adresse =
                        panneau.url else {
                    return
                }

                do {
                    let donnees =
                        try Data(
                            contentsOf: adresse
                        )

                    let nomImporte =
                        try progression
                            .importerProfil(
                                depuis: donnees
                            )

                    afficherAlerte(
                        titre: "Profil importé",
                        message:
                            "Le profil \(nomImporte) "
                            + "a été importé avec succès."
                    )
                } catch {
                    afficherAlerte(
                        titre:
                            "Importation impossible",
                        message:
                            error.localizedDescription
                    )
                }
            }
        }
    }

    private func afficherAlerte(
        titre: String,
        message: String
    ) {
        DispatchQueue.main.async {
            let alerte = NSAlert()
            alerte.messageText = titre
            alerte.informativeText = message
            alerte.alertStyle = .informational

            alerte.addButton(
                withTitle: "D’accord"
            )

            alerte.runModal()
        }
    }

    private func nomDeFichierSecurise(
        _ nom: String
    ) -> String {
        let caracteresInterdits =
            CharacterSet(
                charactersIn:
                    "/:\\?%*|\"<>"
            )

        let nomNettoye =
            nom.components(
                separatedBy:
                    caracteresInterdits
            )
            .joined(separator: "-")

        return nomNettoye.isEmpty
            ? "Profil"
            : nomNettoye
    }
}







