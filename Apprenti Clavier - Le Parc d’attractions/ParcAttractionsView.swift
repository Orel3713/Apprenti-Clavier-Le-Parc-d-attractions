//
//  ParcAttractionsView.swift
//  Apprenti Clavier
//

import SwiftUI
import Foundation

struct ParcAttractionsView: View {

    let nomUtilisateur: String

    @Environment(\.colorScheme)
    private var apparence

    @State private var generationOuverture = 0
    @State private var messageInformation = ""
    @State private var afficherDefiEclair = false
    @State private var afficherJeuDesBallons = false
    @State private var afficherDicteeAudio = false
    @State private var afficherGrandeRoue = false
    @State private var afficherSansFaute = false
    @State private var afficherSautGagnant = false

    @AccessibilityFocusState
    private var salutationEnFocus: Bool

    @ViewBuilder
    var body: some View {
        if afficherDefiEclair {
            DefiEclairView {
                afficherDefiEclair = false
            }
        } else if afficherJeuDesBallons {
            JeuDesBallonsView {
                afficherJeuDesBallons = false
            }
        } else if afficherDicteeAudio {
            DicteeAudioView {
                afficherDicteeAudio = false
            }
        } else if afficherGrandeRoue {
            LaGrandeRoueView {
                afficherGrandeRoue = false
            }
        } else if afficherSansFaute {
            SansFauteView {
                afficherSansFaute = false
            }
        } else if afficherSautGagnant {
            SautGagnantView {
                afficherSautGagnant = false
            }
        } else {
            accueilParc
        }
    }

    private var accueilParc: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Bonjour, \(nomUtilisateur)")
                        .font(.headline)
                        .accessibilityFocused($salutationEnFocus)

