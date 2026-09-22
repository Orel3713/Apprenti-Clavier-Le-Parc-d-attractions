//
//  LaGrandeRoueView.swift
//  Apprenti Clavier
//
//  Jeu « La Grande Roue » — 10 niveaux.
//

import SwiftUI
import AppKit
import AVFoundation

struct LaGrandeRoueView: View {

    let retourParc: () -> Void

    @State private var ecran: EcranGrandeRoue = .niveaux
    @State private var niveauSelectionne = 1
    @State private var niveauMaximumDebloque = 1
    private let cleProgressionJeu = "progressionGrandeRoueParUtilisateurV1"

    @State private var tempsRestant = 60
    @State private var partieEnCours = false
    @State private var partieTerminee = false
    @State private var afficherCommentJouer = false
    @State private var saisie = ""
    @State private var indexElement = 0
    @State private var bonnesReponses = 0
    @State private var erreurs = 0
    @State private var textesCorrects: [String] = []
    @State private var enTransitionEntreElements = false
    @State private var compteARebours: Int? = nil

    // vitesse = tours par seconde. Elle est volontairement continue :
    // les bonnes réponses donnent de l'élan, le frottement le dissipe.
    @State private var vitesse: Double = 0
    @State private var angle: Double = 0
    @State private var toursCompletes = 0
    @State private var progressionTour: Double = 0

    @State private var timer: Timer?
    @State private var dernierInstant = Date()
    @State private var derniereBonneReponse = Date.distantPast
    @State private var derniereFrappeValide = Date.distantPast

    @AccessibilityFocusState private var titreEnFocus: Bool
    @AccessibilityFocusState private var zoneNeutreEnFocus: Bool
    @AccessibilityFocusState private var resultatEnFocus: Bool

    // MARK: - Contenu des 10 niveaux
    //
    // Les banques sont mélangées à chaque partie. Un élément n'est pas
    // reproposé avant que toute sa banque ait été parcourue.
    //
    // Niveau 1 : uniquement des caractères simples. Pas de circonflexe ni
    // de tréma, afin d'éviter les touches mortes dès la découverte du jeu.
    private let banquesElements: [[String]] = [
        // 1. Les caractères
        Array("abcdefghijklmnopqrstuvwxyz").map(String.init) + [
            "é", "è", "à", "ù", "ç",
            ".", ",", "?", "!", ":", ";", "'"
        ],

        // 2. Les objets du quotidien
        [
            "sac", "bol", "lit", "verre", "tasse", "lampe", "tapis", "savon",
            "brosse", "veste", "jupe", "robe", "gant", "bonnet", "poche",
            "table", "porte", "livre", "carte", "peigne", "vase", "cadre",
            "corde", "chaise", "stylo", "gomme", "règle", "cahier", "panier",
            "miroir", "coussin", "rideau", "assiette", "fourchette", "cuillère",
            "bouteille", "valise", "montre", "bougie", "parapluie"
        ],

        // 3. Les animaux
        [
            "renard", "souris", "cheval", "canard", "tortue", "singe", "girafe",
            "koala", "requin", "baleine", "crabe", "pigeon", "hibou", "insecte",
            "castor", "dauphin", "mouton", "chèvre", "cochon", "dindon", "lézard",
            "serpent", "hamster", "gazelle", "gorille", "panthère", "crocodile",
            "escargot", "chenille", "papillon", "moustique", "abeille", "araignée",
            "manchot", "pélican", "moineau", "corbeau", "saumon", "méduse", "zèbre"
        ],

        // 4. Les aliments
        [
            "pomme", "poire", "fraise", "prune", "melon", "kiwi", "figue",
            "raisin", "citron", "orange", "banane", "ananas", "cerise", "tomate",
            "carotte", "radis", "salade", "poireau", "navet", "haricot", "lentille",
            "olive", "noix", "amande", "beurre", "farine", "sucre", "biscuit",
            "madeleine", "yaourt", "fromage", "poulet", "poisson", "pizza", "soupe",
            "compote", "confiture", "chocolat", "dessert", "recette"
        ],

        // 5. Le cirque
        [
            "cirque", "clown", "balle", "ballon", "piste", "scène", "tente",
            "corde", "filet", "anneau", "numéro", "magie", "géant", "nain",
            "cheval", "éléphant", "tigre", "lion", "singe", "artiste", "public",
            "entrée", "musique", "danse", "roue", "vélo", "saut", "ruban",
            "étoile", "costume", "masque", "tambour", "trompette", "acrobate",
            "jongleur", "trapèze", "canon", "parade", "affiche", "lumière"
        ],

        // 6. Les villes : volontairement en minuscules. Accents et espaces conservés.
        [
            "paris", "nantes", "lyon", "lille", "nice", "brest", "dijon", "rouen",
            "reims", "nancy", "metz", "caen", "rennes", "angers", "toulon",
            "avignon", "marseille", "bordeaux", "toulouse", "berlin",
            "madrid", "rome", "londres", "dublin", "tokyo", "miami", "boston",
            "milan", "turin", "naples", "venise", "prague", "monaco", "genève",
            "grenoble", "perpignan", "orléans", "las vegas", "new york", "los angeles"
        ],

        // 7. Les nouvelles technologies
        [
            "clavier", "écran", "souris", "curseur", "casque", "micro", "photo",
            "vidéo", "robot", "drone", "radio", "disque", "pixel", "fichier",
            "dossier", "tactile", "message", "profil", "réseau", "serveur", "menu",
            "audio", "webcam", "tablette", "console", "mobile", "montre", "enceinte",
            "caméra", "manette", "batterie", "logiciel", "internet", "numérique",
            "smartphone", "ordinateur", "application", "connexion", "sauvegarde",
            "imprimante"
        ],

        // 8. L'école
        [
            "stylo", "crayon", "gomme", "règle", "colle", "feuille", "livre",
            "cahier", "classe", "école", "cour", "table", "chaise", "bureau",
            "carte", "globe", "craie", "trousse", "cartable", "compas", "pinceau",
            "peinture", "dessin", "calcul", "lecture", "phrase", "nombre", "chiffre",
            "leçon", "devoir", "exercice", "matière", "histoire", "musique",
            "science", "élève", "professeur", "tableau", "récréation", "bibliothèque"
        ],

        // 9. La musique
        [
            "musique", "chanson", "micro", "chanteur", "chanteuse", "piano",
            "guitare", "violon", "clarinette", "harpe", "orgue", "violoncelle",
            "batterie", "tambour", "trompette", "saxophone", "concert", "scène",
            "public", "artiste", "groupe", "solo", "duo", "note", "rythme",
            "mélodie", "refrain", "couplet", "disque", "album", "radio", "casque",
            "danse", "chorale", "orchestre", "festival", "spectacle", "écoute",
            "studio", "musicien"
        ],

        // 10. Le sport
        [
            "but", "match", "balle", "ballon", "équipe", "stade", "piste",
            "course", "vélo", "ski", "judo", "tennis", "rugby", "foot",
            "golf", "boxe", "nage", "saut", "joueur", "arbitre", "gardien",
            "athlète", "victoire", "médaille", "podium", "maillot", "raquette",
            "piscine", "natation", "marathon", "cyclisme", "patinage", "escalade",
            "gymnastique", "handball", "karaté", "échauffement", "record", "terrain", "finale"
        ]
    ]

