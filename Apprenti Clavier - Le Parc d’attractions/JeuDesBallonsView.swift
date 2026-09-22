//
//  JeuDesBallonsKiosqueSansBallonsArriere.swift
//  Apprenti Clavier
//
//  Jeu des ballons
//  Version complète : niveaux 1 à 10
//

import SwiftUI
import AppKit
import AVFoundation

struct JeuDesBallonsView: View {

    let retourParcAttractions: () -> Void

    private enum Ecran {
        case accueil
        case objectif
        case decompte
        case partie
        case resultat
    }

    private struct ConfigurationNiveau {
        let numero: Int
        let elements: [String]
        let nombreBallons: Int
        let objectif: Int
        let dureeMontee: TimeInterval
        let texteObjectif: String
    }

    @State private var ecran: Ecran = .accueil
    @State private var afficherCommentJouer = false
    @State private var niveauMaximumDeverrouille = 1
    @State private var niveauSelectionne = 1

    @State private var elementsPartie: [String] = []
    @State private var indexBallon = 0
    @State private var elementCourant = "a"
    @State private var positionSaisie = 0

    @State private var progressionBallon = 0.0
    @State private var reussites = 0
    @State private var erreursDeFrappe = 0
    @State private var textesCorrects: [String] = []
    @State private var tempsSaisieCumule: TimeInterval = 0
    @State private var ballonsEchappes = 0

    @State private var valeurDecompte = 3
    @State private var generationDecompte = 0

    @State private var timerMontee: Timer?
    @State private var dateDepartBallon = Date()
    @State private var prochainPing: TimeInterval = 0

    @AccessibilityFocusState private var focusTitreAccueil: Bool
    @AccessibilityFocusState private var focusObjectif: Bool
    @AccessibilityFocusState private var focusTitreResultat: Bool
    @AccessibilityFocusState private var focusNiveauListe: Int?
    @AccessibilityFocusState private var focusDecompteSilencieux: Bool

    var body: some View {
        ZStack {
            ArrierePlanJeuDesBallons(
                afficherBallonsDecoratifs: ecran == .accueil
            )
                .ignoresSafeArea()
                .accessibilityHidden(true)

            switch ecran {
            case .accueil:
                accueil
            case .objectif:
                objectif
            case .decompte:
                decompte
            case .partie:
                partie
            case .resultat:
                resultat
            }
        }
        .background {
            CaptureClavierBallons(
                actif: ecran == .partie,
                caractereSaisi: { caractere in
                    traiterCaractere(caractere)
                },
                commandePressee: {
                    reannoncerElement()
                },
                echapPresse: {
                    gererEchap()
                }
            )
            .frame(width: 0, height: 0)
        }
        .onExitCommand {
            gererEchap()
        }
        .sheet(isPresented: $afficherCommentJouer) {
            CommentJouerBallonsView {
                afficherCommentJouer = false
            }
        }
        .onDisappear {
            arreterMontee()
            LecteurSonsBallons.shared.arreterTout()
        }
    }

    // MARK: - Configurations des 10 niveaux

