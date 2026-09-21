//
//  IconeGrandeRoue.swift
//  Apprenti Clavier
//

import SwiftUI
import Foundation

struct IconeGrandeRoue: View {

    var detaillee = false

    @Environment(\.colorScheme)
    private var apparence

    var body: some View {
        Canvas { contexte, taille in
            let cote = min(taille.width, taille.height)
            let echelle = cote / 100
            let decalageX = (taille.width - cote) / 2
            let decalageY = (taille.height - cote) / 2

            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(
                    x: decalageX + x * echelle,
                    y: decalageY + y * echelle
                )
            }

            func rectangle(
                x: CGFloat,
                y: CGFloat,
                largeur: CGFloat,
                hauteur: CGFloat
            ) -> CGRect {
                CGRect(
                    x: decalageX + x * echelle,
                    y: decalageY + y * echelle,
                    width: largeur * echelle,
                    height: hauteur * echelle
                )
            }

            func peinture(_ couleur: Color) -> GraphicsContext.Shading {
                .color(couleur)
            }

            let or = Color(red: 0.95, green: 0.66, blue: 0.13)
            let bleu = apparence == .dark
                ? Color(red: 0.12, green: 0.32, blue: 0.58)
                : Color(red: 0.19, green: 0.52, blue: 0.72)
            let metal = apparence == .dark
                ? Color(red: 0.82, green: 0.86, blue: 0.91)
                : Color(red: 0.56, green: 0.61, blue: 0.67)

            let couleursNacelles: [Color] = [
                Color(red: 0.86, green: 0.16, blue: 0.16),
                Color(red: 0.18, green: 0.58, blue: 0.28),
                Color(red: 0.94, green: 0.47, blue: 0.08),
                Color(red: 0.12, green: 0.40, blue: 0.76),
                Color(red: 0.95, green: 0.67, blue: 0.08),
                Color(red: 0.48, green: 0.23, blue: 0.68)
            ]

            let centre = point(50, 38)
            let rayon = 27 * echelle
            let epaisseurPrincipale = max(1.2, 2.5 * echelle)
            let epaisseurFine = max(0.8, 1.25 * echelle)

            let stylePrincipal = StrokeStyle(
                lineWidth: epaisseurPrincipale,
                lineCap: .round,
                lineJoin: .round
            )
            let styleFin = StrokeStyle(
                lineWidth: epaisseurFine,
                lineCap: .round,
                lineJoin: .round
            )

            let cercleExterieur = Path(
                ellipseIn: rectangle(
                    x: 23,
                    y: 11,
                    largeur: 54,
                    hauteur: 54
                )
            )
            contexte.stroke(
                cercleExterieur,
                with: peinture(or),
                style: stylePrincipal
            )

            let cercleInterieur = Path(
                ellipseIn: rectangle(
                    x: 26,
                    y: 14,
                    largeur: 48,
                    hauteur: 48
                )
            )
            contexte.stroke(
                cercleInterieur,
                with: peinture(bleu),
                style: styleFin
            )

            for index in 0..<8 {
                let angle = Double(index) * 2 * Double.pi / 8
                let extremite = CGPoint(
                    x: centre.x + CGFloat(cos(angle)) * rayon,
                    y: centre.y + CGFloat(sin(angle)) * rayon
                )

                var rayonTrace = Path()
                rayonTrace.move(to: centre)
                rayonTrace.addLine(to: extremite)
                contexte.stroke(
                    rayonTrace,
                    with: peinture(metal),
                    style: styleFin
                )
            }

            let moyeuExterieur = Path(
                ellipseIn: rectangle(
                    x: 44,
                    y: 32,
                    largeur: 12,
                    hauteur: 12
                )
            )
            contexte.fill(moyeuExterieur, with: peinture(or))

            let moyeuInterieur = Path(
                ellipseIn: rectangle(
                    x: 46,
                    y: 34,
                    largeur: 8,
                    hauteur: 8
                )
            )
            contexte.fill(moyeuInterieur, with: peinture(bleu))

            var piedsOr = Path()
            piedsOr.move(to: point(47, 42))
            piedsOr.addLine(to: point(30, 88))
            piedsOr.move(to: point(53, 42))
            piedsOr.addLine(to: point(70, 88))
            contexte.stroke(
                piedsOr,
                with: peinture(or),
                style: StrokeStyle(
                    lineWidth: max(2, 7 * echelle),
                    lineCap: .round,
                    lineJoin: .round
                )
            )

            var piedsBleus = Path()
            piedsBleus.move(to: point(47, 42))
            piedsBleus.addLine(to: point(30, 88))
            piedsBleus.move(to: point(53, 42))
            piedsBleus.addLine(to: point(70, 88))
            contexte.stroke(
                piedsBleus,
                with: peinture(bleu),
                style: StrokeStyle(
                    lineWidth: max(1.5, 4.8 * echelle),
                    lineCap: .round,
                    lineJoin: .round
                )
            )

            let base = Path(
                roundedRect: rectangle(
                    x: 22,
                    y: 85,
                    largeur: 56,
                    hauteur: 8
                ),
                cornerRadius: 3 * echelle
            )
            contexte.fill(base, with: peinture(bleu))
            contexte.stroke(base, with: peinture(or), style: styleFin)

            if detaillee {
                for index in 0..<12 {
                    let angle = Double(index) * 2 * Double.pi / 12
                    let position = CGPoint(
                        x: centre.x + CGFloat(cos(angle)) * rayon,
                        y: centre.y + CGFloat(sin(angle)) * rayon
                    )
                    let lumiere = Path(
                        ellipseIn: CGRect(
                            x: position.x - 1.2 * echelle,
                            y: position.y - 1.2 * echelle,
                            width: 2.4 * echelle,
                            height: 2.4 * echelle
                        )
                    )
                    contexte.fill(lumiere, with: peinture(or))
                }
            }

            for index in 0..<6 {
                let angle = -Double.pi / 2
                    + Double(index) * 2 * Double.pi / 6
                let pointRoue = CGPoint(
                    x: centre.x + CGFloat(cos(angle)) * rayon,
                    y: centre.y + CGFloat(sin(angle)) * rayon
                )
                let longueurSuspension: CGFloat = detaillee ? 5 : 3.5
                let pointSuspension = CGPoint(
                    x: pointRoue.x,
                    y: pointRoue.y + longueurSuspension * echelle
                )

                var suspension = Path()
                suspension.move(to: pointRoue)
                suspension.addLine(to: pointSuspension)
                contexte.stroke(
                    suspension,
                    with: peinture(or),
                    style: styleFin
                )

                let largeurCabine: CGFloat = detaillee ? 13 : 12
                let hauteurCabine: CGFloat = detaillee ? 10 : 8
                let cabine = CGRect(
                    x: pointSuspension.x - largeurCabine / 2 * echelle,
                    y: pointSuspension.y,
                    width: largeurCabine * echelle,
                    height: hauteurCabine * echelle
                )
                let nacelle = Path(
                    roundedRect: cabine,
                    cornerRadius: 2.5 * echelle
                )
                contexte.fill(
                    nacelle,
                    with: peinture(couleursNacelles[index])
                )
                contexte.stroke(
                    nacelle,
                    with: peinture(or),
                    style: styleFin
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

