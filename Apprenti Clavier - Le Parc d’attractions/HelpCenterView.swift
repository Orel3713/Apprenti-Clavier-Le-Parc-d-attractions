import SwiftUI
import AppKit

/// Centre d’aide volontairement basé sur les API AppKit disponibles depuis
/// macOS Monterey. Les documents validés sont inclus dans l’application et
/// ouverts avec l’application macOS associée au type de fichier (Aperçu pour
/// les PDF dans une installation standard). Cette approche évite de dépendre
/// d’API SwiftUI de gestion de fenêtres apparues après Monterey.
struct HelpCenterView: View {
    @AccessibilityFocusState private var titreEnFocus: Bool
    @State private var messageErreur: String?
    @State private var moniteurEchap: Any?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Centre d’aide")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreEnFocus)

                Text("Sélectionnez un document pour l’ouvrir. Les documents sont fournis avec l’application et restent disponibles hors connexion.")
                    .fixedSize(horizontal: false, vertical: true)

                GroupBox("Documentation") {
                    VStack(alignment: .leading, spacing: 12) {
                        boutonDocument(
                            titre: "Guide utilisateur",
                            description: "Installation, interface, jeux, réglages, raccourcis clavier et dépannage.",
                            ressource: "Guide_Utilisateur_Apprenti_Clavier_Le_Parc_d_attractions",
                            extensionFichier: "pdf"
                        )

                        Divider()

                        boutonDocument(
                            titre: "Notes de version",
                            description: "Nouveautés, améliorations et corrections de la version installée.",
                            ressource: "NOTES_DE_VERSION",
                            extensionFichier: "pdf"
                        )

                        Divider()

                        boutonDocument(
                            titre: "Remerciements",
                            description: "Personnes et contributions remerciées dans le cadre du projet.",
                            ressource: "REMERCIEMENTS",
                            extensionFichier: "pdf"
                        )
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Textes de licence") {
                    VStack(alignment: .leading, spacing: 12) {
                        boutonDocument(
                            titre: "Licence GNU GPL v2 — français",
                            description: "Traduction française du texte de la licence.",
                            ressource: "gpl-fr",
                            extensionFichier: "txt"
                        )

                        Divider()

                        boutonDocument(
                            titre: "Licence GNU GPL v2 — texte original",
                            description: "Texte original anglais de la licence GNU GPL v2.",
                            ressource: "gpl",
                            extensionFichier: "txt"
                        )
                    }
                    .padding(.vertical, 6)
                }

                Text("Échap ferme le Centre d’aide. Après l’ouverture d’un document, utilisez les commandes habituelles de macOS et de VoiceOver pour le parcourir.")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(28)
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            installerMoniteurEchap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                titreEnFocus = true
            }
        }
        .onDisappear {
            retirerMoniteurEchap()
        }
        .onExitCommand {
            fermerCentreAide()
        }
        .alert(
            "Impossible d’ouvrir le document",
            isPresented: Binding(
                get: { messageErreur != nil },
                set: { nouvelleValeur in
                    if !nouvelleValeur { messageErreur = nil }
                }
            )
        ) {
            Button("D’accord", role: .cancel) {
                messageErreur = nil
            }
        } message: {
            Text(messageErreur ?? "Le document demandé est indisponible.")
        }
    }

    private func installerMoniteurEchap() {
        guard moniteurEchap == nil else { return }

        moniteurEchap = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { evenement in
            if evenement.keyCode == 53 {
                fermerCentreAide()
                return nil
            }
            return evenement
        }
    }

    private func retirerMoniteurEchap() {
        if let moniteurEchap {
            NSEvent.removeMonitor(moniteurEchap)
            self.moniteurEchap = nil
        }
    }

    private func fermerCentreAide() {
        NSApp.keyWindow?.performClose(nil)
    }

    @ViewBuilder
    private func boutonDocument(
        titre: String,
        description: String,
        ressource: String,
        extensionFichier: String
    ) -> some View {
        Button {
            ouvrirDocument(
                ressource: ressource,
                extensionFichier: extensionFichier,
                titre: titre
            )
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(titre)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(titre)
        .accessibilityHint("Ouvre le document \(titre).")
    }

    private func ouvrirDocument(
        ressource: String,
        extensionFichier: String,
        titre: String
    ) {
        guard let url = Bundle.main.url(
            forResource: ressource,
            withExtension: extensionFichier
        ) else {
            messageErreur = "Le fichier « \(titre) » n’a pas été trouvé dans l’application."
            return
        }

        guard NSWorkspace.shared.open(url) else {
            messageErreur = "macOS n’a pas pu ouvrir le document « \(titre) »."
            return
        }
    }
}