    private func configuration(_ numero: Int) -> ConfigurationNiveau {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz").map(String.init)
        let accents = ["é", "è", "à", "ù", "ç", "â", "ê", "î", "ô", "û", "ë", "ï"]
        let ponctuation = [".", ",", ";", ":", "!", "?", "'", "-"]

        switch numero {
        case 1:
            return ConfigurationNiveau(
                numero: 1,
                elements: alphabet,
                nombreBallons: 26,
                objectif: 21,
                dureeMontee: 6.0,
                texteObjectif:
                    "Les vingt-six lettres de l’alphabet apparaissent dans un ordre aléatoire. Vous disposez de 6 secondes par ballon."
            )

        case 2:
            return ConfigurationNiveau(
                numero: 2,
                elements: [
                    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
                    "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
                    "é", "è", "à", "ù", "ç", "ê"
                ],
                nombreBallons: 26,
                objectif: 22,
                dureeMontee: 5.8,
                texteObjectif:
                    "Lettres simples et lettres accentuées sont mélangées. Vous disposez de 5,8 secondes par ballon."
            )

        case 3:
            return ConfigurationNiveau(
                numero: 3,
                elements: [
                    "a", "e", "i", "o", "u", "r", "t", "n", "s", "l",
                    "é", "è", "à", "ù", "ç", "â", "ê", "î",
                    ".", ",", ";", ":", "!", "?", "'", "-"
                ],
                nombreBallons: 26,
                objectif: 22,
                dureeMontee: 5.6,
                texteObjectif:
                    "Lettres, caractères accentués et signes de ponctuation sont mélangés. Vous disposez de 5,6 secondes par ballon."
            )

        case 4:
            return ConfigurationNiveau(
                numero: 4,
                elements: (
                    alphabet
                    + accents
                    + ponctuation
                ),
                nombreBallons: 26,
                objectif: 23,
                dureeMontee: 5.3,
                texteObjectif:
                    "Lettres, accents et ponctuation peuvent apparaître dans n’importe quel ordre. Vous disposez de 5,3 secondes par ballon."
            )

        case 5:
            return ConfigurationNiveau(
                numero: 5,
                elements: (
                    alphabet
                    + accents
                    + ponctuation
                ),
                nombreBallons: 26,
                objectif: 23,
                dureeMontee: 5.0,
                texteObjectif:
                    "Tous les caractères des niveaux précédents sont mélangés. Vous disposez de 5 secondes par ballon."
            )

        case 6:
            return ConfigurationNiveau(
                numero: 6,
                elements: [
                    "a", "é", "?", "m", "ç", ".", "r", "!",
                    "ami", "bus", "lac", "mur", "été", "île",
                    "chat", "main", "jour", "lune", "rose", "vite",
                    "q", ",", "à", "s", "jeu", "mot"
                ],
                nombreBallons: 20,
                objectif: 16,
                dureeMontee: 6.5,
                texteObjectif:
                    "Des petits mots apparaissent maintenant parmi les caractères isolés. Vous disposez de 6,5 secondes par ballon."
            )

        case 7:
            return ConfigurationNiveau(
                numero: 7,
                elements: [
                    "é", "!", "n", "?", "à", ",",
                    "chat", "porte", "table", "route", "livre", "plage",
                    "été", "forêt", "école", "vélo", "radio", "piano",
                    "m", ".", "ç", "r", "ami", "lune", "soleil", "train"
                ],
                nombreBallons: 20,
                objectif: 17,
                dureeMontee: 6.1,
                texteObjectif:
                    "Les mots deviennent plus présents parmi les caractères isolés. Vous disposez de 6,1 secondes par ballon."
            )

        case 8:
            return ConfigurationNiveau(
                numero: 8,
                elements: [
                    "?", "é", ";", "t", "ù", "!",
                    "maison", "jardin", "clavier", "ballon", "rivière",
                    "étoile", "fenêtre", "musique", "orange", "nuage",
                    "rapide", "sourire", "voyage", "oiseau",
                    ".", "ç", "a", ",", "prairie", "cascade"
                ],
                nombreBallons: 20,
                objectif: 17,
                dureeMontee: 6.3,
                texteObjectif:
                    "Des mots plus longs, parfois accentués, apparaissent parmi les caractères isolés. Vous disposez de 6,3 secondes par ballon."
            )

        case 9:
            return ConfigurationNiveau(
                numero: 9,
                elements: [
                    "a", "é", "?", "ç", ",", "!",
                    "tempête", "cabane", "horizon", "planète", "village",
                    "montagne", "paysage", "océan", "silence", "chemin",
                    "p", ";", "à", ".", "soleil", "lumière",
                    "forêt", "route", "livre", "rivage", "moteur", "nature"
                ],
                nombreBallons: 20,
                objectif: 18,
                dureeMontee: 5.9,
                texteObjectif:
                    "Lettres, accents, ponctuation et mots de différentes longueurs sont mélangés. Vous disposez de 5,9 secondes par ballon."
            )

        default:
            return ConfigurationNiveau(
                numero: 10,
                elements: [
                    "é", "?", "r", "!", "ç", ",",
                    "clavier", "ballon", "musique", "rivière", "montagne",
                    "ordinateur", "aventure", "lumière", "fenêtre",
                    "jardin", "oiseau", "rapide", "voyage", "soleil",
                    ".", "à", ";", "n", "forêt", "orange",
                    "histoire", "parc", "étoile", "route"
                ],
                nombreBallons: 20,
                objectif: 18,
                dureeMontee: 5.5,
                texteObjectif:
                    "Mélange final de caractères et de mots, avec le rythme le plus soutenu du jeu. Vous disposez de 5,5 secondes par ballon."
            )
        }
    }

    // MARK: - Accueil