    private let titresNiveaux = [
        "Les caractères",
        "Les objets du quotidien",
        "Les animaux",
        "Les aliments",
        "Le cirque",
        "Les villes",
        "Les nouvelles technologies",
        "L’école",
        "La musique",
        "Le sport"
    ]

    private let descriptionsNiveaux = [
        "Lettres, accents et signes de ponctuation donnent les premiers tours de roue.",
        "Faites tourner la roue au milieu des objets qui nous accompagnent tous les jours.",
        "Des plus petits aux plus impressionnants, les animaux prennent place dans la grande roue.",
        "Fruits, légumes et gourmandises sont au menu de ce tour de roue.",
        "Clowns, acrobates et artistes de la piste s’invitent au pied de la grande roue.",
        "Faites voyager la grande roue de ville en ville, en France et ailleurs.",
        "Claviers, écrans et objets connectés font entrer la grande roue dans l’ère numérique.",
        "Cahiers, leçons et matériel scolaire prennent place pour un nouveau tour.",
        "Instruments, chansons et scènes de concert donnent le rythme à la grande roue.",
        "Du stade à la piscine, retrouvez tout l’univers du sport au fil des tours de roue."
    ]

    // La physique reste strictement identique d’un niveau à l’autre.
    // La progression se fait par l’objectif et par la variété des éléments.
    private let objectifsTours = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

    private var objectifNiveauCourant: Int {
        objectifsTours[max(0, min(niveauSelectionne - 1, objectifsTours.count - 1))]
    }

    private var titreNiveauCourant: String {
        titresNiveaux[max(0, min(niveauSelectionne - 1, titresNiveaux.count - 1))]
    }

    private var descriptionNiveauCourant: String {
        descriptionsNiveaux[max(0, min(niveauSelectionne - 1, descriptionsNiveaux.count - 1))]
    }

    private var elementsNiveauCourant: [String] {
        banquesElements[max(0, min(niveauSelectionne - 1, banquesElements.count - 1))]
    }

    @State private var elementsPartie: [String] = []

    var body: some View {
        Group {
            switch ecran {
            case .niveaux:
                ecranNiveaux
            case .objectif:
                ecranObjectif
            case .partie:
                ecranPartie
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        .background {
            DecorGrandeRoueParc()
                .accessibilityHidden(true)
        }
        .background {
            CaptureClavierGrandeRoue(
                actif:
                    ecran == .partie
                    && partieEnCours
                    && !partieTerminee
                    && compteARebours == nil
                    && !enTransitionEntreElements,
                caractereSaisi: { caractere in
                    traiterCaractereSaisi(caractere)
                },
                commandePressee: {
                    reannoncerElementCourant()
                },
                echapPresse: {
                    gererEchap()
                }
            )
            .frame(width: 0, height: 0)
        }
        .background {
            CaptureEchapGrandeRoue(
                actif: ecran != .partie && !afficherCommentJouer,
                action: gererEchap
            )
            .frame(width: 0, height: 0)
        }
        .onExitCommand {
            gererEchap()
        }
        .onDisappear {
            arreterPartie()
        }
        .sheet(isPresented: $afficherCommentJouer) {
            CommentJouerGrandeRoueView {
                afficherCommentJouer = false
            }
        }
    }

    // MARK: - Liste des niveaux

    private var ecranNiveaux: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Button("Retour au parc d’attractions") {
                        retourParc()
                    }
                    Spacer()
                }

                Text("La Grande Roue")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreEnFocus)

