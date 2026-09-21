//
//  ParametresView.swift
//  Apprenti Clavier
//
//  Réglages d’accessibilité, des jeux et du profil.
//

import SwiftUI
import AppKit

struct ParametresView: View {

    private enum ElementAccessible: Hashable {
        case titre
        case confirmation
    }

    private enum AlerteActive {
        case aucune
        case reinitialisation
        case suppression
    }

    @ObservedObject private var reglages =
        AppSettings.shared

    @ObservedObject private var progression =
        ProgressionManager.shared

    @AppStorage("apparenceApplication")
    private var apparenceApplication = "automatique"

    @State private var alerteActive:
        AlerteActive = .aucune

    @State private var messageConfirmation = ""

    @State private var moniteurClavier: Any?

    @AccessibilityFocusState
    private var focusVoiceOver: ElementAccessible?

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                Text("Réglages")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused(
                        $focusVoiceOver,
                        equals: .titre
                    )

                if let utilisateur =
                    progression.utilisateurActif {
                    GroupBox("Utilisateur actuel") {
                        Text(utilisateur)
                            .font(.title2)
                            .padding(.vertical, 8)
                    }
                    .accessibilityElement(
                        children: .combine
                    )
                    .accessibilityLabel(
                        "Utilisateur actuel, \(utilisateur)"
                    )
                } else {
                    GroupBox("Utilisateur actuel") {
                        Text("Aucun utilisateur sélectionné")
                            .padding(.vertical, 8)
                    }
                    .accessibilityElement(
                        children: .combine
                    )
                }