    private var accueil: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button("Retour au parc d’attractions") {
                            retourParcAttractions()
                        }
                        Spacer()
                    }

                    Spacer(minLength: 12)

                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            Image(systemName: "balloon.2.fill")
                                .font(.system(size: 34))
                                .accessibilityHidden(true)

                            Text("Jeu des ballons")
                                .font(.largeTitle)
                                .bold()
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityFocused($focusTitreAccueil)
                        }

                        Text("Tapez ce qui est indiqué sur le ballon avant qu’il n’atteigne le haut de la fenêtre.")
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
                                    verrouille: niveauMaximumDeverrouille < numero
                                )
                            }
                        }
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 12)
                }
                .padding(36)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
        }
        .onAppear {
            chargerProgression()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusTitreAccueil = true
            }
        }
    }

    private func boutonNiveau(numero: Int, verrouille: Bool) -> some View {
        Button {
            if verrouille {
                _ = GestionnaireSonsInterface.shared.jouerCadenasVerrouille()
                return
            }

            niveauSelectionne = numero
            ecran = .objectif

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                focusObjectif = true
            }
        } label: {
            ZStack {
                Text("Niveau \(numero)")
                    .font(.headline)
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
        .id("niveau-\(numero)-\(verrouille ? "verrouille" : "ouvert")")
        .accessibilityFocused(
            $focusNiveauListe,
            equals: numero
        )
        .accessibilityLabel(
            verrouille
            ? "Niveau \(numero), verrouillé"
            : "Niveau \(numero)"
        )
        .accessibilityHint(
            verrouille
            ? "Terminez d’abord le niveau précédent."
            : "Ouvre ce niveau."
        )
    }

    // MARK: - Objectif

    private var objectif: some View {
        let config = configuration(niveauSelectionne)

        return VStack(spacing: 24) {
            HStack {
                Button("Retour aux niveaux") {
                    ecran = .accueil
                }

                Spacer()
            }

            Spacer()

            VStack(spacing: 18) {
                Text("Niveau \(niveauSelectionne)")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($focusObjectif)

                Text("Objectif du niveau")
                    .font(.title2)
                    .bold()

                Text(config.texteObjectif)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 760)

                Text(
                    "Réussissez au moins \(config.objectif) ballons sur \(config.nombreBallons)."
                )
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)

                Button("Commencer le niveau") {
                    preparerNiveau()
                }
                .keyboardShortcut(.defaultAction)
            }

            Spacer()
        }
        .padding(36)
    }

    // MARK: - Décompte

    private var decompte: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Niveau \(niveauSelectionne)")
                    .font(.title)
                    .bold()

                Text("\(valeurDecompte)")
                    .font(.system(size: 96, weight: .bold))
                    .accessibilityHidden(true)
            }

            PointFocusVoiceOverSilencieuxBallons()
                .frame(width: 2, height: 2)
                .accessibilityFocused($focusDecompteSilencieux)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Partie

    private var partie: some View {
        let config = configuration(niveauSelectionne)

        return GeometryReader { geometry in
            ZStack {
                PointFocusVoiceOverSilencieuxBallons()
                    .frame(width: 2, height: 2)
                    .accessibilityFocused($focusDecompteSilencieux)

                let largeurBallon: CGFloat = 190
                let hauteurBallon: CGFloat = 185
                let margeHaute: CGFloat = 95
                let margeBasse: CGFloat = 85
                let distance = max(
                    1,
                    geometry.size.height
                    - hauteurBallon
                    - margeHaute
                    - margeBasse
                )

                BallonJeu(
                    lettre: elementCourant
                )
                .frame(
                    width: largeurBallon,
                    height: hauteurBallon
                )
                .position(
                    x: geometry.size.width / 2,
                    y:
                        geometry.size.height
                        - margeBasse
                        - progressionBallon * distance
                )
                .accessibilityHidden(true)

                VStack {
                    HStack {
                        Text(
                            "Ballon \(min(indexBallon + 1, config.nombreBallons)) sur \(config.nombreBallons)"
                        )
                        .font(.headline)

                        Spacer()

                        Text("Réussites : \(reussites)")
                        Text("Erreurs : \(erreursDeFrappe)")
                    }
                    .padding(20)
                    .background(.thinMaterial)
                    .accessibilityHidden(true)

                    Spacer()
                }

                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        KiosqueBallons()
                            .frame(width: 250, height: 220)
                            .padding(.trailing, 24)
                            .padding(.bottom, 10)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }

    // MARK: - Résultat

    private var resultat: some View {
        let config = configuration(niveauSelectionne)
        let niveauReussi = reussites >= config.objectif

        let messageResultat: String = {
            if niveauReussi {
                if niveauSelectionne < 10 {
                    return "Bravo ! Objectif atteint. Le niveau \(niveauSelectionne + 1) est maintenant déverrouillé."
                } else {
                    return "Bravo, vous avez terminé tous les niveaux du Jeu des ballons !"
                }
            } else {
                return "Niveau terminé. Objectif non atteint."
            }
        }()

        return VStack(spacing: 22) {
            VStack(spacing: 16) {
                Text("Résultat du niveau")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($focusTitreResultat)

                Text(messageResultat)
                    .font(.title2)
                    .multilineTextAlignment(.center)

                Text(
                    "Ballons éclatés : \(reussites) sur \(config.nombreBallons)."
                )
                .font(.title3)

                Text(
                    "Ballons échappés : \(ballonsEchappes)."
                )
                .font(.title3)

                Text(
                    "Erreurs de frappe : \(erreursDeFrappe)."
                )
                .font(.title3)

                Text("Appuyez sur Entrée pour revenir à la liste des niveaux.")
                    .font(.headline)

                if !niveauReussi {
                    Text(
                        "L’objectif était de faire éclater au moins \(config.objectif) ballons."
                    )
                    .font(.title3)
                    .multilineTextAlignment(.center)
                }
            }
            .accessibilityElement(children: .combine)

            HStack(spacing: 16) {
                Button("Terminer le niveau") {
                    let prochainNiveau =
                        niveauReussi && niveauSelectionne < 10
                        ? niveauSelectionne + 1
                        : nil

                    ecran = .accueil

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        if let prochainNiveau {
                            focusNiveauListe = prochainNiveau
                        } else {
                            focusTitreAccueil = true
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)

                Button("Rejouer") {
                    ecran = .objectif

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        focusObjectif = true
                    }
                }
            }
        }
        .padding(36)
        .onAppear {
            focusTitreResultat = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard ecran == .resultat else {
                    return
                }

                focusTitreResultat = true
            }
        }
    }

    // MARK: - Mécanique

    private func preparerNiveau() {
        arreterMontee()
        LecteurSonsBallons.shared.arreterTout()

        let config = configuration(niveauSelectionne)

        if niveauSelectionne == 1 {
            elementsPartie = config.elements.shuffled()
        } else {
            elementsPartie = construirePartie(
                depuis: config.elements,
                nombre: config.nombreBallons
            )
        }

        indexBallon = 0
        elementCourant = elementsPartie[0]
        positionSaisie = 0
        progressionBallon = 0
        reussites = 0
        erreursDeFrappe = 0
        textesCorrects = []
        tempsSaisieCumule = 0
        ballonsEchappes = 0

        generationDecompte += 1
        valeurDecompte = 3

        focusObjectif = false
        focusDecompteSilencieux = false
        ecran = .decompte

        DispatchQueue.main.async {
            guard ecran == .decompte else { return }
            focusDecompteSilencieux = true
        }

        let generationCourante = generationDecompte

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.6
        ) {
            lancerDecompte(
                generationDemandee: generationCourante
            )
        }
    }

    private func construirePartie(
        depuis banque: [String],
        nombre: Int
    ) -> [String] {
        guard !banque.isEmpty else {
            return ["a"]
        }

        var resultat: [String] = []
        var cycle = banque.shuffled()

        while resultat.count < nombre {
            if cycle.isEmpty {
                cycle = banque.shuffled()
            }

            resultat.append(cycle.removeFirst())
        }

        return resultat
    }

    private func lancerDecompte(
        generationDemandee: Int
    ) {
        guard
            generationDemandee == generationDecompte,
            ecran == .decompte
        else {
            return
        }

        if valeurDecompte > 0 {
            VoiceOverAnnouncer.annoncerTexte(
                "\(valeurDecompte)"
            )

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 1
            ) {
                guard
                    generationDemandee == generationDecompte,
                    ecran == .decompte
                else {
                    return
                }

                valeurDecompte -= 1

                lancerDecompte(
                    generationDemandee: generationDemandee
                )
            }
        } else {
            ecran = .partie

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.15
            ) {
                presenterBallon()
            }
        }
    }

    private func presenterBallon() {
        let config = configuration(niveauSelectionne)

        guard
            ecran == .partie,
            indexBallon < elementsPartie.count
        else {
            return
        }

        arreterMontee()

        elementCourant = elementsPartie[indexBallon]
        positionSaisie = 0
        progressionBallon = 0
        dateDepartBallon = Date()
        prochainPing = 0.75

        LecteurSonsBallons.shared.jouerEffet(
            nom: "BallonApparition"
        )

        let delaiAnnonceVoiceOver: TimeInterval =
            indexBallon == 0 ? 2.0 : 0.15

        VoiceOverAnnouncer.annoncerTexte(
            annoncePour(elementCourant),
            apres: delaiAnnonceVoiceOver
        )

        timerMontee = Timer.scheduledTimer(
            withTimeInterval: 0.05,
            repeats: true
        ) { _ in
            let ecoule = Date().timeIntervalSince(dateDepartBallon)

            let progression = min(
                max(
                    ecoule / config.dureeMontee,
                    0
                ),
                1
            )

            progressionBallon = progression

            gererSignalPosition(
                tempsEcoule: ecoule,
                progression: progression
            )

            if progression >= 1 {
                ballonEchappe()
            }
        }
    }

    private func gererSignalPosition(
        tempsEcoule: TimeInterval,
        progression: Double
    ) {
        guard tempsEcoule >= prochainPing else {
            return
        }

        let intervalle = 0.78 - (0.50 * progression)

        prochainPing =
            tempsEcoule + max(0.28, intervalle)

        let vitesse =
            Float(0.82 + (0.70 * progression))

        LecteurSonsBallons.shared.jouerPing(
            vitesse: vitesse
        )
    }

    private func traiterCaractere(
        _ caractere: String
    ) {
        guard ecran == .partie else {
            return
        }

        let attendu = Array(
            elementCourant
                .precomposedStringWithCanonicalMapping
                .lowercased()
        )

        let saisi =
            caractere
            .precomposedStringWithCanonicalMapping
            .lowercased()

        guard
            positionSaisie < attendu.count,
            let caractereSaisi = saisi.first
        else {
            return
        }

        if caractereSaisi == attendu[positionSaisie] {
            positionSaisie += 1

            if positionSaisie >= attendu.count {
                ballonReussi()
            }
        } else {
            erreursDeFrappe += 1
            positionSaisie = 0
            jouerSonMauvaiseReponse()
        }
    }

    private func ballonReussi() {
        guard ecran == .partie else {
            return
        }

        arreterMontee()
        tempsSaisieCumule += Date().timeIntervalSince(dateDepartBallon)
        reussites += 1
        textesCorrects.append(elementCourant)

        LecteurSonsBallons.shared.jouerEffet(
            nom: "BallonReussi_PopDoux"
        )

        passerAuBallonSuivant(
            apres: 0.48
        )
    }

    private func ballonEchappe() {
        guard ecran == .partie else {
            return
        }

        arreterMontee()
        tempsSaisieCumule += Date().timeIntervalSince(dateDepartBallon)
        ballonsEchappes += 1

        LecteurSonsBallons.shared.jouerEffet(
            nom: "BallonEchappe_Monte"
        )

        passerAuBallonSuivant(
            apres: 0.75
        )
    }

    private func passerAuBallonSuivant(
        apres delai: TimeInterval
    ) {
        indexBallon += 1

        if indexBallon >= elementsPartie.count {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + delai
            ) {
                terminerNiveau()
            }
        } else {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + delai
            ) {
                guard ecran == .partie else {
                    return
                }

                presenterBallon()
            }
        }
    }

    private func terminerNiveau() {
        let config = configuration(niveauSelectionne)

        guard ecran == .partie else {
            return
        }

        arreterMontee()
        NSApp.keyWindow?.makeFirstResponder(nil)

        if reussites >= config.objectif {
            debloquerNiveauSuivant()
        }

        ProgressionManager.shared.enregistrerPartie(
            jeu: .jeuDesBallons,
            niveau: niveauSelectionne,
            reussie: reussites >= config.objectif,
            motsCorrects: textesCorrects.reduce(0) { $0 + ProgressionManager.nombreDeMots(dans: $1) },
            erreursDeFrappe: erreursDeFrappe,
            caracteresValides: textesCorrects.reduce(0) { $0 + $1.count },
            dureeSaisie: tempsSaisieCumule
        )

        ecran = .resultat
    }

    private func reannoncerElement() {
        guard ecran == .partie else {
            return
        }

        VoiceOverAnnouncer.annoncerTexte(
            annoncePour(elementCourant)
        )
    }

    private func annoncePour(_ element: String) -> String {
        switch element {
        case "é":
            return "E accent aigu"
        case "è":
            return "E accent grave"
        case "à":
            return "A accent grave"
        case "ù":
            return "U accent grave"
        case "ç":
            return "C cédille"
        case "â":
            return "A accent circonflexe"
        case "ê":
            return "E accent circonflexe"
        case "î":
            return "I accent circonflexe"
        case "ô":
            return "O accent circonflexe"
        case "û":
            return "U accent circonflexe"
        case "ä":
            return "A tréma"
        case "ë":
            return "E tréma"
        case "ï":
            return "I tréma"
        case "ö":
            return "O tréma"
        case "ü":
            return "U tréma"
        case ".":
            return "point"
        case ",":
            return "virgule"
        case ";":
            return "point-virgule"
        case ":":
            return "deux-points"
        case "!":
            return "point d’exclamation"
        case "?":
            return "point d’interrogation"
        case "'":
            return "apostrophe"
        case "-":
            return "tiret"
        default:
            return element
        }
    }

    private func jouerSonMauvaiseReponse() {
        guard
            let url = Bundle.main.url(
                forResource: "MauvaiseReponse",
                withExtension: "wav"
            ),
            let son = NSSound(
                contentsOf: url,
                byReference: false
            )
        else {
            NSSound.beep()
            return
        }

        son.play()
    }

    private func arreterMontee() {
        timerMontee?.invalidate()
        timerMontee = nil
    }

    // MARK: - Progression

    private func chargerProgression() {
        guard
            let utilisateur =
                ProgressionManager.shared.utilisateurActif
        else {
            niveauMaximumDeverrouille = 1
            return
        }

        let cle =
            "progressionJeuDesBallonsParUtilisateurV1"

        let cleMigration =
            "migrationJeuDesBallonsNiveau2Aout2026"

        var progressions =
            UserDefaults.standard
            .dictionary(forKey: cle) ?? [:]

        let niveauEnregistre: Int

        if let valeur = progressions[utilisateur] as? Int {
            niveauEnregistre = valeur
        } else if let valeur = progressions[utilisateur] as? NSNumber {
            niveauEnregistre = valeur.intValue
        } else {
            niveauEnregistre = 1
        }

        // Migration unique destinée à récupérer le niveau 2
        // déjà validé avant l'arrivée de la version à 10 niveaux.
        // Elle ne s'applique qu'une seule fois au profil actif actuel.
        if !UserDefaults.standard.bool(forKey: cleMigration) {
            let niveauMigre =
                max(
                    niveauEnregistre,
                    2
                )

            progressions[utilisateur] = niveauMigre

            UserDefaults.standard.set(
                progressions,
                forKey: cle
            )

            UserDefaults.standard.set(
                true,
                forKey: cleMigration
            )

            niveauMaximumDeverrouille =
                min(
                    10,
                    niveauMigre
                )

            return
        }

        niveauMaximumDeverrouille =
            min(
                10,
                max(
                    1,
                    niveauEnregistre
                )
            )
    }

    private func debloquerNiveauSuivant() {
        guard niveauSelectionne < 10 else {
            return
        }

        let suivant = niveauSelectionne + 1

        guard
            let utilisateur =
                ProgressionManager.shared.utilisateurActif
        else {
            niveauMaximumDeverrouille =
                max(
                    niveauMaximumDeverrouille,
                    suivant
                )
            return
        }

        let cle =
            "progressionJeuDesBallonsParUtilisateurV1"

        var progressions =
            UserDefaults.standard
            .dictionary(forKey: cle) ?? [:]

        let niveauActuel: Int

        if let valeur = progressions[utilisateur] as? Int {
            niveauActuel = valeur
        } else if let valeur = progressions[utilisateur] as? NSNumber {
            niveauActuel = valeur.intValue
        } else {
            niveauActuel = 1
        }

        progressions[utilisateur] =
            max(
                niveauActuel,
                suivant
            )

        UserDefaults.standard.set(
            progressions,
            forKey: cle
        )

        niveauMaximumDeverrouille =
            max(
                niveauMaximumDeverrouille,
                suivant
            )
    }

    // MARK: - Échap

    private func gererEchap() {
        switch ecran {
        case .accueil:
            retourParcAttractions()

        case .objectif:
            ecran = .accueil

        case .decompte:
            // Le niveau est lancé : Échap est volontairement désactivé
            // jusqu'à l'écran de résultat.
            break

        case .partie:
            // Le niveau est lancé : il faut le terminer.
            // Échap redevient disponible sur l'écran de résultat.
            break

        case .resultat:
            ecran = .accueil

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focusTitreAccueil = true
            }
        }
    }
}


