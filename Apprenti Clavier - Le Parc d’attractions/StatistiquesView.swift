import SwiftUI
import AppKit

struct StatistiquesView: View {
    @ObservedObject private var progression = ProgressionManager.shared
    @State private var messageExportation = ""
    @AccessibilityFocusState private var titreEnFocus: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Mes statistiques du Parc")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreEnFocus)

                Button("Exporter mes statistiques…") {
                    exporterStatistiques()
                }

                if let utilisateur = progression.utilisateurActif {
                    Text("Profil : \(utilisateur)")
                    Text("Parcours pédagogique Apprenti Clavier : terminé. Billet d’entrée validé.")

                    if !messageExportation.isEmpty {
                        Text(messageExportation)
                            .accessibilityLabel(messageExportation)
                    }

                    let stats = progression.statistiquesParc

                    Group {
                        Text("Vue d’ensemble")
                            .font(.title2)
                            .bold()
                            .accessibilityAddTraits(.isHeader)

                        Text("Jeux terminés : \(stats.jeuxTermines) sur 6.")
                        Text("Niveaux terminés : \(stats.niveauxTermines) sur 60.")
                        Text("Parties jouées : \(stats.partiesJouees).")
                        Text("Mots correctement saisis : \(stats.motsCorrects).")
                        Text("Erreurs de frappe : \(stats.erreursDeFrappe).")
                        Text("Précision moyenne : \(Int(stats.precisionMoyenne.rounded())) pour cent.")
                        Text("Vitesse moyenne : \(Int(stats.vitesseMoyenneMPM.rounded())) mots par minute.")
                        Text("Meilleure vitesse : \(Int(stats.meilleureVitesseMPM.rounded())) mots par minute.")
                    }

                    Text("Niveaux terminés par jeu")
                        .font(.title2)
                        .bold()
                        .accessibilityAddTraits(.isHeader)

                    ForEach(ProgressionManager.JeuParc.allCases) { jeu in
                        let termines = stats.statistiques(pour: jeu).niveauxTermines.count
                        Text("\(jeu.nom) : \(termines) sur 10.")
                    }
                } else {
                    Text("Aucun profil sélectionné.")
                }

                HStack {
                    Spacer()

                    Button("Fermer") {
                        fermerFenetre()
                    }
                    .keyboardShortcut("w", modifiers: .command)
                    .accessibilityLabel("Fermer")
                }
            }
            .padding(30)
            .frame(
                minWidth: 620,
                minHeight: 650,
                alignment: .topLeading
            )
        }
        .navigationTitle("Mes statistiques du Parc")
        .onAppear {
            titreEnFocus = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                titreEnFocus = true
            }
        }
        .onExitCommand {
            fermerFenetre()
        }
    }

    private func fermerFenetre() {
        NSApplication.shared.keyWindow?.performClose(nil)
    }

    private func exporterStatistiques() {
        guard let utilisateur = progression.utilisateurActif else {
            messageExportation =
                "Aucun profil actif. L’exportation est impossible."
            return
        }

        let stats = progression.statistiquesParc

        var lignes: [String] = [
            "Apprenti Clavier – Le Parc d’attractions – Mes statistiques",
            "",
            "Profil : \(utilisateur)",
            "Parcours pédagogique Apprenti Clavier : terminé. Billet d’entrée validé.",
            "",
            "Vue d’ensemble",
            "Jeux terminés : \(stats.jeuxTermines) sur 6.",
            "Niveaux terminés : \(stats.niveauxTermines) sur 60.",
            "Parties jouées : \(stats.partiesJouees).",
            "Mots correctement saisis : \(stats.motsCorrects).",
            "Erreurs de frappe : \(stats.erreursDeFrappe).",
            "Précision moyenne : \(Int(stats.precisionMoyenne.rounded())) pour cent.",
            "Vitesse moyenne : \(Int(stats.vitesseMoyenneMPM.rounded())) mots par minute.",
            "Meilleure vitesse : \(Int(stats.meilleureVitesseMPM.rounded())) mots par minute.",
            "",
            "Niveaux terminés par jeu"
        ]

        for jeu in ProgressionManager.JeuParc.allCases {
            let termines =
                stats.statistiques(pour: jeu).niveauxTermines.count

            lignes.append(
                "\(jeu.nom) : \(termines) sur 10."
            )
        }

        let contenu =
            lignes.joined(separator: "\n") + "\n"

        do {
            let dossier = try dossierTelechargements()

            let nomFichier =
                "Statistiques-"
                + nomDeFichierSecurise(utilisateur)
                + "-Apprenti-Clavier-Le-Parc-d-attractions.txt"

            let adresse =
                adresseDisponible(
                    dans: dossier,
                    nomFichier: nomFichier
                )

            try contenu.write(
                to: adresse,
                atomically: true,
                encoding: .utf8
            )

            NSWorkspace.shared
                .activateFileViewerSelecting([adresse])

            messageExportation =
                "Vos statistiques ont été exportées dans le dossier Téléchargements. "
                + "Le fichier est sélectionné dans le Finder."
        } catch {
            messageExportation =
                "L’exportation des statistiques a échoué : "
                + error.localizedDescription
        }
    }

    private func dossierTelechargements() throws -> URL {
        guard let dossier =
                FileManager.default.urls(
                    for: .downloadsDirectory,
                    in: .userDomainMask
                ).first else {
            throw NSError(
                domain: "ApprentiClavierParc",
                code: 2,
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
        let gestionnaire = FileManager.default

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

    private func nomDeFichierSecurise(
        _ nom: String
    ) -> String {
        let caracteresInterdits =
            CharacterSet(
                charactersIn: "/:\\?%*|\"<>"
            )

        return nom
            .components(
                separatedBy: caracteresInterdits
            )
            .joined(separator: "-")
            .replacingOccurrences(
                of: " ",
                with: "-"
            )
    }
}
