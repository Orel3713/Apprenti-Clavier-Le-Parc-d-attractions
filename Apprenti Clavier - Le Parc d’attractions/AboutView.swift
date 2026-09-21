import SwiftUI
import AppKit

struct AboutView: View {

    private enum CibleFocus: Hashable {
        case titre
    }

    @AccessibilityFocusState
    private var cibleFocus: CibleFocus?

    private let urlApprentiClavier = URL(
        string: "https://github.com/Orel3713/Apprenti-Clavier"
    )!
    private let urlVersionsApprentiClavier = URL(
        string: "https://github.com/Orel3713/Apprenti-Clavier/releases"
    )!
    private let urlParc = URL(
        string: "https://github.com/Orel3713/Apprenti-Clavier-Le-Parc-d-attractions"
    )!
    private let urlVersionsParc = URL(
        string: "https://github.com/Orel3713/Apprenti-Clavier-Le-Parc-d-attractions/releases"
    )!

    var body: some View {
        VStack(spacing: 12) {

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 112)
                .accessibilityLabel(
                    AppInfo.iconAccessibilityLabel
                )

            Text(AppInfo.name)
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused(
                    $cibleFocus,
                    equals: .titre
                )

            Text(
                "Version \(AppInfo.version), build \(AppInfo.build)"
            )
            .font(.headline)
            .accessibilityLabel(
                "Version \(AppInfo.version), build \(AppInfo.build)"
            )

            Text(
                "Développé par \(AppInfo.developer)"
            )

            Text(AppInfo.summary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 390)

            Text(AppInfo.accessibilityStatement)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(
                "Apprenti Clavier le Parc d’attractions est une application de jeux autour de la frappe au clavier, conçue pour prolonger l’expérience d’Apprenti Clavier dans un univers ludique et accessible. Elle propose différents jeux mettant à l’épreuve la rapidité, la précision et la maîtrise du clavier."
            )
            .font(.footnote)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 410)
            .foregroundStyle(.secondary)

            Text("© 2026 Aurélien Reffay")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityLabel(
                    "Copyright 2026 Aurélien Reffay"
                )

            Text(
                "Publié sous licence GNU GPL version 2."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(
                "Contact : contactdevapcb@gmail.com"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityLabel(
                "Contact, contact dev a p c b, arobase gmail point com"
            )

            VStack(spacing: 6) {
                LienRobuste(
                    titre: "Découvrir Apprenti Clavier",
                    destination: urlApprentiClavier,
                    aide:
                        "Ouvre le dépôt d’Apprenti Clavier dans votre navigateur"
                )
                .fixedSize()
                LienRobuste(
                    titre: "Découvrir Apprenti Clavier le Parc d’attractions",
                    destination: urlParc,
                    aide: "Ouvre le dépôt du Parc d’attractions dans votre navigateur"
                )
                .fixedSize()
                LienRobuste(
                    titre: "Télécharger les versions d’Apprenti Clavier",
                    destination: urlVersionsApprentiClavier,
                    aide: "Ouvre la page des versions d’Apprenti Clavier"
                )
                .fixedSize()
                LienRobuste(
                    titre: "Télécharger les versions d’Apprenti Clavier le Parc d’attractions",
                    destination: urlVersionsParc,
                    aide: "Ouvre la page des versions du Parc d’attractions"
                )
                .fixedSize()
            }

            Button("Fermer") {
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(28)
        .frame(width: 480)
        .fixedSize(
            horizontal: false,
            vertical: true
        )
        .onAppear {
            cibleFocus = nil

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.6
            ) {
                cibleFocus = .titre
            }
        }
        .onExitCommand {
            NSApp.keyWindow?.close()
        }
    }
}

private struct LienRobuste: NSViewRepresentable {

    let titre: String
    let destination: URL
    let aide: String

    func makeCoordinator() -> Coordinateur {
        Coordinateur(destination: destination)
    }

    func makeNSView(
        context: Context
    ) -> NSButton {
        let bouton = NSButton(
            title: titre,
            target: context.coordinator,
            action: #selector(Coordinateur.ouvrirLien)
        )

        configurer(bouton)
        return bouton
    }

    func updateNSView(
        _ bouton: NSButton,
        context: Context
    ) {
        context.coordinator.destination = destination
        configurer(bouton)
    }

    private func configurer(
        _ bouton: NSButton
    ) {
        bouton.title = titre
        bouton.isBordered = false
        bouton.bezelStyle = .inline
        bouton.font = NSFont.systemFont(
            ofSize: NSFont.systemFontSize
        )
        bouton.contentTintColor = .linkColor
        bouton.focusRingType = .default
        bouton.toolTip = aide

        bouton.setAccessibilityElement(true)
        bouton.setAccessibilityRole(.link)
        bouton.setAccessibilityRoleDescription("lien")
        bouton.setAccessibilityLabel("Lien, " + titre)
        bouton.setAccessibilityHelp(aide)
        bouton.setAccessibilityURL(destination)

        // Sur macOS Monterey, VoiceOver interroge la cellule interne
        // d’un NSButton plutôt que le bouton lui-même. Le rôle, le libellé
        // et l’adresse doivent donc aussi être appliqués à cette cellule.
        if let cellule = bouton.cell {
            cellule.setAccessibilityElement(true)
            cellule.setAccessibilityRole(.link)
            cellule.setAccessibilityRoleDescription("lien")
            cellule.setAccessibilityLabel("Lien, " + titre)
            cellule.setAccessibilityHelp(aide)
            cellule.setAccessibilityURL(destination)
        }
    }

    final class Coordinateur: NSObject {

        var destination: URL

        init(destination: URL) {
            self.destination = destination
        }

        @objc
        func ouvrirLien() {
            NSWorkspace.shared.open(destination)
        }
    }
}