// MARK: - Ballon visuel

private struct BallonJeu: View {

    let lettre: String

    var body: some View {
        VStack(spacing: -2) {
            ZStack {
                Ellipse()
                    .fill(.thinMaterial)

                Ellipse()
                    .stroke(
                        Color.primary.opacity(0.28),
                        lineWidth: 2
                    )

                Text(lettre)
                    .font(
                        .system(
                            size: 58,
                            weight: .bold,
                            design: .rounded
                        )
                    )
            }
            .frame(width: 130, height: 150)

            TriangleBallons()
                .fill(Color.primary.opacity(0.35))
                .frame(width: 16, height: 13)

            Path { path in
                path.move(
                    to: CGPoint(x: 8, y: 0)
                )
                path.addCurve(
                    to: CGPoint(x: 15, y: 48),
                    control1:
                        CGPoint(x: 22, y: 15),
                    control2:
                        CGPoint(x: 0, y: 30)
                )
            }
            .stroke(
                Color.primary.opacity(0.42),
                lineWidth: 2
            )
            .frame(width: 28, height: 50)
        }
    }
}


// MARK: - Capture clavier

private struct CaptureClavierBallons:
    NSViewRepresentable {

    let actif: Bool
    let caractereSaisi: (String) -> Void
    let commandePressee: () -> Void
    let echapPresse: () -> Void

    func makeCoordinator() -> Coordinateur {
        Coordinateur()
    }

    func makeNSView(
        context: Context
    ) -> VueCaptureBallons {
        let vue = VueCaptureBallons()

        vue.caractereSaisi = caractereSaisi
        vue.echapPresse = echapPresse

        context.coordinator.mettreAJour(
            actif: actif,
            commandePressee: commandePressee
        )

        context.coordinator
            .installerMoniteurCommande()

        return vue
    }

    func updateNSView(
        _ vue: VueCaptureBallons,
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
        _ nsView: VueCaptureBallons,
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
            self.commandePressee =
                commandePressee

            if !actif {
                commandeDejaAnnoncee = false
            }
        }

        func installerMoniteurCommande() {
            guard moniteurCommande == nil else {
                return
            }

            moniteurCommande =
                NSEvent.addLocalMonitorForEvents(
                    matching: .flagsChanged
                ) { [weak self] evenement in
                    guard
                        let self,
                        self.actif
                    else {
                        return evenement
                    }

                    let commandeActive =
                        evenement.modifierFlags
                        .contains(.command)

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
                NSEvent.removeMonitor(
                    moniteurCommande
                )
                self.moniteurCommande = nil
            }
        }
    }
}