                GroupBox("Apparence") {
                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {
                        Text("Choisissez l’apparence de l’application")
                            .font(.title2)

                        Button {
                            selectionnerApparence(
                                "automatique"
                            )
                        } label: {
                            Label(
                                "Automatique",
                                systemImage:
                                    apparenceApplication == "automatique"
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                        .accessibilityLabel(
                            apparenceApplication == "automatique"
                            ? "Automatique, sélectionné"
                            : "Automatique"
                        )
                        .accessibilityHint(
                            "Suit automatiquement l’apparence choisie dans macOS."
                        )

                        Button {
                            selectionnerApparence(
                                "clair"
                            )
                        } label: {
                            Label(
                                "Clair",
                                systemImage:
                                    apparenceApplication == "clair"
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                        .accessibilityLabel(
                            apparenceApplication == "clair"
                            ? "Clair, sélectionné"
                            : "Clair"
                        )
                        .accessibilityHint(
                            "Utilise toujours l’apparence claire."
                        )

                        Button {
                            selectionnerApparence(
                                "sombre"
                            )
                        } label: {
                            Label(
                                "Sombre",
                                systemImage:
                                    apparenceApplication == "sombre"
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                        .accessibilityLabel(
                            apparenceApplication == "sombre"
                            ? "Sombre, sélectionné"
                            : "Sombre"
                        )
                        .accessibilityHint(
                            "Utilise toujours l’apparence sombre."
                        )

                        Text(
                            "Le mode Automatique suit l’apparence de macOS. "
                            + "Vous pouvez choisir Clair ou Sombre "
                            + "pour utiliser toujours la même apparence."
                        )
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("Accessibilité VoiceOver") {
                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {
                        Toggle(
                            "Annoncer automatiquement le texte restant à taper",
                            isOn: $reglages.annoncerTexteRestant
                        )
                        .toggleStyle(.checkbox)
                        .accessibilityHint(
                            "Active ou désactive les annonces automatiques "
                            + "du texte restant pendant la frappe."
                        )

                        Text(
                            "Les consignes, les résultats et les messages "
                            + "importants restent accessibles lorsque "
                            + "cette option est désactivée."
                        )

                        Divider()

                        Text("Délai des annonces VoiceOver")
                            .font(.title2)

                        Button {
                            selectionnerDelaiAnnonce(0.25)
                        } label: {
                            Label(
                                "Très rapide, un quart de seconde",
                                systemImage:
                                    reglages.delaiAnnonce == 0.25
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                        .accessibilityLabel(
                            reglages.delaiAnnonce == 0.25
                            ? "Très rapide, un quart de seconde, sélectionné"
                            : "Très rapide, un quart de seconde"
                        )
                        .disabled(
                            !reglages.annoncerTexteRestant
                        )

                        Button {
                            selectionnerDelaiAnnonce(0.5)
                        } label: {
                            Label(
                                "Rapide, une demi-seconde",
                                systemImage:
                                    reglages.delaiAnnonce == 0.5
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                        .accessibilityLabel(
                            reglages.delaiAnnonce == 0.5
                            ? "Rapide, une demi-seconde, sélectionné"
                            : "Rapide, une demi-seconde"
                        )
                        .disabled(
                            !reglages.annoncerTexteRestant
                        )

                        Button {
                            selectionnerDelaiAnnonce(1.0)
                        } label: {
                            Label(
                                "Normal, une seconde",
                                systemImage:
                                    reglages.delaiAnnonce == 1.0
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                        .accessibilityLabel(
                            reglages.delaiAnnonce == 1.0
                            ? "Normal, une seconde, sélectionné"
                            : "Normal, une seconde"
                        )
                        .disabled(
                            !reglages.annoncerTexteRestant
                        )

                        Button {
                            selectionnerDelaiAnnonce(1.5)
                        } label: {
                            Label(
                                "Confortable, une seconde et demie",
                                systemImage:
                                    reglages.delaiAnnonce == 1.5
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                        .accessibilityLabel(
                            reglages.delaiAnnonce == 1.5
                            ? "Confortable, une seconde et demie, sélectionné"
                            : "Confortable, une seconde et demie"
                        )
                        .disabled(
                            !reglages.annoncerTexteRestant
                        )

                        Button {
                            selectionnerDelaiAnnonce(2.0)
                        } label: {
                            Label(
                                "Lent, deux secondes",
                                systemImage:
                                    reglages.delaiAnnonce == 2.0
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                        .accessibilityLabel(
                            reglages.delaiAnnonce == 2.0
                            ? "Lent, deux secondes, sélectionné"
                            : "Lent, deux secondes"
                        )
                        .disabled(
                            !reglages.annoncerTexteRestant
                        )

                        Text(
                            "Ce délai est utilisé après la frappe "
                            + "avant d’annoncer les lettres, les mots "
                            + "ou les phrases qu’il reste à saisir."
                        )
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("Sons des exercices") {
                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {
                        Toggle(
                            "Activer les sons de validation",
                            isOn: $reglages.sonsExercicesActifs
                        )
                        .toggleStyle(.checkbox)
                        .accessibilityHint(
                            "Active ou désactive le son de bonne réponse "
                            + "et le son de mauvaise réponse pendant les exercices."
                        )

                        Text(
                            "Lorsque cette option est activée, un son bref "
                            + "confirme une bonne réponse ou signale une erreur. "
                            + "Elle est activée par défaut."
                        )
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("Progression") {
                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {
                        Text(texteProgression)

                        Button(
                            "Réinitialiser ma progression dans les jeux…",
                            role: .destructive
                        ) {
                            alerteActive =
                                .reinitialisation
                        }
                        .disabled(
                            progression.utilisateurActif == nil
                        )
                        .accessibilityHint(
                            "Efface la progression enregistrée dans les jeux "
                            + "pour l’utilisateur actuel."
                        )
                    }
                    .padding(.vertical, 8)
                }

                GroupBox(
                    titreSectionSuppression
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {
                        Text(
                            "La suppression efface définitivement "
                            + "le profil actif et toute sa progression."
                        )

                        Button(
                            "Supprimer ce profil…",
                            role: .destructive
                        ) {
                            alerteActive = .suppression
                        }
                        .disabled(
                            progression.utilisateurActif == nil
                        )
                        .accessibilityHint(
                            "Supprime définitivement "
                            + "l’utilisateur actuel."
                        )
                    }
                    .padding(.vertical, 8)
                }

                if !messageConfirmation.isEmpty {
                    Text(messageConfirmation)
                        .accessibilityLabel(
                            messageConfirmation
                        )
                        .accessibilityFocused(
                            $focusVoiceOver,
                            equals: .confirmation
                        )
                }

            }
            .padding(40)
            .frame(
                minWidth: 650,
                minHeight: 610,
                alignment: .topLeading
            )
        }
        .alert(
            titreAlerte,
            isPresented: alerteEstPresentee
        ) {
            Button(
                "Annuler",
                role: .cancel
            ) {
                alerteActive = .aucune
            }

            Button(
                libelleBoutonConfirmation,
                role: .destructive
            ) {
                confirmerAlerte()
            }
        } message: {
            Text(messageAlerte)
        }
        .onAppear {
            messageConfirmation = ""
            alerteActive = .aucune
            focusVoiceOver = nil

            installerMoniteurClavier()

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.9
            ) {
                focusVoiceOver = .titre
            }
        }
        .onDisappear {
            messageConfirmation = ""
            alerteActive = .aucune
            retirerMoniteurClavier()
        }
        .onReceive(
            progression.$utilisateurActif
        ) { _ in
            messageConfirmation = ""
            alerteActive = .aucune
        }
    }

    private var alerteEstPresentee: Binding<Bool> {
        Binding(
            get: {
                alerteActive != .aucune
            },
            set: { nouvelleValeur in
                if !nouvelleValeur {
                    alerteActive = .aucune
                }
            }
        )
    }

    private var titreAlerte: String {
        switch alerteActive {
        case .reinitialisation:
            return "Réinitialiser la progression des jeux ?"
        case .suppression:
            return "Supprimer ce profil ?"
        case .aucune:
            return ""
        }
    }

    private var libelleBoutonConfirmation: String {
        switch alerteActive {
        case .reinitialisation:
            return "Réinitialiser"
        case .suppression:
            return "Supprimer"
        case .aucune:
            return "Confirmer"
        }
    }

    private var messageAlerte: String {
        guard let utilisateur =
            progression.utilisateurActif else {
            return
                "Aucun utilisateur n’est actuellement sélectionné."
        }

        switch alerteActive {
        case .reinitialisation:
            return
                "Voulez-vous vraiment effacer la progression des jeux "
                + "de \(utilisateur) ? Le billet d’entrée importé reste valide. Cette action est irréversible."

        case .suppression:
            return
                "Voulez-vous vraiment supprimer le profil "
                + "\(utilisateur) ? Le profil et toute sa progression "
                + "seront définitivement effacés."

        case .aucune:
            return ""
        }
    }

    private var titreSectionSuppression: String {
        guard let utilisateur =
            progression.utilisateurActif else {
            return "Suppression du profil"
        }

        return "Suppression du profil de \(utilisateur)"
    }

    private var texteDelai: String {
        if reglages.delaiAnnonce == 0.25 {
            return "Un quart de seconde"
        }

        if reglages.delaiAnnonce == 0.5 {
            return "Une demi-seconde"
        }

        if reglages.delaiAnnonce == 1.0 {
            return "Une seconde"
        }

        if reglages.delaiAnnonce == 1.5 {
            return "Une seconde et demie"
        }

        return "Deux secondes"
    }

    private var texteProgression: String {
        "La réinitialisation efface les niveaux déverrouillés et les statistiques "
        + "du profil actif. Le profil reste enregistré et sa progression pédagogique "
        + "dans Apprenti Clavier n’est pas modifiée."
    }

    private func installerMoniteurClavier() {
        retirerMoniteurClavier()

        moniteurClavier = NSEvent.addLocalMonitorForEvents(
            matching: .keyDown
        ) { evenement in
            if alerteActive != .aucune {
                return evenement
            }

            if evenement.keyCode == 53 {
                let fenetre = evenement.window

                DispatchQueue.main.async {
                    fenetre?.performClose(nil)
                }

                return nil
            }

            return evenement
        }
    }

    private func retirerMoniteurClavier() {
        if let moniteurClavier {
            NSEvent.removeMonitor(moniteurClavier)
            self.moniteurClavier = nil
        }
    }

    private func selectionnerDelaiAnnonce(
        _ valeur: Double
    ) {
        reglages.delaiAnnonce = valeur
    }

    private func selectionnerApparence(
        _ valeur: String
    ) {
        apparenceApplication = valeur

        GestionnaireApparence.appliquer(
            valeur
        )
    }

    private func confirmerAlerte() {
        switch alerteActive {
        case .reinitialisation:
            progression.reinitialiserProgression()

            messageConfirmation =
                "Progression réinitialisée. "
                + "Tous les jeux repartent désormais du niveau 1."

            annoncerConfirmation()

        case .suppression:
            let nomSupprime =
                progression.supprimerUtilisateurActif()

            if let nomSupprime {
                messageConfirmation =
                    "Le profil \(nomSupprime) a été supprimé."

                annoncerConfirmation()
            } else {
                messageConfirmation =
                    "Aucun profil n’a été supprimé."

                annoncerConfirmation()
            }

        case .aucune:
            break
        }

        alerteActive = .aucune
    }

    private func annoncerConfirmation() {
        focusVoiceOver = nil

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.3
        ) {
            focusVoiceOver = .confirmation
        }
    }

}