                Text("Donnez de l’élan à la grande roue en tapant correctement et accomplissez le plus de tours possible.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 760)

                Button("Comment jouer") {
                    afficherCommentJouer = true
                }

                VStack(spacing: 12) {
                    ForEach(1...10, id: \.self) { numero in
                        boutonNiveau(
                            numero: numero,
                            verrouille: numero > niveauMaximumDebloque
                        )
                    }
                }
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .padding(36)
        }
        .onAppear {
            niveauMaximumDebloque = ProgressionManager.shared.niveauMaximumDebloqueJeu(
                cle: cleProgressionJeu,
                cleHistorique: "grandeRoueNiveauMaximumDebloque"
            )
            placerFocusTitre()
        }
    }

    private func boutonNiveau(
        numero: Int,
        verrouille: Bool
    ) -> some View {
        Button {
            if verrouille {
                _ = GestionnaireSonsInterface.shared
                    .jouerCadenasVerrouille()
                return
            }

            niveauSelectionne = numero
            ecran = .objectif
            placerFocusTitre()
        } label: {
            ZStack {
                VStack(spacing: 3) {
                    Text("Niveau \(numero)")
                        .font(.headline)
                    Text(titresNiveaux[numero - 1])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                HStack {
                    Spacer()

                    Image(
                        systemName:
                            verrouille
                            ? "lock.fill"
                            : "chevron.right.circle.fill"
                    )
                    .foregroundStyle(
                        verrouille ? .red : .accentColor
                    )
                    .accessibilityHidden(true)
                }
            }
            .padding(14)
            .background(
                .thinMaterial,
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            verrouille
            ? "Niveau \(numero), \(titresNiveaux[numero - 1]), verrouillé"
            : "Niveau \(numero), \(titresNiveaux[numero - 1])"
        )
        .accessibilityHint(
            verrouille
            ? "Terminez d’abord le niveau précédent."
            : "Ouvre ce niveau."
        )
    }

    // MARK: - Objectif

    private var ecranObjectif: some View {
        VStack(spacing: 24) {
            Text("Niveau \(niveauSelectionne)")
                .font(.largeTitle)
                .bold()
                .accessibilityFocused($titreEnFocus)

            Text(titreNiveauCourant)
                .font(.title)
                .bold()

            Text(descriptionNiveauCourant)
                .font(.title3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 760)

            Text("Objectif du niveau")
                .font(.title2)
                .bold()

            Text("Accomplissez au moins \(objectifNiveauCourant) tours en 60 secondes.")
                .font(.title2)
                .multilineTextAlignment(.center)

            Button("Commencer") {
                demarrerPartie()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .onAppear { placerFocusTitre() }
    }

    // MARK: - Partie

    private var ecranPartie: some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: 16) {
            HStack {
                Text("Temps : \(tempsRestant) s")
                    .font(.headline)
                Spacer()
                Text("Tours : \(toursCompletes) / \(objectifNiveauCourant)")
                    .font(.headline)
                Spacer()
                Text("Erreurs : \(erreurs)")
                    .font(.headline)
            }
            .padding(.horizontal, 30)
            .accessibilityHidden(true)

            if partieTerminee {
                resultatPartie
            } else {
                HStack(spacing: 36) {
                    GrandeRoueAnimee(angle: angle)
                        .frame(width: 430, height: 430)
                        .accessibilityHidden(true)

                    VStack(spacing: 18) {
                        if let compteARebours {
                            Text("\(compteARebours)")
                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                .accessibilityHidden(true)
                        } else if enTransitionEntreElements {
                            Text("La roue continue de tourner…")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        } else {
                            Text("À taper")
                                .font(.headline)

                            Text(elementActuel)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .accessibilityHidden(true)

                            Text("Tapez directement au clavier.")
                    .accessibilityHint("Appuyez sur la touche Commande pour réentendre l’élément à taper.")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)

                            Text("Chaque bonne réponse donne de l’élan à la roue.")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: 380)
                    .accessibilityHidden(true)
                }
            }
            }
            .padding(28)

            // Point de repos VoiceOver placé tout à droite.
            // Il est volontairement sans texte ni libellé.
            // Le focus y est envoyé AVANT le décompte, puis n'est plus déplacé
            // pendant toute la partie.
            PointFocusVoiceOverSilencieux()
                .frame(width: 2, height: 2)
                .accessibilityFocused($zoneNeutreEnFocus)
                .padding(.trailing, 2)
        }
    }

    private var messageReussiteResultat: String {
        guard toursCompletes >= objectifNiveauCourant else {
            return "Objectif non atteint."
        }

        if niveauSelectionne < 10 {
            return "Bravo, vous avez réussi ce niveau. Le niveau \(niveauSelectionne + 1) est maintenant déverrouillé."
        } else {
            return "Bravo, vous avez terminé tous les niveaux de La Grande Roue !"
        }
    }

    private var resultatPartie: some View {
        Button {
            ecran = .niveaux
            placerFocusTitre()
        } label: {
            VStack(spacing: 22) {
                Text(toursCompletes >= objectifNiveauCourant ? "Niveau réussi !" : "Objectif non atteint")
                    .font(.largeTitle)
                    .bold()

                Text(messageReussiteResultat)
                    .font(.title2)
                    .multilineTextAlignment(.center)

                Text("Vous avez accompli \(toursCompletes) tours. Objectif : \(objectifNiveauCourant).")
                    .font(.title2)

                Text("Éléments réussis : \(bonnesReponses). Erreurs : \(erreurs).")
                    .font(.headline)

                Text("Appuyez sur Entrée pour revenir à la liste des niveaux.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(resumeAccessible)
        .accessibilityHint("Appuyez sur Entrée pour revenir à la liste des niveaux.")
        .accessibilityFocused($resultatEnFocus)
        .keyboardShortcut(.defaultAction)
        .onAppear { placerFocusResultat() }
    }

    private var resumeAccessible: String {
        return "\(messageReussiteResultat) Vous avez accompli \(toursCompletes) tours. Objectif : \(objectifNiveauCourant). Éléments réussis : \(bonnesReponses). Erreurs : \(erreurs). Appuyez sur Entrée pour revenir à la liste des niveaux."
    }

    // MARK: - Moteur du jeu

    private var elementActuel: String {
        if elementsPartie.isEmpty {
            return elementsNiveauCourant.first ?? "a"
        }
        return elementsPartie[indexElement % elementsPartie.count]
    }

    private var libelleAccessibleElement: String {
        guard niveauSelectionne == 1 else { return elementActuel }

        switch elementActuel {
        case "é": return "E accent aigu"
        case "è": return "E accent grave"
        case "à": return "A accent grave"
        case "ù": return "U accent grave"
        case "ç": return "C cédille"
        case ".": return "point"
        case ",": return "virgule"
        case "?": return "point d’interrogation"
        case "!": return "point d’exclamation"
        case ":": return "deux-points"
        case ";": return "point-virgule"
        case "'": return "apostrophe"
        default: return elementActuel
        }
    }

    private func demarrerPartie() {
        arreterPartie()
        titreEnFocus = false
        resultatEnFocus = false
        ecran = .partie
        tempsRestant = 60
        partieEnCours = false
        partieTerminee = false
        saisie = ""
        indexElement = 0
        elementsPartie = elementsNiveauCourant.shuffled()
        bonnesReponses = 0
        erreurs = 0
        textesCorrects = []
        enTransitionEntreElements = false
        vitesse = 0
        angle = 0
        toursCompletes = 0
        progressionTour = 0
        lancerCompteARebours()
    }

    private func lancerCompteARebours() {
        // Le curseur VoiceOver est déplacé AVANT le décompte.
        // Toute annonce générique éventuelle liée à ce déplacement doit donc
        // être immédiatement remplacée par « 3 », et aucun nouveau déplacement
        // de focus n'a lieu après « 1 ».
        placerFocusZoneNeutre()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.20) {
            guard ecran == .partie, !partieTerminee else { return }
            compteARebours = 3
            annoncerVoiceOver("3")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.20) {
            guard ecran == .partie, !partieTerminee else { return }
            compteARebours = 2
            annoncerVoiceOver("2")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.20) {
            guard ecran == .partie, !partieTerminee else { return }
            compteARebours = 1
            annoncerVoiceOver("1")
        }

        // Une seconde complète sans parole après « 1 ».
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.20) {
            guard ecran == .partie, !partieTerminee else { return }
            compteARebours = nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.20) {
            guard ecran == .partie, !partieTerminee else { return }
            commencerChronometreEtPremierElement()
        }
    }

    private func commencerChronometreEtPremierElement() {
        partieEnCours = true
        dernierInstant = Date()
        debutReference = Date().timeIntervalSinceReferenceDate

        // La roue démarre réellement à l’arrêt. La première bonne réponse
        // lui donne son premier élan.
        vitesse = 0
        derniereBonneReponse = Date.distantPast
        derniereFrappeValide = Date.distantPast

        let nouveauTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            DispatchQueue.main.async {
                actualiserMoteur()
            }
        }
        RunLoop.main.add(nouveauTimer, forMode: .common)
        timer = nouveauTimer

        // Le focus a déjà été déplacé avant le décompte.
        // On ne le touche plus pendant la partie.
        presenterElementCourant(apres: 0.35)
    }

    private func actualiserMoteur() {
        guard partieEnCours else { return }

        let maintenant = Date()
        let dt = maintenant.timeIntervalSince(dernierInstant)
        dernierInstant = maintenant

        // Après une bonne réponse, on laisse assez d'inertie pour que VoiceOver
        // annonce confortablement le mot suivant sans faire chuter la roue.
        // En revanche, une vraie pause du joueur provoque un ralentissement net.
        let silenceDepuisBonneReponse = Date().timeIntervalSince(derniereBonneReponse)
        let silenceDepuisFrappe = Date().timeIntervalSince(derniereFrappeValide)

        // Une frappe correcte en cours ne doit plus faire freiner la roue.
        // Le ralentissement commence seulement après une vraie pause du joueur.
        let frottement: Double
        if silenceDepuisFrappe < 1.25 {
            frottement = 0.0
        } else if silenceDepuisFrappe < 3.0 {
            frottement = 0.018
        } else if silenceDepuisFrappe < 5.0 {
            frottement = 0.065
        } else if silenceDepuisBonneReponse > 5.0 {
            frottement = 0.16
        } else {
            frottement = 0.09
        }
        vitesse = max(0, vitesse - frottement * dt)
        vitesse = min(vitesse, 0.46)

        let toursAjoutes = vitesse * dt
        progressionTour += toursAjoutes
        angle += toursAjoutes * 360

        while progressionTour >= 1.0 {
            progressionTour -= 1.0
            toursCompletes += 1
            SonGrandeRoue.shared.jouerSonTour()
        }

        SonGrandeRoue.shared.actualiserBruitRoue(vitesse: vitesse)

        // Chronomètre dérivé du temps réel pour éviter les dérives du Timer.
        let ecoule = 60 - Int(tempsRestant)
        _ = ecoule
        if dt > 0 {
            // Le compteur visible descend une fois par seconde environ.
            let nouveauTemps = max(0, 60 - Int(Date().timeIntervalSinceReferenceDate - debutReference))
            if nouveauTemps != tempsRestant {
                tempsRestant = nouveauTemps
            }
        }

        if tempsRestant <= 0 {
            terminerPartie()
        }
    }

    @State private var debutReference: TimeInterval = Date().timeIntervalSinceReferenceDate

    private func traiterCaractereSaisi(_ caractere: String) {
        guard
            partieEnCours,
            !partieTerminee,
            !enTransitionEntreElements,
            compteARebours == nil
        else {
            return
        }

        let attendu =
            elementActuel
            .precomposedStringWithCanonicalMapping

        let tentative =
            (saisie + caractere)
            .precomposedStringWithCanonicalMapping

        // Tant que les caractères saisis correspondent au début du mot,
        // on attend simplement le caractère suivant.
        if attendu.hasPrefix(tentative) {
            saisie = tentative
            derniereFrappeValide = Date()

            if tentative == attendu {
                bonneReponse()
            }
            return
        }

        // Une erreur coupe fortement l'élan. Le ralentissement de la roue
        // constitue lui-même le retour sonore de l'erreur.
        erreurs += 1
        vitesse *= 0.40
        saisie = ""
        laisserRespirerLaRoue()
    }

    private func reannoncerElementCourant() {
        guard
            partieEnCours,
            !partieTerminee,
            !enTransitionEntreElements,
            compteARebours == nil
        else {
            return
        }

        annoncerVoiceOver(libelleAccessibleElement)
    }

    private func bonneReponse() {
        bonnesReponses += 1
        textesCorrects.append(elementActuel)

        // Réglage intermédiaire après les tests extrêmes : 27 tours était trop
        // généreux, tandis que 3 tours restait beaucoup trop difficile.
        // On remonte franchement l’énergie gagnée sans retrouver l’ancienne fusée.
        // Nouvelle mécanique : les bonnes réponses entretiennent une
        // vitesse de croisière au lieu d'empiler les accélérations.
        // Le premier mot lance franchement la roue. Ensuite, tant qu'elle
        // tourne déjà à une vitesse confortable, une bonne réponse sert
        // surtout à maintenir l'élan sans la transformer en fusée.
        let vitesseCroisiere: Double = 0.28
        let vitesseRelance: Double = 0.22

        if vitesse < 0.08 {
            // Roue presque arrêtée : relance nette.
            vitesse = min(0.46, vitesse + vitesseRelance)
        } else if vitesse < vitesseCroisiere {
            // On remonte progressivement vers la vitesse de croisière.
            let manque = vitesseCroisiere - vitesse
            let coupDePouce = min(0.08, max(0.025, manque * 0.65))
            vitesse = min(vitesseCroisiere, vitesse + coupDePouce)
        } else {
            // Déjà à vitesse de croisière : pas d'accélération supplémentaire.
            // La frappe correcte entretient simplement l'activité, ce qui
            // empêche le freinage pendant que le joueur continue à taper.
            vitesse = min(vitesse, 0.46)
        }
        derniereBonneReponse = Date()

        indexElement += 1
        if !elementsPartie.isEmpty, indexElement >= elementsPartie.count {
            let precedent = elementsPartie.last
            elementsPartie = elementsNiveauCourant.shuffled()
            if let precedent,
               elementsPartie.count > 1,
               elementsPartie.first == precedent {
                elementsPartie.swapAt(0, 1)
            }
            indexElement = 0
        }
        saisie = ""
        laisserRespirerLaRoue()
    }

    private func laisserRespirerLaRoue() {
        enTransitionEntreElements = true
        saisie = ""

        // Courte respiration sonore entre deux mots : assez longue pour entendre
        // la roue, mais assez courte pour ne pas casser son élan.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard partieEnCours, !partieTerminee else { return }
            enTransitionEntreElements = false
            presenterElementCourant(apres: 0.10)
        }
    }

    private func presenterElementCourant(apres delai: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delai) {
            guard
                partieEnCours,
                !partieTerminee,
                !enTransitionEntreElements
            else {
                return
            }

            saisie = ""
            derniereFrappeValide = Date()
            annoncerVoiceOver(libelleAccessibleElement)
        }
    }

    private func annoncerVoiceOver(_ texte: String) {
        // Même méthode que le Jeu des ballons : annonce portée par la
        // fenêtre principale, sans déplacer le focus VoiceOver ni lui
        // imposer une priorité spéciale.
        VoiceOverAnnouncer.annoncerTexte(texte)
    }

    private func terminerPartie() {
        guard partieEnCours else { return }
        partieEnCours = false
        partieTerminee = true
        timer?.invalidate()
        timer = nil
        vitesse = 0
        SonGrandeRoue.shared.arreterTout()

        let reussi = toursCompletes >= objectifNiveauCourant
        ProgressionManager.shared.enregistrerPartie(
            jeu: .grandeRoue,
            niveau: niveauSelectionne,
            reussie: reussi,
            motsCorrects: textesCorrects.reduce(0) { $0 + ProgressionManager.nombreDeMots(dans: $1) },
            erreursDeFrappe: erreurs,
            caracteresValides: textesCorrects.reduce(0) { $0 + $1.count },
            dureeSaisie: 60
        )

        if toursCompletes >= objectifNiveauCourant,
           niveauSelectionne < 10 {
            niveauMaximumDebloque = max(
                niveauMaximumDebloque,
                niveauSelectionne + 1
            )
            ProgressionManager.shared.enregistrerNiveauMaximumDebloqueJeu(
                niveauMaximumDebloque,
                cle: cleProgressionJeu
            )
        }

        placerFocusResultat()
    }

    private func arreterPartie() {
        partieEnCours = false
        compteARebours = nil
        enTransitionEntreElements = false
        timer?.invalidate()
        timer = nil
        SonGrandeRoue.shared.arreterTout()
    }

    private func gererEchap() {
        switch ecran {
        case .partie:
            // Dès que le niveau est lancé (décompte compris), Échap est ignorée.
            // Le joueur termine donc la tentative en cours.
            return
        case .objectif:
            ecran = .niveaux
            placerFocusTitre()
        case .niveaux:
            retourParc()
        }
    }

    private func placerFocusZoneNeutre() {
        titreEnFocus = false
        resultatEnFocus = false
        zoneNeutreEnFocus = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            guard ecran == .partie, !partieTerminee else { return }
            zoneNeutreEnFocus = true
        }
    }

    private func placerFocusResultat() {
        titreEnFocus = false
        resultatEnFocus = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard ecran == .partie, partieTerminee else { return }
            resultatEnFocus = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard ecran == .partie, partieTerminee else { return }
                zoneNeutreEnFocus = false
            }
        }
    }

    private func placerFocusTitre() {
        zoneNeutreEnFocus = false
        resultatEnFocus = false
        titreEnFocus = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            titreEnFocus = true
        }
    }
}