private final class VueCaptureBallons: NSView {

    var caractereSaisi: ((String) -> Void)?
    var echapPresse: (() -> Void)?

    // Les touches ^ et ¨ sont des touches mortes sur un clavier AZERTY.
    // On mémorise leur signe diacritique et on l'applique à la lettre suivante.
    private var diacritiqueEnAttente: String?

    override var acceptsFirstResponder: Bool {
        true
    }

    override init(
        frame frameRect: NSRect
    ) {
        super.init(frame: frameRect)
        setAccessibilityElement(false)
    }

    required init?(
        coder: NSCoder
    ) {
        super.init(coder: coder)
        setAccessibilityElement(false)
    }

    override func resignFirstResponder() -> Bool {
        diacritiqueEnAttente = nil
        return super.resignFirstResponder()
    }

    override func keyDown(
        with event: NSEvent
    ) {
        // Échap est traité directement ici lorsque la vue de saisie
        // possède le focus. Cela garantit le retour contextuel même
        // pendant le niveau 10 et évite qu'AppKit n'avale la touche.
        if event.keyCode == 53 {
            diacritiqueEnAttente = nil
            echapPresse?()
            return
        }

        // Entrée, Retour arrière et Supprimer
        // ne servent pas dans ce jeu.
        if event.keyCode == 36
            || event.keyCode == 76
            || event.keyCode == 51
            || event.keyCode == 117 {
            diacritiqueEnAttente = nil
            return
        }

        // Les raccourcis Commande, Contrôle et Option
        // ne sont pas considérés comme de la saisie du jeu.
        if event.modifierFlags.contains(.command)
            || event.modifierFlags.contains(.control)
            || event.modifierFlags.contains(.option) {
            super.keyDown(with: event)
            return
        }

        let caracteres = event.characters ?? ""
        let caracteresSansModificateur =
            event.charactersIgnoringModifiers ?? ""

        // AppKit renvoie une chaîne vide pour une touche morte.
        // Sur AZERTY, la touche physique ^ / ¨ correspond normalement
        // au keyCode 33. On garde aussi les caractères pour rester robuste.
        if caracteres.isEmpty {
            let estToucheAccent =
                event.keyCode == 33
                || caracteresSansModificateur == "^"
                || caracteresSansModificateur == "¨"

            if estToucheAccent {
                if event.modifierFlags.contains(.shift)
                    || caracteresSansModificateur == "¨" {
                    // Tréma
                    diacritiqueEnAttente = "\u{0308}"
                } else {
                    // Accent circonflexe
                    diacritiqueEnAttente = "\u{0302}"
                }

                // Important : aucune erreur n'est comptée ici.
                return
            }

            super.keyDown(with: event)
            return
        }

        guard
            let premier = caracteres.first,
            !premier.isWhitespace
        else {
            super.keyDown(with: event)
            return
        }

        var texteSaisi = String(premier)

        if let diacritique = diacritiqueEnAttente {
            // Si macOS nous fournit déjà le caractère composé,
            // on l'utilise tel quel. Sinon, on le compose nous-mêmes.
            let normalise =
                texteSaisi
                .precomposedStringWithCanonicalMapping

            let contientDejaDiacritique =
                normalise !=
                normalise
                .folding(
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
                texteSaisi
                .precomposedStringWithCanonicalMapping
        }

        caractereSaisi?(texteSaisi)
    }
}


// MARK: - Sons du jeu

@MainActor
private final class LecteurSonsBallons {

