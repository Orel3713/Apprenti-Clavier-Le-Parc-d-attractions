//
//  AccueilView.swift
//  Apprenti Clavier - Le Parc d’attractions
//

import SwiftUI
import AppKit

struct AccueilView: View {
    @ObservedObject private var progression = ProgressionManager.shared
    @AccessibilityFocusState private var titreAccueilEnFocus: Bool
    @AccessibilityFocusState private var descriptionAccueilEnFocus: Bool

    private var descriptionAccueil: String {
        switch progression.profilsUtilisateurs.count {
        case 0:
            return "Bienvenue dans Apprenti Clavier - Le Parc d’attractions. "
                + "Cette application vous permet de poursuivre votre entraînement au clavier à travers différents jeux accessibles avec VoiceOver. "
                + "Pour entrer dans le Parc, importez un profil exporté depuis Apprenti Clavier après avoir terminé les quatorze modules pédagogiques."
        case 1:
            return "Bravo, votre billet pour le Parc est validé ! "
                + "Les portes du Parc vous sont ouvertes."
        default:
            return "Bravo, vos billets pour le Parc sont validés ! "
                + "Les portes du Parc vous sont ouvertes."
        }
    }

    var body: some View {
        Group {
            if let utilisateur = progression.utilisateurActif {
                ParcAttractionsView(
                    nomUtilisateur: utilisateur
                )
            } else {
                contenuAccueil
            }
        }
        .onAppear {
            preparerFocusAccueilSiNecessaire()
        }
        .onReceive(progression.$utilisateurActif) { _ in
            preparerFocusAccueilSiNecessaire()
        }
        .onChange(of: progression.profilsUtilisateurs.count) { nouveauNombre in
            guard progression.utilisateurActif == nil,
                  nouveauNombre > 0 else {
                return
            }

            titreAccueilEnFocus = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard progression.utilisateurActif == nil else {
                    return
                }

                descriptionAccueilEnFocus = true
            }
        }
    }

    private var contenuAccueil: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Apprenti Clavier - Le Parc d’attractions")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreAccueilEnFocus)

                Text(descriptionAccueil)
                    .accessibilityLabel(descriptionAccueil)
                    .accessibilityFocused($descriptionAccueilEnFocus)

                if progression.profilsUtilisateurs.isEmpty {
                    GroupBox("Votre billet d’entrée") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Aucun profil admis au Parc n’est encore enregistré sur ce Mac.")
                            Text("Dans Apprenti Clavier, terminez les 14 modules, exportez votre profil depuis le menu Fichier, puis choisissez « Importer un profil… » dans le menu Fichier de cette application.")
                        }
                        .padding(.vertical, 6)
                    }
                } else {
                    Text("Choisissez un utilisateur")
                        .font(.title2)
                        .bold()
                        .accessibilityAddTraits(.isHeader)

                    ForEach(progression.profilsUtilisateurs, id: \.self) { profil in
                        Button {
                            titreAccueilEnFocus = false
                            progression.activerUtilisateur(profil)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "ticket.fill")
                                    .accessibilityHidden(true)
                                Text("Entrer dans le Parc avec \(profil)")
                            }
                        }
                        .accessibilityLabel("Entrer dans le Parc avec \(profil)")
                    }

                    Divider()

                    Text("Pour ajouter un autre utilisateur, importez son profil Apprenti Clavier depuis le menu Fichier.")
                }

                Spacer(minLength: 30)
            }
            .padding(40)
            .frame(
                minWidth: 700,
                minHeight: 520,
                alignment: .topLeading
            )
        }
    }

    private func preparerFocusAccueilSiNecessaire() {
        guard progression.utilisateurActif == nil else {
            titreAccueilEnFocus = false
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard progression.utilisateurActif == nil else {
                return
            }

            descriptionAccueilEnFocus = false
            titreAccueilEnFocus = true
        }
    }
}