// MARK: - Point de repos VoiceOver silencieux

private struct PointFocusVoiceOverSilencieux: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let vue = NSView(frame: .zero)
        vue.setAccessibilityElement(true)
        vue.setAccessibilityRole(.unknown)
        vue.setAccessibilityLabel(nil)
        vue.setAccessibilityHelp(nil)
        vue.setAccessibilityValue(nil)
        return vue
    }

    func updateNSView(_ nsView: NSView, context: Context) { }
}

private enum EcranGrandeRoue {
    case niveaux
    case objectif
    case partie
}


// MARK: - Décor de la zone « Grande Roue »
//
// L'idée n'est pas d'afficher une seconde grande roue derrière la roue jouable.
// On se place au pied de l'attraction : ciel de parc, sol, guirlande lumineuse,
// arbres et petites silhouettes de stands au loin. Cela donne l'impression
// d'être dans une zone différente du Parc sans voler la vedette à la roue.

private struct DecorGrandeRoueParc: View {
    @Environment(\.colorScheme) private var apparence

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: apparence == .dark
                        ? [Color.black.opacity(0.92), Color.indigo.opacity(0.50)]
                        : [Color.cyan.opacity(0.20), Color.blue.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Sol de l'allée du parc.
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(
                            apparence == .dark
                                ? Color.green.opacity(0.16)
                                : Color.green.opacity(0.12)
                        )
                        .frame(height: geo.size.height * 0.23)
                }