    static let shared =
        LecteurSonsBallons()

    private var lecteurEffet:
        AVAudioPlayer?

    private var lecteurPing:
        AVAudioPlayer?

    private init() {
    }

    func jouerEffet(
        nom: String
    ) {
        guard
            let url =
                Bundle.main.url(
                    forResource: nom,
                    withExtension: "wav"
                )
        else {
            NSSound.beep()
            return
        }

        do {
            lecteurEffet =
                try AVAudioPlayer(
                    contentsOf: url
                )
            lecteurEffet?.prepareToPlay()
            lecteurEffet?.play()
        } catch {
            NSSound.beep()
        }
    }

    func jouerPing(
        vitesse: Float
    ) {
        guard
            let url =
                Bundle.main.url(
                    forResource:
                        "BallonPosition_Ping",
                    withExtension: "wav"
                )
        else {
            return
        }

        do {
            lecteurPing =
                try AVAudioPlayer(
                    contentsOf: url
                )

            lecteurPing?.enableRate = true
            lecteurPing?.rate =
                min(
                    max(vitesse, 0.75),
                    1.65
                )

            lecteurPing?.volume = 0.55
            lecteurPing?.prepareToPlay()
            lecteurPing?.play()
        } catch {
            return
        }
    }

    func arreterTout() {
        lecteurEffet?.stop()
        lecteurPing?.stop()
        lecteurEffet = nil
        lecteurPing = nil
    }
}


// MARK: - Décor fête foraine

private struct ArrierePlanJeuDesBallons:
    View {

    let afficherBallonsDecoratifs: Bool

    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors:
                        colorScheme == .dark
                        ? [
                            Color(
                                red: 0.03,
                                green: 0.08,
                                blue: 0.18
                            ),
                            Color(
                                red: 0.10,
                                green: 0.18,
                                blue: 0.34
                            ),
                            Color(
                                red: 0.22,
                                green: 0.16,
                                blue: 0.28
                            )
                        ]
                        : [
                            Color(
                                red: 0.40,
                                green: 0.73,
                                blue: 0.96
                            ),
                            Color(
                                red: 0.72,
                                green: 0.88,
                                blue: 0.98
                            ),
                            Color(
                                red: 0.96,
                                green: 0.79,
                                blue: 0.55
                            )
                        ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                GrandeRoueBallons(
                    colorScheme: colorScheme
                )
                .frame(
                    width: 270,
                    height: 270
                )
                .position(
                    x: geometry.size.width * 0.16,
                    y: geometry.size.height * 0.69
                )

                if afficherBallonsDecoratifs {
                    BallonsFlottantsArrierePlan()
                        .accessibilityHidden(true)
                }

                VStack {
                    Spacer()

                    Rectangle()
                        .fill(
                            colorScheme == .dark
                            ? Color(
                                red: 0.03,
                                green: 0.12,
                                blue: 0.08
                            ).opacity(0.76)
                            : Color(
                                red: 0.22,
                                green: 0.52,
                                blue: 0.22
                            ).opacity(0.52)
                        )
                        .frame(
                            height:
                                max(
                                    90,
                                    geometry.size.height
                                    * 0.16
                                )
                        )
                }
            }
        }
    }
}