                    Spacer()
                }

                Text("Parc d’attractions")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)

                // Les attractions restent de vraies nacelles colorées.
                // L’ordre du code est aussi l’ordre VoiceOver : les jeux,
                // puis plus aucun élément accessible après le dernier bouton.
                HStack(spacing: 22) {
                    nacelle(
                        titre: "Défi éclair",
                        icone: .symbole("bolt.fill"),
                        couleur: couleurNacelle(pour: 0),
                        action: {
                            generationOuverture += 1
                            salutationEnFocus = false
                            afficherDefiEclair = true
                        }
                    )

                    nacelle(
                        titre: "Dictée audio",
                        icone: .symbole("headphones"),
                        couleur: couleurNacelle(pour: 1),
                        action: {
                            generationOuverture += 1
                            salutationEnFocus = false
                            afficherDicteeAudio = true
                        }
                    )

                    nacelle(
                        titre: "Jeu des Ballons",
                        icone: .ballons,
                        couleur: couleurNacelle(pour: 2),
                        action: {
                            generationOuverture += 1
                            salutationEnFocus = false
                            afficherJeuDesBallons = true
                        }
                    )

                    nacelle(
                        titre: "La Grande Roue",
                        icone: .grandeRoue,
                        couleur: couleurNacelle(pour: 3),
                        action: {
                            generationOuverture += 1
                            salutationEnFocus = false
                            afficherGrandeRoue = true
                        }
                    )

                    nacelle(
                        titre: "Sans faute",
                        icone: .symbole("target"),
                        couleur: couleurNacelle(pour: 5),
                        action: {
                            generationOuverture += 1
                            salutationEnFocus = false
                            afficherSansFaute = true
                        }
                    )

                    nacelle(
                        titre: "Le Saut gagnant",
                        icone: .sautGagnant,
                        couleur: couleurNacelle(pour: 4),
                        action: {
                            generationOuverture += 1
                            salutationEnFocus = false
                            afficherSautGagnant = true
                        }
                    )
                }
                .frame(maxWidth: .infinity)
                // La rangée vient légèrement devant la partie haute de la roue,
                // sans modifier l’ordre d’accessibilité.
                .padding(.bottom, -46)
                .zIndex(2)

                // Grande roue redevenue l’élément visuel principal du Parc.
                // Elle reste purement décorative pour VoiceOver.
                IconeGrandeRoue(detaillee: true)
                    .frame(width: 510, height: 510)
                    .accessibilityHidden(true)
                    .zIndex(1)

                if !messageInformation.isEmpty {
                    Text(messageInformation)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .accessibilityHidden(true)
                }
            }
            .padding(36)
        }
        .frame(minWidth: 1260, minHeight: 700)
        .background(
            arrierePlan
                .accessibilityHidden(true)
        )
        .onAppear {
            preparerOuverture()
        }
        .onDisappear {
            generationOuverture += 1
            salutationEnFocus = false

            GestionnaireSonsInterface.shared
                .arreterSonEnCours()
        }
    }

    private var arrierePlan: some View {
        ZStack(alignment: .bottom) {
            Group {
                if apparence == .dark {
                    LinearGradient(
                        colors: [
                            Color(red: 0.025, green: 0.075, blue: 0.16),
                            Color(red: 0.04, green: 0.13, blue: 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    LinearGradient(
                        colors: [
                            Color(red: 0.76, green: 0.90, blue: 1.0),
                            Color(red: 1.0, green: 0.96, blue: 0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }

            // Ligne d'horizon douce pour donner de la profondeur au parc.
            Ellipse()
                .fill(
                    apparence == .dark
                    ? Color(red: 0.08, green: 0.24, blue: 0.16)
                    : Color(red: 0.45, green: 0.72, blue: 0.35)
                )
                .frame(width: 1500, height: 230)
                .offset(y: 105)
                .accessibilityHidden(true)

            // Sol du parc. La grande roue vient visuellement s'y poser.
            Rectangle()
                .fill(
                    apparence == .dark
                    ? Color(red: 0.10, green: 0.20, blue: 0.13)
                    : Color(red: 0.53, green: 0.76, blue: 0.40)
                )
                .frame(height: 118)
                .accessibilityHidden(true)

            // Allée centrale, purement décorative.
            Path { chemin in
                chemin.move(to: CGPoint(x: 430, y: 118))
                chemin.addLine(to: CGPoint(x: 610, y: 118))
                chemin.addLine(to: CGPoint(x: 690, y: 0))
                chemin.addLine(to: CGPoint(x: 350, y: 0))
                chemin.closeSubpath()
            }
            .fill(
                apparence == .dark
                ? Color(red: 0.25, green: 0.25, blue: 0.24).opacity(0.75)
                : Color(red: 0.86, green: 0.76, blue: 0.57).opacity(0.85)
            )
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }

    private func nacelle(
        titre: String,
        icone: IconeJeuParc,
        couleur: Color,
        action: (() -> Void)? = nil
    ) -> some View {
        NacelleAttractionView(
            titre: titre,
            icone: icone,
            couleur: couleur
        ) {
            if let action {
                action()
            } else {
                annoncerJeuProchainement(titre)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titre)
        .accessibilityHint(
            action == nil
            ? "Ce jeu sera intégré prochainement."
            : "Ouvre ce jeu."
        )
    }

    // Palette inspirée des couleurs de la roue. Lorsqu’un nouveau jeu
    // est ajouté, utiliser l’index suivant pour obtenir automatiquement une
    // couleur différente, puis la palette recommence seulement après six jeux.
    private func couleurNacelle(pour index: Int) -> Color {
        let palette: [CouleurNacelle] = [
            .jaune,
            .verte,
            .orange,
            .bleue,
            .rouge,
            .violette
        ]

        return palette[index % palette.count].couleur
    }

    private func annoncerJeuProchainement(_ titre: String) {
        let message = titre + " sera disponible prochainement."
        messageInformation = message
        VoiceOverAnnouncer.annoncerTexte(message)
    }

    private func preparerOuverture() {
        generationOuverture += 1
        let generationDemandee = generationOuverture

        salutationEnFocus = false
        messageInformation = ""

        DispatchQueue.main.async {
            guard generationOuverture == generationDemandee else {
                return
            }

            salutationEnFocus = true
        }
    }


}

private enum CouleurNacelle {
    case rouge
    case verte
    case orange
    case bleue
    case jaune
    case violette

    var couleur: Color {
        switch self {
        case .rouge:
            return Color(red: 0.82, green: 0.13, blue: 0.15)
        case .verte:
            return Color(red: 0.16, green: 0.52, blue: 0.25)
        case .orange:
            return Color(red: 0.93, green: 0.39, blue: 0.06)
        case .bleue:
            return Color(red: 0.08, green: 0.34, blue: 0.69)
        case .jaune:
            return Color(red: 0.94, green: 0.61, blue: 0.05)
        case .violette:
            return Color(red: 0.43, green: 0.20, blue: 0.64)
        }
    }
}

private enum IconeJeuParc {
    case symbole(String)
    case ballons
    case grandeRoue
    case miroir
    case sautGagnant
}

private struct NacelleAttractionView: View {

    let titre: String
    let icone: IconeJeuParc
    let couleur: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(red: 1.0, green: 0.97, blue: 0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(couleur, lineWidth: 5)
                    )

                VStack(spacing: 8) {
                    toit

                    iconeAffichee
                        .frame(width: 48, height: 48)
                        .accessibilityHidden(true)

                    Text(titre)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(
                            Color(red: 0.04, green: 0.14, blue: 0.28)
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: 170)

                    Spacer(minLength: 4)

                    Rectangle()
                        .fill(couleur)
                        .frame(height: 6)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 9)
                }
            }
            .frame(width: 210, height: 156)
            .shadow(color: .black.opacity(0.20), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var toit: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(couleur)
                .frame(height: 34)

            HStack(spacing: 5) {
                ForEach(0..<6, id: \.self) { _ in
                    Circle()
                        .fill(couleur)
                        .frame(width: 20, height: 20)
                }
            }
            .offset(y: 14)
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private var iconeAffichee: some View {
        switch icone {
        case .symbole(let nom):
            Image(systemName: nom)
                .resizable()
                .scaledToFit()
                .foregroundStyle(couleur)

        case .ballons:
            IconeBouquetBallons(couleurPrincipale: couleur)

        case .grandeRoue:
            IconeGrandeRoue(detaillee: false)

        case .miroir:
            IconeMiroirDeforme(couleur: couleur)

        case .sautGagnant:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(couleur.opacity(0.35))
                    .frame(width: 42, height: 9)
                    .offset(y: 17)
                Image(systemName: "figure.run")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(couleur)
                    .frame(width: 32, height: 32)
                    .offset(x: 4, y: -5)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(couleur)
                    .offset(x: 20, y: 8)
            }
        }
    }
}

private struct IconeBouquetBallons: View {

    let couleurPrincipale: Color

    var body: some View {
        Canvas { contexte, taille in
            let couleurs: [Color] = [
                .red,
                .blue,
                .green,
                .yellow,
                couleurPrincipale
            ]
            let positions: [(CGFloat, CGFloat)] = [
                (0.18, 0.27),
                (0.38, 0.16),
                (0.58, 0.29),
                (0.78, 0.20),
                (0.49, 0.43)
            ]
            let pointMain = CGPoint(
                x: taille.width * 0.5,
                y: taille.height * 0.94
            )

            for index in positions.indices {
                let position = positions[index]
                let centre = CGPoint(
                    x: taille.width * position.0,
                    y: taille.height * position.1
                )

                var ficelle = Path()
                ficelle.move(
                    to: CGPoint(
                        x: centre.x,
                        y: centre.y + taille.height * 0.13
                    )
                )
                ficelle.addLine(to: pointMain)
                contexte.stroke(
                    ficelle,
                    with: .color(.secondary),
                    lineWidth: 1.2
                )

                let ballon = Path(
                    ellipseIn: CGRect(
                        x: centre.x - taille.width * 0.10,
                        y: centre.y - taille.height * 0.13,
                        width: taille.width * 0.20,
                        height: taille.height * 0.27
                    )
                )
                contexte.fill(ballon, with: .color(couleurs[index]))
            }

            let main = Path(
                roundedRect: CGRect(
                    x: taille.width * 0.42,
                    y: taille.height * 0.84,
                    width: taille.width * 0.16,
                    height: taille.height * 0.15
                ),
                cornerRadius: taille.width * 0.05
            )
            contexte.fill(
                main,
                with: .color(Color(red: 0.72, green: 0.45, blue: 0.28))
            )
        }
    }
}

private struct IconeMiroirDeforme: View {

    let couleur: Color

    var body: some View {
        Canvas { contexte, taille in
            var miroir = Path()
            miroir.move(to: CGPoint(x: taille.width * 0.28, y: 2))
            miroir.addCurve(
                to: CGPoint(x: taille.width * 0.72, y: 2),
                control1: CGPoint(x: taille.width * 0.38, y: 8),
                control2: CGPoint(x: taille.width * 0.62, y: -4)
            )
            miroir.addCurve(
                to: CGPoint(x: taille.width * 0.80, y: taille.height * 0.82),
                control1: CGPoint(x: taille.width * 0.90, y: taille.height * 0.20),
                control2: CGPoint(x: taille.width * 0.62, y: taille.height * 0.60)
            )
            miroir.addCurve(
                to: CGPoint(x: taille.width * 0.20, y: taille.height * 0.82),
                control1: CGPoint(x: taille.width * 0.62, y: taille.height),
                control2: CGPoint(x: taille.width * 0.38, y: taille.height * 0.70)
            )
            miroir.addCurve(
                to: CGPoint(x: taille.width * 0.28, y: 2),
                control1: CGPoint(x: taille.width * 0.08, y: taille.height * 0.55),
                control2: CGPoint(x: taille.width * 0.18, y: taille.height * 0.20)
            )

            contexte.fill(
                miroir,
                with: .linearGradient(
                    Gradient(colors: [.white, .cyan.opacity(0.55), .white]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: taille.width, y: taille.height)
                )
            )
            contexte.stroke(
                miroir,
                with: .color(couleur),
                lineWidth: 4
            )

            let pied = Path(
                roundedRect: CGRect(
                    x: taille.width * 0.36,
                    y: taille.height * 0.83,
                    width: taille.width * 0.28,
                    height: taille.height * 0.12
                ),
                cornerRadius: 3
            )
            contexte.fill(pied, with: .color(couleur))
        }
    }
}