                // Quelques stands très discrets au loin.
                HStack(alignment: .bottom, spacing: geo.size.width * 0.05) {
                    ForEach(0..<4, id: \.self) { index in
                        VStack(spacing: 0) {
                            TriangleDecor()
                                .fill(Color.orange.opacity(apparence == .dark ? 0.20 : 0.16))
                                .frame(width: 90, height: 34)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.secondary.opacity(0.08))
                                .frame(width: 82, height: 55)
                        }
                        .opacity(index == 1 || index == 2 ? 0.55 : 0.35)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, geo.size.height * 0.16)

                // Guirlande lumineuse de fête foraine.
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height * 0.13))
                    path.addQuadCurve(
                        to: CGPoint(x: geo.size.width, y: geo.size.height * 0.13),
                        control: CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.22)
                    )
                }
                .stroke(Color.secondary.opacity(0.18), lineWidth: 2)

                HStack(spacing: max(28, geo.size.width / 14)) {
                    ForEach(0..<12, id: \.self) { _ in
                        Circle()
                            .fill(Color.yellow.opacity(apparence == .dark ? 0.42 : 0.28))
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, geo.size.height * 0.14)
            }
        }
        .ignoresSafeArea()
    }
}

private struct TriangleDecor: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Grande roue animée
//
// Elle reprend volontairement l'identité de l'IconeGrandeRoue du Parc :
// or, bleu, six nacelles rouge/verte/orange/bleue/jaune/violette.
// La structure tourne avec l'angle du jeu, tandis que les nacelles restent
// verticales, comme sur une vraie grande roue.