private struct GrandeRoueBallons: View {

    let colorScheme: ColorScheme

    private let couleursNacelles: [Color] = [
        .red, .orange, .yellow, .green,
        .mint, .blue, .purple, .pink
    ]

    var body: some View {
        GeometryReader { geometry in
            let largeur = geometry.size.width
            let hauteur = geometry.size.height
            let centre = CGPoint(x: largeur * 0.50, y: hauteur * 0.45)
            let rayon = min(largeur, hauteur) * 0.37

            ZStack {
                // Deux pieds donnent à la roue une vraie assise sur le sol.
                Path { path in
                    path.move(to: centre)
                    path.addLine(to: CGPoint(x: largeur * 0.30, y: hauteur * 0.98))
                    path.move(to: centre)
                    path.addLine(to: CGPoint(x: largeur * 0.70, y: hauteur * 0.98))
                    path.move(to: CGPoint(x: largeur * 0.22, y: hauteur * 0.98))
                    path.addLine(to: CGPoint(x: largeur * 0.78, y: hauteur * 0.98))
                }
                .stroke(
                    colorScheme == .dark
                    ? Color.white.opacity(0.30)
                    : Color.black.opacity(0.24),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )

                Circle()
                    .stroke(
                        colorScheme == .dark
                        ? Color.white.opacity(0.34)
                        : Color.black.opacity(0.25),
                        lineWidth: 6
                    )
                    .frame(width: rayon * 2, height: rayon * 2)
                    .position(centre)

                ForEach(0..<8, id: \.self) { index in
                    let angle = Double(index) * Double.pi / 4
                    let x = centre.x + CGFloat(cos(angle)) * rayon
                    let y = centre.y + CGFloat(sin(angle)) * rayon

                    Path { path in
                        path.move(to: centre)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    .stroke(
                        colorScheme == .dark
                        ? Color.white.opacity(0.25)
                        : Color.black.opacity(0.17),
                        lineWidth: 4
                    )

                    NacelleBallons(couleur: couleursNacelles[index])
                        .frame(
                            width: largeur * 0.105,
                            height: hauteur * 0.085
                        )
                        .position(x: x, y: y)
                }

                Circle()
                    .fill(
                        colorScheme == .dark
                        ? Color.white.opacity(0.48)
                        : Color.black.opacity(0.30)
                    )
                    .frame(width: 24, height: 24)
                    .position(centre)
            }
        }
    }
}

private struct NacelleBallons: View {

    let couleur: Color

    var body: some View {
        VStack(spacing: -2) {
            Capsule()
                .fill(couleur.opacity(0.92))
                .frame(height: 6)

            RoundedRectangle(cornerRadius: 5)
                .fill(couleur.opacity(0.78))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white.opacity(0.48), lineWidth: 1)
                }
        }
    }
}

private struct BallonsFlottantsArrierePlan: View {

    var body: some View {
        GeometryReader { geometry in
            let positions: [CGPoint] = [
                CGPoint(x: geometry.size.width * 0.06, y: geometry.size.height * 0.17),
                CGPoint(x: geometry.size.width * 0.14, y: geometry.size.height * 0.27),
                CGPoint(x: geometry.size.width * 0.91, y: geometry.size.height * 0.18),
                CGPoint(x: geometry.size.width * 0.96, y: geometry.size.height * 0.34),
                CGPoint(x: geometry.size.width * 0.88, y: geometry.size.height * 0.49),
                CGPoint(x: geometry.size.width * 0.07, y: geometry.size.height * 0.45)
            ]
            let couleurs: [Color] = [
                .red, .yellow, .blue, .green, .orange, .purple
            ]
            let tailles: [CGSize] = [
                CGSize(width: 54, height: 68),
                CGSize(width: 44, height: 56),
                CGSize(width: 58, height: 72),
                CGSize(width: 46, height: 59),
                CGSize(width: 52, height: 66),
                CGSize(width: 42, height: 54)
            ]

            ForEach(0..<positions.count, id: \.self) { index in
                BallonDecoratif(couleur: couleurs[index])
                    .frame(
                        width: tailles[index].width,
                        height: tailles[index].height + 48
                    )
                    .position(positions[index])
            }
        }
    }
}

private struct BallonDecoratif: View {

    let couleur: Color