private struct GrandeRoueAnimee: View {

    let angle: Double
    @Environment(\.colorScheme) private var apparence

    private let couleursNacelles: [Color] = [
        Color(red: 0.86, green: 0.16, blue: 0.16),
        Color(red: 0.18, green: 0.58, blue: 0.28),
        Color(red: 0.94, green: 0.47, blue: 0.08),
        Color(red: 0.12, green: 0.40, blue: 0.76),
        Color(red: 0.95, green: 0.67, blue: 0.08),
        Color(red: 0.48, green: 0.23, blue: 0.68)
    ]

    var body: some View {
        GeometryReader { geo in
            let cote = min(geo.size.width, geo.size.height)
            let centre = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.43)
            let rayon = cote * 0.31
            let or = Color(red: 0.95, green: 0.66, blue: 0.13)
            let bleu = apparence == .dark
                ? Color(red: 0.12, green: 0.32, blue: 0.58)
                : Color(red: 0.19, green: 0.52, blue: 0.72)

            ZStack {
                // Pieds fixes.
                Path { p in
                    p.move(to: CGPoint(x: centre.x - cote * 0.025, y: centre.y + cote * 0.025))
                    p.addLine(to: CGPoint(x: centre.x - cote * 0.22, y: geo.size.height * 0.91))
                    p.move(to: CGPoint(x: centre.x + cote * 0.025, y: centre.y + cote * 0.025))
                    p.addLine(to: CGPoint(x: centre.x + cote * 0.22, y: geo.size.height * 0.91))
                }
                .stroke(or, style: StrokeStyle(lineWidth: cote * 0.045, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: centre.x - cote * 0.025, y: centre.y + cote * 0.025))
                    p.addLine(to: CGPoint(x: centre.x - cote * 0.22, y: geo.size.height * 0.91))
                    p.move(to: CGPoint(x: centre.x + cote * 0.025, y: centre.y + cote * 0.025))
                    p.addLine(to: CGPoint(x: centre.x + cote * 0.22, y: geo.size.height * 0.91))
                }
                .stroke(bleu, style: StrokeStyle(lineWidth: cote * 0.028, lineCap: .round))

                // Structure tournante.
                ZStack {
                    Circle()
                        .stroke(or, lineWidth: cote * 0.018)
                        .frame(width: rayon * 2, height: rayon * 2)

                    Circle()
                        .stroke(bleu, lineWidth: cote * 0.009)
                        .frame(width: rayon * 1.82, height: rayon * 1.82)

                    ForEach(0..<8, id: \.self) { i in
                        Rectangle()
                            .fill(bleu.opacity(0.9))
                            .frame(width: rayon, height: max(2, cote * 0.007))
                            .offset(x: rayon / 2)
                            .rotationEffect(.degrees(Double(i) * 45))
                    }
                }
                .frame(width: rayon * 2, height: rayon * 2)
                .position(centre)
                .rotationEffect(.degrees(angle))

                Circle()
                    .fill(or)
                    .frame(width: cote * 0.085, height: cote * 0.085)
                    .position(centre)
                Circle()
                    .fill(bleu)
                    .frame(width: cote * 0.052, height: cote * 0.052)
                    .position(centre)

                // Nacelles : leur position tourne, leur cabine reste droite.
                ForEach(0..<6, id: \.self) { i in
                    let a = (Double(i) * 60 - 90 + angle) * Double.pi / 180
                    let x = centre.x + CGFloat(cos(a)) * rayon
                    let y = centre.y + CGFloat(sin(a)) * rayon

                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(or)
                            .frame(width: 3, height: cote * 0.035)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(couleursNacelles[i])
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(or, lineWidth: 2))
                            .frame(width: cote * 0.115, height: cote * 0.075)
                    }
                    .position(x: x, y: y + cote * 0.045)
                }

                RoundedRectangle(cornerRadius: 8)
                    .fill(bleu)
                    .frame(width: cote * 0.55, height: cote * 0.055)
                    .position(x: centre.x, y: geo.size.height * 0.92)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Retour sonore
//
// Pour ce premier test, aucun nouveau WAV n'est nécessaire : on utilise des
// sons système courts pour le tour et l'erreur, et un léger « tic » mécanique
// dont la cadence suit la vitesse. Cela permet de tester immédiatement le
// principe avant de choisir les WAV définitifs de la roue.

@MainActor

// MARK: - Capture clavier directe

private struct CommentJouerGrandeRoueView: View {
    let fermer: () -> Void
    @AccessibilityFocusState private var titreEnFocus: Bool
    @State private var contenuAccessible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Comment jouer")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreEnFocus)

                Text("Dans ce jeu, tapez correctement les caractères ou les mots proposés pour donner de l’élan à la grande roue. Tant que vous continuez à répondre correctement, la roue conserve son mouvement. Si vous cessez de taper, elle ralentit progressivement.")
                Text("Si la roue s’arrête complètement, la partie continue : tapez correctement l’élément proposé pour la relancer. Une erreur lui fait perdre une grande partie de son élan, mais les tours déjà accomplis restent acquis.")
                Text("Un son bref marque chaque tour complet. La partie dure 60 secondes et continue jusqu’à la fin du temps, même si l’objectif est déjà atteint.")
                Text("Au niveau 6, tapez les noms de villes sans majuscule. Les accents et les espaces doivent être saisis.")
                Text("Avec VoiceOver activé, appuyez sur la touche Commande pour réentendre l’élément en cours. Sans VoiceOver, l’élément est affiché à l’écran ; la touche Commande ne déclenche pas de lecture vocale.")

                HStack {
                    Spacer()
                    Button("J’ai compris") { fermer() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(34)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .frame(minWidth: 720, minHeight: 520)
        .accessibilityHidden(!contenuAccessible)
        .onAppear {
            contenuAccessible = false
            titreEnFocus = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                contenuAccessible = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    titreEnFocus = true
                }
            }
        }
        .onExitCommand { fermer() }
    }
}

private struct CaptureEchapGrandeRoue: NSViewRepresentable {
    let actif: Bool
    let action: () -> Void

    func makeCoordinator() -> Coordinateur { Coordinateur() }

    func makeNSView(context: Context) -> NSView {
        let vue = NSView(frame: .zero)
        context.coordinator.mettreAJour(actif: actif, action: action)
        context.coordinator.installerMoniteur()
        return vue
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.mettreAJour(actif: actif, action: action)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinateur) {
        coordinator.retirerMoniteur()
    }

    final class Coordinateur {
        private var moniteur: Any?
        private var actif = false
        private var action: (() -> Void)?

        func mettreAJour(actif: Bool, action: @escaping () -> Void) {
            self.actif = actif
            self.action = action
        }

        func installerMoniteur() {
            guard moniteur == nil else { return }
            moniteur = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] evenement in
                guard let self, self.actif else { return evenement }
                let modificateurs = evenement.modifierFlags
                    .intersection(.deviceIndependentFlagsMask)
                    .intersection([.command, .control, .option, .shift])
                guard evenement.keyCode == 53, modificateurs.isEmpty else { return evenement }
                DispatchQueue.main.async { [weak self] in self?.action?() }
                return nil
            }
        }

        func retirerMoniteur() {
            if let moniteur { NSEvent.removeMonitor(moniteur) }
            moniteur = nil
        }
    }
}

private struct CaptureClavierGrandeRoue: NSViewRepresentable {

    let actif: Bool
    let caractereSaisi: (String) -> Void
    let commandePressee: () -> Void
    let echapPresse: () -> Void

    func makeCoordinator() -> Coordinateur {
        Coordinateur()
    }

    func makeNSView(context: Context) -> VueCaptureGrandeRoue {
        let vue = VueCaptureGrandeRoue()
        vue.caractereSaisi = caractereSaisi
        vue.echapPresse = echapPresse

        context.coordinator.mettreAJour(
            actif: actif,
            commandePressee: commandePressee
        )
        context.coordinator.installerMoniteurCommande()

        return vue
    }

    func updateNSView(
        _ vue: VueCaptureGrandeRoue,
        context: Context
    ) {
        vue.caractereSaisi = caractereSaisi
        vue.echapPresse = echapPresse

        context.coordinator.mettreAJour(
            actif: actif,
            commandePressee: commandePressee
        )

        DispatchQueue.main.async {
            guard let fenetre = vue.window else {
                return
            }

            if actif {
                if fenetre.firstResponder !== vue {
                    fenetre.makeFirstResponder(vue)
                }
            } else if fenetre.firstResponder === vue {
                fenetre.makeFirstResponder(nil)
            }
        }
    }

    static func dismantleNSView(
        _ nsView: VueCaptureGrandeRoue,
        coordinator: Coordinateur
    ) {
        coordinator.retirerMoniteurCommande()
    }

    final class Coordinateur {
        private var moniteurCommande: Any?
        private var actif = false
        private var commandePressee: (() -> Void)?
        private var commandeDejaAnnoncee = false