    var body: some View {
        GeometryReader { geometry in
            let largeur = geometry.size.width
            let hauteurBallon = geometry.size.height - 48

            ZStack(alignment: .top) {
                VStack(spacing: -1) {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    couleur.opacity(0.92),
                                    couleur.opacity(0.60)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Ellipse()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                        }
                        .frame(width: largeur, height: hauteurBallon)

                    TriangleBallons()
                        .fill(couleur.opacity(0.82))
                        .frame(width: largeur * 0.22, height: 9)

                    Path { path in
                        path.move(to: CGPoint(x: largeur * 0.50, y: 0))
                        path.addCurve(
                            to: CGPoint(x: largeur * 0.42, y: 37),
                            control1: CGPoint(x: largeur * 0.72, y: 10),
                            control2: CGPoint(x: largeur * 0.25, y: 24)
                        )
                    }
                    .stroke(Color.primary.opacity(0.38), lineWidth: 1.4)
                    .frame(width: largeur, height: 38)
                }
            }
        }
        .opacity(0.76)
    }
}

private struct KiosqueBallons: View {

    var body: some View {
        ZStack(alignment: .bottom) {
            // Kiosque sans ballons à l’arrière : enseigne, toit, montants, fenêtre et comptoir.
            VStack(spacing: 0) {
                Text("KIOSQUE À BALLONS")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: 174, height: 27)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.red.opacity(0.94))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.white.opacity(0.72), lineWidth: 2)
                    }

                ToitKiosqueBallons()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.red.opacity(0.96),
                                Color.yellow.opacity(0.94),
                                Color.blue.opacity(0.92),
                                Color.green.opacity(0.92),
                                Color.red.opacity(0.96)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        ToitKiosqueBallons()
                            .stroke(Color.white.opacity(0.64), lineWidth: 2)
                    }
                    .frame(width: 220, height: 45)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.brown.opacity(0.88))
                        .frame(width: 184, height: 112)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.34))
                        .frame(width: 126, height: 66)
                        .overlay {
                            HStack(spacing: 11) {
                                Image(systemName: "balloon.fill")
                                    .foregroundStyle(Color.red)
                                Image(systemName: "balloon.fill")
                                    .foregroundStyle(Color.yellow)
                                Image(systemName: "balloon.fill")
                                    .foregroundStyle(Color.blue)
                            }
                            .font(.system(size: 28))
                        }
                        .offset(y: -30)

                    HStack {
                        Capsule()
                            .fill(Color.brown)
                            .frame(width: 13, height: 104)
                        Spacer()
                        Capsule()
                            .fill(Color.brown)
                            .frame(width: 13, height: 104)
                    }
                    .frame(width: 174)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.48, green: 0.23, blue: 0.10))
                        .frame(width: 204, height: 22)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color.white.opacity(0.20))
                                .frame(height: 3)
                        }
                        .offset(y: -27)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.38, green: 0.17, blue: 0.07))
                        .frame(width: 184, height: 29)
                        .overlay {
                            HStack(spacing: 16) {
                                Circle().fill(Color.red).frame(width: 9, height: 9)
                                Circle().fill(Color.yellow).frame(width: 9, height: 9)
                                Circle().fill(Color.blue).frame(width: 9, height: 9)
                                Circle().fill(Color.green).frame(width: 9, height: 9)
                            }
                        }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ToitKiosqueBallons: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.15, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.85, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.72))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.88, y: rect.height),
            control: CGPoint(x: rect.width * 0.96, y: rect.height)
        )
        path.addLine(to: CGPoint(x: rect.width * 0.12, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height * 0.72),
            control: CGPoint(x: rect.width * 0.04, y: rect.height)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Fenêtre Comment jouer

struct CommentJouerBallonsView:
    View {

    let fermer: () -> Void

    @AccessibilityFocusState
    private var titreEnFocus: Bool
    @State private var contenuAccessible = false

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            Text("Comment jouer")
                .font(.largeTitle)
                .bold()
                .accessibilityAddTraits(
                    .isHeader
                )
                .accessibilityFocused(
                    $titreEnFocus
                )

            Text(
                "Dans ce jeu, un seul ballon apparaît à la fois. Tapez au clavier l’élément indiqué avant que le ballon n’atteigne le haut de la fenêtre."
            )

            Text(
                "Une mauvaise frappe compte comme une erreur, mais le ballon continue de monter : vous pouvez donc vous corriger tant qu’il n’a pas atteint le haut."
            )

            Text(
                "Des repères sonores vous accompagnent pendant la partie : un son signale le lancement d’un nouveau ballon, puis un signal sonore vous permet de suivre sa montée. Ce signal devient plus rapide et plus aigu lorsque le ballon approche du haut."
            )

            Text(
                "Une mauvaise frappe déclenche le son d’erreur. Un son différent signale qu’un ballon est réussi, et un autre vous avertit lorsqu’il atteint le haut de la fenêtre et est perdu."
            )

            Text(
                "Avec VoiceOver activé, appuyez sur la touche Commande pour réentendre l’élément du ballon. Sans VoiceOver, l’élément est affiché à l’écran ; la touche Commande ne déclenche pas de lecture vocale."
            )

            HStack {
                Spacer()

                Button("J’ai compris") {
                    fermer()
                }
                .keyboardShortcut(
                    .defaultAction
                )
            }
        }
        .padding(34)
        .frame(width: 650)
        .accessibilityHidden(!contenuAccessible)
        .onAppear {
            // La feuille peut donner spontanément le focus au premier paragraphe.
            // On attend sa présentation complète puis on place explicitement
            // VoiceOver sur le titre, afin que l’utilisateur lise les règles
            // à son propre rythme.
            contenuAccessible = false
            titreEnFocus = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                contenuAccessible = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    titreEnFocus = true
                }
            }
        }
        .onExitCommand {
            fermer()
        }
    }
}


// MARK: - Forme utilitaire

private struct TriangleBallons:
    Shape {

    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        path.move(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.minY
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: rect.maxX,
                    y: rect.maxY
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: rect.minX,
                    y: rect.maxY
                )
        )

        path.closeSubpath()
        return path
    }
}



// MARK: - Point de repos VoiceOver silencieux du Jeu des ballons

private struct PointFocusVoiceOverSilencieuxBallons: NSViewRepresentable {
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