        func mettreAJour(
            actif: Bool,
            commandePressee: @escaping () -> Void
        ) {
            self.actif = actif
            self.commandePressee = commandePressee

            if !actif {
                commandeDejaAnnoncee = false
            }
        }

        func installerMoniteurCommande() {
            guard moniteurCommande == nil else {
                return
            }

            moniteurCommande = NSEvent.addLocalMonitorForEvents(
                matching: .flagsChanged
            ) { [weak self] evenement in
                guard
                    let self,
                    self.actif
                else {
                    return evenement
                }

                let commandeActive =
                    evenement.modifierFlags.contains(.command)

                if commandeActive {
                    if !self.commandeDejaAnnoncee {
                        self.commandeDejaAnnoncee = true
                        self.commandePressee?()
                    }
                } else {
                    self.commandeDejaAnnoncee = false
                }

                return evenement
            }
        }

        func retirerMoniteurCommande() {
            if let moniteurCommande {
                NSEvent.removeMonitor(moniteurCommande)
                self.moniteurCommande = nil
            }
        }
    }
}

private final class VueCaptureGrandeRoue: NSView {

    var caractereSaisi: ((String) -> Void)?
    var echapPresse: (() -> Void)?

    private var diacritiqueEnAttente: String?

    override var acceptsFirstResponder: Bool {
        true
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(false)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setAccessibilityElement(false)
    }

    override func resignFirstResponder() -> Bool {
        diacritiqueEnAttente = nil
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        // Échap reste le retour contextuel du jeu.
        if event.keyCode == 53 {
            diacritiqueEnAttente = nil
            echapPresse?()
            return
        }

        // Entrée, Retour arrière et Supprimer ne servent pas dans ce jeu.
        if event.keyCode == 36
            || event.keyCode == 76
            || event.keyCode == 51
            || event.keyCode == 117 {
            diacritiqueEnAttente = nil
            return
        }

        // Les raccourcis macOS ne sont pas interprétés comme de la frappe.
        if event.modifierFlags.contains(.command)
            || event.modifierFlags.contains(.control)
            || event.modifierFlags.contains(.option) {
            super.keyDown(with: event)
            return
        }

        let caracteres = event.characters ?? ""
        let caracteresSansModificateur =
            event.charactersIgnoringModifiers ?? ""

        // Gestion des touches mortes ^ et ¨ sur clavier AZERTY.
        if caracteres.isEmpty {
            let estToucheAccent =
                event.keyCode == 33
                || caracteresSansModificateur == "^"
                || caracteresSansModificateur == "¨"

            if estToucheAccent {
                if event.modifierFlags.contains(.shift)
                    || caracteresSansModificateur == "¨" {
                    diacritiqueEnAttente = "\u{0308}"
                } else {
                    diacritiqueEnAttente = "\u{0302}"
                }
                return
            }

            super.keyDown(with: event)
            return
        }

        guard let premier = caracteres.first else {
            return
        }

        var texteSaisi = String(premier)

        if let diacritique = diacritiqueEnAttente {
            let normalise =
                texteSaisi.precomposedStringWithCanonicalMapping

            let contientDejaDiacritique =
                normalise != normalise.folding(
                    options: .diacriticInsensitive,
                    locale: Locale(identifier: "fr_FR")
                )

            if !contientDejaDiacritique {
                texteSaisi =
                    (texteSaisi + diacritique)
                    .precomposedStringWithCanonicalMapping
            } else {
                texteSaisi = normalise
            }

            diacritiqueEnAttente = nil
        } else {
            texteSaisi =
                texteSaisi.precomposedStringWithCanonicalMapping
        }

        caractereSaisi?(texteSaisi)
    }
}

private final class SonGrandeRoue {

    static let shared = SonGrandeRoue()

    private var lecteurPosition: AVAudioPlayer?
    private var lecteurTour: AVAudioPlayer?
    private var dernierPing = Date.distantPast

    private init() {}

    func actualiserBruitRoue(vitesse: Double) {
        guard vitesse > 0.012 else { return }

        // Son grave retenu : même matière sonore à toutes les vitesses.
        // Seule la cadence change, afin que le ralentissement soit perceptible
        // sans transformer le son en bip aigu. À pleine vitesse, on retrouve
        // la cadence de la proposition 05 retenue pendant les essais.
        let vitesseNormalisee = min(max(vitesse / 0.46, 0), 1)
        let intervalle = 1.65 - (1.43 * vitesseNormalisee)
        guard Date().timeIntervalSince(dernierPing) >= intervalle else { return }
        dernierPing = Date()

        guard let url = Bundle.main.url(
            forResource: "GrandeRoue_Rotation_Grave",
            withExtension: "wav"
        ) else { return }

        do {
            lecteurPosition = try AVAudioPlayer(contentsOf: url)
            lecteurPosition?.enableRate = false
            lecteurPosition?.volume = 0.20
            lecteurPosition?.prepareToPlay()
            lecteurPosition?.play()
        } catch {
            return
        }
    }

    func jouerCompteARebours() {
        // Le décompte est annoncé par VoiceOver. Aucun son supplémentaire
        // n'est nécessaire ici.
    }

    func jouerSonTour() {
        guard let url = Bundle.main.url(
            forResource: "Ding_Tour_Complet",
            withExtension: "wav"
        ) else {
            NSSound.beep()
            return
        }

        do {
            lecteurTour = try AVAudioPlayer(contentsOf: url)
            lecteurTour?.volume = 0.20
            lecteurTour?.prepareToPlay()
            lecteurTour?.play()
        } catch {
            NSSound.beep()
        }
    }

    func jouerErreur() {
        // Pas de son d'erreur séparé : la perte immédiate de vitesse et la
        // cadence du son de rotation rendent le ralentissement perceptible.
    }

    func arreterTout() {
        lecteurPosition?.stop()
        lecteurTour?.stop()
        lecteurPosition = nil
        lecteurTour = nil
        dernierPing = Date.distantPast
    }
}
