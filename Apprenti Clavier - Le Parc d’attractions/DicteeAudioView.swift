//
//  DicteeAudioView.swift
//  Apprenti Clavier
//

import SwiftUI
import AppKit
import AVFoundation
import Combine

struct DicteeAudioView: View {

    let retourParcAttractions: () -> Void

    @State private var niveauEnCours: Int?
    @State private var afficherCommentJouer = false
    @State private var niveauMaximumDeverrouille = 1
    @State private var messageInformation = ""
    @State private var exerciceEnCours = false

    @AccessibilityFocusState
    private var titreEnFocus: Bool

    var body: some View {
        Group {
            if let niveau = niveauEnCours,
               let configuration = ConfigurationNiveauDicteeAudio.configuration(numero: niveau) {
                NiveauDicteeAudioView(
                    configuration: configuration,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        if niveau < 10 {
                            deverrouillerNiveau(niveau + 1)
                        }
                    }
                )
            } else {
                accueil
            }
        }
        .background(
            CaptureEchapDicteeAudio(actif: !afficherCommentJouer) {
                if niveauEnCours != nil {
                    guard !exerciceEnCours else {
                        return
                    }

                    niveauEnCours = nil
                    titreEnFocus = true
                } else {
                    retourParcAttractions()
                }
            }
            .frame(width: 0, height: 0)
        )
    }

    private var accueil: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Button("Retour au parc d’attractions") {
                        retourParcAttractions()
                    }
                    Spacer()
                }

                HStack(spacing: 12) {
                    Text("Dictée audio")
                        .font(.largeTitle)
                        .bold()
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($titreEnFocus)
                }

                Text("Écoutez des phrases de grands auteurs dans lesquelles un mot a disparu, puis retrouvez le mot manquant.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 780)

                Button("Comment jouer") {
                    afficherCommentJouer = true
                }

                VStack(spacing: 12) {
                    ForEach(1...10, id: \.self) { numero in
                        if let configuration =
                            ConfigurationNiveauDicteeAudio.configuration(numero: numero) {
                            boutonNiveau(
                                numero: numero,
                                titre: configuration.titre,
                                sousTitre: nil,
                                verrouille: niveauMaximumDeverrouille < numero
                            ) {
                                messageInformation = ""
                                niveauEnCours = numero
                            }
                        }
                    }
                }
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)

                if !messageInformation.isEmpty {
                    Text(messageInformation)
                        .accessibilityHidden(true)
                }
            }
            .padding(36)
        }
        .onAppear {
            chargerProgression()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                titreEnFocus = true
            }
        }
        .sheet(isPresented: $afficherCommentJouer) {
            CommentJouerDicteeAudioView {
                afficherCommentJouer = false
            }
        }
    }

    private func boutonNiveau(
        numero: Int,
        titre: String,
        sousTitre: String?,
        verrouille: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            if verrouille {
                _ = GestionnaireSonsInterface.shared.jouerCadenasVerrouille()
            } else {
                action()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Niveau \(numero)")
                        .font(.headline)
                    Text(titre)
                        .font(.title3)
                    if let sousTitre {
                        Text(sousTitre)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(
                    systemName:
                        verrouille
                        ? "lock.fill"
                        : "chevron.right.circle.fill"
                )
                .foregroundStyle(verrouille ? .red : .accentColor)
                .accessibilityHidden(true)
            }
            .padding(14)
            .background(
                .thinMaterial,
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            libelleAccessibleNiveau(
                numero: numero,
                titre: titre,
                sousTitre: sousTitre,
                verrouille: verrouille
            )
        )
        .accessibilityHint(
            verrouille
            ? "Terminez d’abord le niveau précédent."
            : "Ouvre ce niveau."
        )
    }

    private func libelleAccessibleNiveau(
        numero: Int,
        titre: String,
        sousTitre: String?,
        verrouille: Bool
    ) -> String {
        var morceaux = ["Niveau \(numero)", titre]
        if let sousTitre {
            morceaux.append(sousTitre)
        }
        if verrouille {
            morceaux.append("verrouillé")
        }
        return morceaux.joined(separator: ", ")
    }

    private func annoncerNiveauProchainement(_ numero: Int) {
        let message = "Le niveau \(numero) sera intégré prochainement."
        messageInformation = message
        VoiceOverAnnouncer.annoncerTexte(message)
    }

    private func chargerProgression() {
        guard let utilisateur =
            ProgressionManager.shared.utilisateurActif else {
            niveauMaximumDeverrouille = 1
            return
        }

        let cle = "progressionDicteeAudioParUtilisateurV1"
        let progressions =
            UserDefaults.standard.dictionary(forKey: cle)
            as? [String: Int]
            ?? [:]

        niveauMaximumDeverrouille =
            max(1, progressions[utilisateur] ?? 1)
    }

    private func deverrouillerNiveau(_ numero: Int) {
        niveauMaximumDeverrouille =
            max(niveauMaximumDeverrouille, numero)

        guard let utilisateur =
            ProgressionManager.shared.utilisateurActif else {
            return
        }

        let cle = "progressionDicteeAudioParUtilisateurV1"
        let defaults = UserDefaults.standard
        var progressions =
            defaults.dictionary(forKey: cle) as? [String: Int]
            ?? [:]

        progressions[utilisateur] =
            max(progressions[utilisateur] ?? 1, numero)

        defaults.set(progressions, forKey: cle)
    }
}

private struct CommentJouerDicteeAudioView: View {

    let fermer: () -> Void

    @AccessibilityFocusState
    private var titreEnFocus: Bool
    @State private var contenuAccessible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Comment jouer")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreEnFocus)

                Text("Dans ce jeu, chaque phrase est d’abord lue entièrement, puis une seconde fois avec un bip à la place du mot à retrouver.")
                Text("Après cette seconde lecture, un petit bip différent indique que vous pouvez saisir votre réponse.")
                Text("Saisissez uniquement le mot manquant. Il n’est pas nécessaire d’appuyer sur Entrée : la réponse est validée automatiquement dès que la longueur attendue est atteinte.")
                Text("Avec ou sans VoiceOver, appuyez sur la touche Commande pour réécouter la phrase complète, ou sur la touche Option pour réécouter la phrase avec le mot manquant remplacé par le bip.")
                Text("Les majuscules ne sont pas prises en compte, mais les accents doivent être respectés. Une réponse incorrecte compte pour une erreur.")
                Text("Plus vous progressez, plus les phrases sont nombreuses et le vocabulaire varié. Chaque phrase contient toujours un seul mot à retrouver.")

                if NSWorkspace.shared.isVoiceOverEnabled {
                    Text("Avec VoiceOver, la zone de saisie reste silencieuse pendant la partie afin de ne pas interrompre l’écoute. Les raccourcis de réécoute restent disponibles.")
                }

                HStack {
                    Spacer()
                    Button("J’ai compris") {
                        fermer()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(32)
            .frame(minWidth: 700, minHeight: 500)
        }
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
        .onExitCommand {
            fermer()
        }
    }
}

private struct ConfigurationNiveauDicteeAudio {

    let numero: Int
    let titre: String
    let auteur: String
    let typeOeuvre: String
    let vers: [String]
    let reponses: [String]
    let maximumErreurs: Int

    static func configuration(numero: Int) -> ConfigurationNiveauDicteeAudio? {
        switch numero {
        case 1: return .niveau1
        case 2: return .niveau2
        case 3: return .niveau3
        case 4: return .niveau4
        case 5: return .niveau5
        case 6: return .niveau6
        case 7: return .niveau7
        case 8: return .niveau8
        case 9: return .niveau9
        case 10: return .niveau10
        default: return nil
        }
    }

    static let niveau1 = ConfigurationNiveauDicteeAudio(
        numero: 1,
        titre: "Les fables de La Fontaine",
        auteur: "Jean de La Fontaine",
        typeOeuvre: "sélection de fables",
        vers: [
            "Maître Corbeau, sur un arbre perché.",
            "Tenait en son bec un fromage.",
            "La raison du plus fort est toujours la meilleure.",
            "Un agneau se désaltérait dans le courant d'une onde pure.",
            "Rien ne sert de courir, il faut partir à point.",
            "La cigale, ayant chanté tout l'été.",
            "Le chêne un jour dit au roseau.",
            "Patience et longueur de temps font plus que force ni que rage."
        ],
        reponses: [
            "perché",
            "fromage",
            "meilleure",
            "pure",
            "point",
            "été",
            "roseau",
            "rage"
        ],
        maximumErreurs: 4
    )

    static let niveau2 = ConfigurationNiveauDicteeAudio(
        numero: 2,
        titre: "Les poèmes de Victor Hugo",
        auteur: "Victor Hugo",
        typeOeuvre: "sélection de poèmes",
        vers: [
            "Demain, dès l'aube, à l'heure où blanchit la campagne.",
            "Je partirai. Vois-tu, je sais que tu m'attends.",
            "Je marcherai les yeux fixés sur mes pensées.",
            "Sans rien voir au dehors, sans entendre aucun bruit.",
            "Seul, inconnu, le dos courbé, les mains croisées.",
            "Triste, et le jour pour moi sera comme la nuit.",
            "Je ne regarderai ni l'or du soir qui tombe.",
            "Ni les voiles au loin descendant vers Harfleur.",
            "Et quand j'arriverai, je mettrai sur ta tombe."
        ],
        reponses: [
            "aube",
            "attends",
            "pensées",
            "bruit",
            "croisées",
            "nuit",
            "soir",
            "descendant",
            "tombe"
        ],
        maximumErreurs: 4
    )

    static let niveau3 = ConfigurationNiveauDicteeAudio(
        numero: 3,
        titre: "Le théâtre de Molière",
        auteur: "Molière",
        typeOeuvre: "sélection de répliques",
        vers: [
            "Le petit chat est mort.",
            "Couvrez ce sein que je ne saurais voir.",
            "Que diable allait-il faire dans cette galère ?",
            "Il faut manger pour vivre, et non pas vivre pour manger.",
            "Les anciens, monsieur, sont les anciens, et nous sommes les gens de maintenant.",
            "Je veux qu'on soit sincère, et qu'en homme d'honneur.",
            "La parfaite raison fuit toute extrémité.",
            "Et veut que l'on soit sage avec sobriété.",
            "Plus on aime quelqu'un, moins il faut qu'on le flatte.",
            "Et c'est aimer bien peu que de n'oser déplaire."
        ],
        reponses: [
            "chat",
            "sein",
            "galère",
            "manger",
            "maintenant",
            "sincère",
            "extrémité",
            "sobriété",
            "flatte",
            "déplaire"
        ],
        maximumErreurs: 5
    )

    static let niveau4 = ConfigurationNiveauDicteeAudio(
        numero: 4,
        titre: "Les poèmes de Baudelaire",
        auteur: "Charles Baudelaire",
        typeOeuvre: "sélection de poèmes",
        vers: [
            "Là, tout n'est qu'ordre et beauté.",
            "Luxe, calme et volupté.",
            "La Nature est un temple où de vivants piliers.",
            "Laissent parfois sortir de confuses paroles.",
            "Vaste comme la nuit et comme la clarté.",
            "Qui l'observent avec des regards familiers.",
            "Homme libre, toujours tu chériras la mer.",
            "La mer est ton miroir ; tu contemples ton âme.",
            "Sois sage, ô ma Douleur, et tiens-toi plus tranquille.",
            "Comme de longs échos qui de loin se confondent.",
            "Les parfums, les couleurs et les sons se répondent."
        ],
        reponses: [
            "beauté",
            "volupté",
            "piliers",
            "paroles",
            "clarté",
            "familiers",
            "mer",
            "miroir",
            "Douleur",
            "échos",
            "répondent"
        ],
        maximumErreurs: 5
    )

    static let niveau5 = ConfigurationNiveauDicteeAudio(
        numero: 5,
        titre: "Les poèmes de Rimbaud",
        auteur: "Arthur Rimbaud",
        typeOeuvre: "sélection de poèmes",
        vers: [
            "On n'est pas sérieux, quand on a dix-sept ans.",
            "Un beau soir, foin des bocks et de la limonade.",
            "De la clarté d'un pâle réverbère.",
            "Je m’en allais, les poings dans mes poches crevées.",
            "Par les soirs bleus d'été, j'irai dans les sentiers.",
            "Picoté par les blés, fouler l'herbe menue.",
            "Rêveur, j'en sentirai la fraîcheur à mes pieds.",
            "Je laisserai le vent baigner ma tête nue.",
            "C'est un trou de verdure où chante une rivière.",
            "Accrochant follement aux herbes des haillons.",
            "D'argent ; où le soleil, de la montagne fière.",
            "Luit : c'est un petit val qui mousse de rayons."
        ],
        reponses: [
            "sérieux",
            "limonade",
            "réverbère",
            "poches",
            "sentiers",
            "menue",
            "fraîcheur",
            "baigner",
            "verdure",
            "haillons",
            "soleil",
            "rayons"
        ],
        maximumErreurs: 6
    )

    static let niveau6 = ConfigurationNiveauDicteeAudio(
        numero: 6,
        titre: "Les poèmes de Verlaine",
        auteur: "Paul Verlaine",
        typeOeuvre: "sélection de poèmes",
        vers: [
            "Les sanglots longs des violons de l'automne.",
            "Blessent mon cœur d'une langueur monotone.",
            "Tout suffocant et blême, quand sonne l'heure.",
            "Je me souviens des jours anciens et je pleure.",
            "Et je m'en vais au vent mauvais.",
            "Deçà, delà, pareil à la feuille morte.",
            "Il pleure dans mon cœur comme il pleut sur la ville.",
            "Quelle est cette langueur qui pénètre mon cœur ?",
            "Ô bruit doux de la pluie, par terre et sur les toits.",
            "Pour un cœur qui s'ennuie, ô le chant de la pluie.",
            "Votre âme est un paysage choisi.",
            "Que vont charmant masques et bergamasques.",
            "Joueuses de luth et dansant et quasi."
        ],
        reponses: [
            "violons",
            "langueur",
            "blême",
            "anciens",
            "mauvais",
            "morte",
            "pleure",
            "pénètre",
            "pluie",
            "ennuie",
            "paysage",
            "bergamasques",
            "luth"
        ],
        maximumErreurs: 6
    )

    static let niveau7 = ConfigurationNiveauDicteeAudio(
        numero: 7,
        titre: "Le théâtre de Corneille",
        auteur: "Pierre Corneille",
        typeOeuvre: "sélection de vers",
        vers: [
            "Ô rage ! ô désespoir ! ô vieillesse ennemie !",
            "N'ai-je donc tant vécu que pour cette infamie ?",
            "Et ne suis-je blanchi dans les travaux guerriers.",
            "Que pour voir en un jour flétrir tant de lauriers ?",
            "À vaincre sans péril, on triomphe sans gloire.",
            "Je suis jeune, il est vrai ; mais aux âmes bien nées.",
            "La valeur n'attend point le nombre des années.",
            "Aux âmes bien nées, la valeur n'attend point.",
            "Va, je ne te hais point.",
            "Rodrigue, as-tu du cœur ?",
            "Percé jusques au fond du cœur.",
            "D'une atteinte imprévue aussi bien que mortelle.",
            "Cette obscure clarté qui tombe des étoiles.",
            "Enfin avec le flux nous fait voir trente voiles."
        ],
        reponses: [
            "vieillesse",
            "infamie",
            "guerriers",
            "lauriers",
            "gloire",
            "nées",
            "années",
            "valeur",
            "hais",
            "cœur",
            "fond",
            "mortelle",
            "clarté",
            "voiles"
        ],
        maximumErreurs: 7
    )

    static let niveau8 = ConfigurationNiveauDicteeAudio(
        numero: 8,
        titre: "Le théâtre de Racine",
        auteur: "Jean Racine",
        typeOeuvre: "sélection de vers",
        vers: [
            "Pour qui sont ces serpents qui sifflent sur vos têtes ?",
            "Tout m'afflige et me nuit, et conspire à me nuire.",
            "Un trouble s'éleva dans mon âme éperdue.",
            "Mes yeux ne voyaient plus, je ne pouvais parler.",
            "Je sentis tout mon corps et transir et brûler.",
            "C'est Vénus tout entière à sa proie attachée.",
            "Dans un mois, dans un an, comment souffrirons-nous.",
            "Seigneur, tant de grandeurs ne nous touchent plus guère.",
            "Je t'aimais inconstant, qu'aurais-je fait fidèle ?",
            "Que le jour recommence et que le jour finisse.",
            "Sans que jamais Titus puisse voir Bérénice.",
            "L'impatient Néron cesse de se contraindre.",
            "Las de se faire aimer, il veut se faire craindre.",
            "Ma foi, sur l'avenir bien fou qui se fiera.",
            "Tel qui rit vendredi, dimanche pleurera."
        ],
        reponses: [
            "serpents",
            "conspire",
            "éperdue",
            "parler",
            "transir",
            "proie",
            "souffrirons",
            "grandeurs",
            "fidèle",
            "finisse",
            "Bérénice",
            "contraindre",
            "craindre",
            "avenir",
            "pleurera"
        ],
        maximumErreurs: 7
    )

    static let niveau9 = ConfigurationNiveauDicteeAudio(
        numero: 9,
        titre: "Les poèmes de Musset",
        auteur: "Alfred de Musset",
        typeOeuvre: "sélection de poèmes",
        vers: [
            "Les plus désespérés sont les chants les plus beaux.",
            "Et j'en sais d'immortels qui sont de purs sanglots.",
            "L'homme est un apprenti, la douleur est son maître.",
            "Et nul ne se connaît tant qu'il n'a pas souffert.",
            "Lorsque le pélican, lassé d'un long voyage.",
            "Dans les brouillards du soir retourne à ses roseaux.",
            "Ses petits affamés courent sur le rivage.",
            "En le voyant au loin s'abattre sur les eaux.",
            "Le vent va m'emporter ; je vais quitter la terre.",
            "Laisse-la s'élargir, cette sainte blessure.",
            "Une larme de toi ! Dieu m'écoute ; il est temps.",
            "Rien ne nous rend si grands qu'une grande douleur.",
            "Mais, pour en être atteint, ne crois pas, ô poète.",
            "Que ta voix ici-bas doive rester muette.",
            "Déjà, croyant saisir et partager leur proie.",
            "Ils courent à leur père avec des cris de joie."
        ],
        reponses: [
            "désespérés",
            "immortels",
            "apprenti",
            "souffert",
            "pélican",
            "brouillards",
            "affamés",
            "eaux",
            "emporter",
            "blessure",
            "larme",
            "douleur",
            "atteint",
            "muette",
            "proie",
            "joie"
        ],
        maximumErreurs: 8
    )

    static let niveau10 = ConfigurationNiveauDicteeAudio(
        numero: 10,
        titre: "Le bal des grandes plumes",
        auteur: "Grands auteurs du domaine public",
        typeOeuvre: "sélection de textes",
        vers: [
            "Rien ne sert de courir, il faut partir à point.",
            "Demain, dès l'aube, à l'heure où blanchit la campagne.",
            "Que diable allait-il faire dans cette galère ?",
            "Les parfums, les couleurs et les sons se répondent.",
            "On n'est pas sérieux, quand on a dix-sept ans.",
            "Il pleure dans mon cœur comme il pleut sur la ville.",
            "À vaincre sans péril, on triomphe sans gloire.",
            "Pour qui sont ces serpents qui sifflent sur vos têtes ?",
            "Les plus désespérés sont les chants les plus beaux.",
            "Patience et longueur de temps font plus que force ni que rage.",
            "Je marcherai les yeux fixés sur mes pensées.",
            "La parfaite raison fuit toute extrémité.",
            "La Nature est un temple où de vivants piliers.",
            "C'est un trou de verdure où chante une rivière.",
            "Deçà, delà, pareil à la feuille morte.",
            "Cette obscure clarté qui tombe des étoiles.",
            "Un trouble s'éleva dans mon âme éperdue."
        ],
        reponses: [
            "courir",
            "campagne",
            "diable",
            "couleurs",
            "sérieux",
            "ville",
            "péril",
            "serpents",
            "désespérés",
            "longueur",
            "pensées",
            "extrémité",
            "temple",
            "verdure",
            "feuille",
            "obscure",
            "éperdue"
        ],
        maximumErreurs: 8
    )

    func partiesPhraseATrous(index: Int) -> (avant: String, apres: String)? {
        guard vers.indices.contains(index),
              reponses.indices.contains(index) else {
            return nil
        }

        let phrase = vers[index]
        let reponse = reponses[index]

        guard let plage = phrase.range(
            of: reponse,
            options: [.caseInsensitive, .backwards]
        ) else {
            return nil
        }

        return (
            avant: String(phrase[..<plage.lowerBound]),
            apres: String(phrase[plage.upperBound...])
        )
    }
}

private struct ErreurVersDicteeAudio: Identifiable {

    let id = UUID()
    let numeroVers: Int
    let reponseAttendue: String
    let reponseSaisie: String
    let nombreErreurs: Int
}

private struct NiveauDicteeAudioView: View {

    private enum Etape {
        case presentation
        case compteARebours
        case dictee
        case resultat
    }

    private enum ModeLecture {
        case naturelle
        case detaillee
    }

    let configuration: ConfigurationNiveauDicteeAudio
    let etatExerciceChange: (Bool) -> Void
    let retourNiveaux: () -> Void
    let niveauReussi: () -> Void

    @StateObject
    private var lecteur = LecteurVocalDicteeAudio()

    @State private var etape: Etape = .presentation
    @State private var indexVers = 0
    @State private var ordreVers: [Int] = []
    @State private var saisie = ""
    @State private var nombreErreurs = 0
    @State private var nombreVersParfaits = 0
    @State private var detailsErreurs: [ErreurVersDicteeAudio] = []
    @State private var champAccessibleAvecVoiceOver = false
    @State private var generationLecture = 0
    @State private var niveauDejaValide = false
    @State private var transitionVersEnCours = false
    @State private var compteARebours = 3
    @State private var lectureAutomatiqueEnCours = false
    @State private var debutPeriodeSaisie: Date?
    @State private var tempsSaisieCumule: TimeInterval = 0
    @State private var textesCorrects: [String] = []

    @FocusState private var champEnFocus: Bool

    @AccessibilityFocusState
    private var titreEnFocus: Bool

    @AccessibilityFocusState
    private var zoneNeutreEnFocus: Bool

    private var voiceOverActif: Bool {
        NSWorkspace.shared.isVoiceOverEnabled
    }

    var body: some View {
        VStack(spacing: 24) {
            switch etape {
            case .presentation:
                presentation
            case .compteARebours, .dictee:
                zoneDicteeEtCompteARebours
            case .resultat:
                resultat
            }
        }
        .padding(40)
        .frame(minWidth: 820, minHeight: 620)
        .background(
            CaptureRaccourcisDicteeAudio(
                actif: etape == .dictee,
                commande: {
                    ecouter(.naturelle)
                },
                option: {
                    ecouter(.detaillee)
                },
                commandeVoiceOver: {
                    interromprePourNavigationVoiceOver()
                },
                valider: {
                    validerVers()
                },
                validationActive:
                    champEnFocus
                    && champAccessibleAvecVoiceOver
                    && !transitionVersEnCours
            )
            .frame(width: 0, height: 0)
        )
        .onDisappear {
            etatExerciceChange(false)
            generationLecture += 1
            lecteur.arreter()
        }
    }

    private var descriptionPresentation: String {
        switch configuration.numero {
        case 1:
            return "Retrouvez les mots de quelques-unes des célèbres fables de Jean de La Fontaine."
        case 2:
            return "Parcourez quelques vers parmi les œuvres poétiques de Victor Hugo."
        case 3:
            return "Entrez en scène avec quelques répliques tirées du théâtre de Molière."
        case 4:
            return "Explorez quelques vers issus de l’univers poétique de Charles Baudelaire."
        case 5:
            return "Voyagez à travers quelques vers de la poésie d’Arthur Rimbaud."
        case 6:
            return "Découvrez une sélection de vers écrits par Paul Verlaine."
        case 7:
            return "Retrouvez quelques répliques marquantes du théâtre de Pierre Corneille."
        case 8:
            return "Plongez dans le théâtre de Jean Racine à travers quelques-uns de ses vers."
        case 9:
            return "Laissez-vous porter par quelques vers de la poésie d’Alfred de Musset."
        case 10:
            return "Entrez dans le bal des grandes plumes, où les grands auteurs se retrouvent et leurs vers se mélangent."
        default:
            return ""
        }
    }

    private var presentation: some View {
        VStack(spacing: 22) {
            Text("Niveau \(configuration.numero) — \(configuration.titre)")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titreEnFocus)

            Text(descriptionPresentation)
                .font(.title2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 760)

            Text("Objectif : terminer la dictée avec au maximum \(configuration.maximumErreurs) erreurs.")
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)

            Button("Commencer le niveau") {
                commencerDictee()
            }
            .keyboardShortcut(.defaultAction)

            Button("Retour aux niveaux") {
                retourNiveaux()
            }
        }
        .onAppear {
            titreEnFocus = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                titreEnFocus = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    titreEnFocus = true
                }
            }
        }
    }

    private var dictee: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(nsColor: .textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.45))
                    )

                CaptureSaisieSilencieuseDicteeAudio(
                    active:
                        etape == .dictee
                        && champAccessibleAvecVoiceOver
                        && !lectureAutomatiqueEnCours
                        && !transitionVersEnCours
                        && !lecteur.estEnTrainDeLire,
                    texteSaisi: { texte in
                        traiterSaisieSilencieuse(texte)
                    }
                )
            }
            .frame(maxWidth: 760, minHeight: 48)
            .accessibilityHidden(true)

        }
        .accessibilityHidden(voiceOverActif)
    }

    private var resultat: some View {
        VStack(spacing: 22) {
            VStack(spacing: 16) {
                Text("Résultat du niveau")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreEnFocus)

                Text(messageResultat)
                    .font(.title2)
                    .multilineTextAlignment(.center)

                Text("Réponses : \(configuration.vers.count). Bonnes réponses : \(nombreVersParfaits).")
                    .font(.title3)

                Text("Nombre total d’erreurs : \(nombreErreurs). Maximum autorisé : \(configuration.maximumErreurs).")
                    .font(.title3)

                Text("Appuyez sur Entrée pour revenir à la liste des niveaux.")
                    .font(.headline)


            }
            .accessibilityElement(children: .combine)

            Button("Terminer le niveau") {
                retourNiveaux()
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private var zoneDicteeEtCompteARebours: some View {
        ZStack {
            dictee
                .opacity(etape == .dictee ? 1 : 0)
                .accessibilityHidden(etape != .dictee)

            Text("\(max(compteARebours, 1))")
                .font(.system(size: 110, weight: .bold, design: .rounded))
                .opacity(etape == .compteARebours ? 1 : 0)
                .accessibilityLabel("\(max(compteARebours, 1))")

            // Même point de repos VoiceOver silencieux que dans La Grande Roue.
            // Le focus y est envoyé avant le décompte et n'est plus déplacé
            // automatiquement pendant le passage vers la dictée.
            PointFocusVoiceOverSilencieuxDicteeAudio()
                .frame(width: 2, height: 2)
                .accessibilityFocused($zoneNeutreEnFocus)
        }
    }

    private var indexOriginalCourant: Int? {
        guard ordreVers.indices.contains(indexVers) else {
            return nil
        }
        return ordreVers[indexVers]
    }

    private var versCourant: String {
        guard let indexOriginal = indexOriginalCourant,
              configuration.vers.indices.contains(indexOriginal) else {
            return ""
        }
        return configuration.vers[indexOriginal]
    }

    private var reponseCourante: String {
        guard let indexOriginal = indexOriginalCourant,
              configuration.reponses.indices.contains(indexOriginal) else {
            return ""
        }
        return configuration.reponses[indexOriginal]
    }

    private var objectifAtteint: Bool {
        nombreErreurs <= configuration.maximumErreurs
    }

    private var messageResultat: String {
        if objectifAtteint {
            if configuration.numero < 10 {
                return "Bravo ! Objectif atteint. Le niveau \(configuration.numero + 1) est déverrouillé."
            }
            return "Bravo, vous avez terminé tous les niveaux de Dictée audio !"
        }
        return "Objectif non atteint. Vous pourrez recommencer cette dictée quand vous le souhaitez."
    }

    private func commencerDictee() {
        etatExerciceChange(true)
        ordreVers = Array(configuration.vers.indices).shuffled()
        indexVers = 0
        saisie = ""
        nombreErreurs = 0
        nombreVersParfaits = 0
        detailsErreurs = []
        niveauDejaValide = false
        transitionVersEnCours = false
        lectureAutomatiqueEnCours = false
        compteARebours = 3
        champEnFocus = false
        champAccessibleAvecVoiceOver = false
        debutPeriodeSaisie = nil
        tempsSaisieCumule = 0
        textesCorrects = []
        generationLecture += 1
        lecteur.arreter()

        // Comme dans La Grande Roue, le curseur VoiceOver est déplacé
        // AVANT le décompte vers un point neutre et silencieux.
        titreEnFocus = false
        zoneNeutreEnFocus = false
        etape = .compteARebours

        DispatchQueue.main.async {
            guard etape == .compteARebours else { return }
            zoneNeutreEnFocus = true
        }

        let generationDemandee = generationLecture
        faireCompteARebours(generationDemandee)
    }

    private func faireCompteARebours(_ generationDemandee: Int) {
        guard etape == .compteARebours,
              generationLecture == generationDemandee else {
            return
        }

        if compteARebours > 0 {
            VoiceOverAnnouncer.annoncerTexte("\(compteARebours)")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard etape == .compteARebours,
                      generationLecture == generationDemandee else {
                    return
                }

                compteARebours -= 1
                faireCompteARebours(generationDemandee)
            }
        } else {
            lectureAutomatiqueEnCours = true
            etape = .dictee

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                guard etape == .dictee,
                      generationLecture == generationDemandee else {
                    return
                }
                presenterVersAutomatiquement()
            }
        }
    }

    private func presenterVersAutomatiquement() {
        guard etape == .dictee else { return }

        transitionVersEnCours = false
        lectureAutomatiqueEnCours = true
        generationLecture += 1
        let generationDemandee = generationLecture

        saisie = ""
        champEnFocus = false
        champAccessibleAvecVoiceOver = false

        let delaiAvantLecture: TimeInterval =
            voiceOverActif ? 0.4 : 0.2

        DispatchQueue.main.asyncAfter(
            deadline: .now() + delaiAvantLecture
        ) {
            guard generationLecture == generationDemandee,
                  etape == .dictee else {
                return
            }

            lecteur.lire(versCourant) {
                guard generationLecture == generationDemandee,
                      etape == .dictee else {
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    guard generationLecture == generationDemandee,
                          etape == .dictee else {
                        return
                    }

                    lirePhraseAvecTrou(
                        generationDemandee: generationDemandee
                    ) {
                        guard generationLecture == generationDemandee,
                              etape == .dictee else {
                            return
                        }
                        rendreChampDisponible()
                    }
                }
            }
        }
    }

    private func ecouter(_ mode: ModeLecture) {
        guard etape == .dictee,
              !transitionVersEnCours else {
            return
        }

        suspendreMesureSaisie()
        generationLecture += 1
        let generationDemandee = generationLecture
        champAccessibleAvecVoiceOver = false
        lectureAutomatiqueEnCours = true
        champEnFocus = false
        saisie = ""

        if mode == .naturelle {
            lecteur.lire(versCourant) {
                guard generationLecture == generationDemandee,
                      etape == .dictee else {
                    return
                }
                rendreChampDisponible()
            }
        } else {
            lirePhraseAvecTrou(
                generationDemandee: generationDemandee
            ) {
                guard generationLecture == generationDemandee,
                      etape == .dictee else {
                    return
                }
                rendreChampDisponible()
            }
        }
    }

    private func lirePhraseAvecTrou(
        generationDemandee: Int,
        completion: @escaping () -> Void
    ) {
        guard let indexOriginal = indexOriginalCourant,
              let parties = configuration.partiesPhraseATrous(
                index: indexOriginal
              ) else {
            completion()
            return
        }

        let avant = parties.avant.trimmingCharacters(
            in: .whitespaces
        )
        let apres = parties.apres.trimmingCharacters(
            in: .whitespaces
        )

        lecteur.lire(avant) {
            guard generationLecture == generationDemandee,
                  etape == .dictee else {
                return
            }

            jouerSon(
                frequence: 920.0,
                duree: 0.18,
                volume: 0.28
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                guard generationLecture == generationDemandee,
                      etape == .dictee else {
                    return
                }

                let contientDuTexte = apres.contains {
                    $0.isLetter || $0.isNumber
                }

                if contientDuTexte {
                    lecteur.lire(apres, completion: completion)
                } else {
                    completion()
                }
            }
        }
    }

    private func rendreChampDisponible() {
        champAccessibleAvecVoiceOver = true
        lectureAutomatiqueEnCours = false
        debutPeriodeSaisie = Date()

        jouerSon(
            frequence: 520.0,
            duree: 0.08,
            volume: 0.20
        )
    }

    private func jouerSon(
        frequence: Double,
        duree: Double,
        volume: Double
    ) {
        let tauxEchantillonnage = 44_100.0
        let nombreEchantillons = Int(duree * tauxEchantillonnage)

        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: tauxEchantillonnage,
            channels: 1
        ),
        let tampon = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(nombreEchantillons)
        ),
        let canal = tampon.floatChannelData?[0] else {
            return
        }

        tampon.frameLength = AVAudioFrameCount(nombreEchantillons)

        let dureeFondu = min(0.015, duree / 4)
        let echantillonsFondu = max(
            1,
            Int(dureeFondu * tauxEchantillonnage)
        )

        for index in 0..<nombreEchantillons {
            let temps = Double(index) / tauxEchantillonnage
            var enveloppe = 1.0

            if index < echantillonsFondu {
                enveloppe =
                    Double(index) / Double(echantillonsFondu)
            } else if index >= nombreEchantillons - echantillonsFondu {
                enveloppe =
                    Double(nombreEchantillons - index - 1)
                    / Double(echantillonsFondu)
            }

            canal[index] = Float(
                sin(2.0 * Double.pi * frequence * temps)
                * volume
                * max(0.0, enveloppe)
            )
        }

        SonBipDicteeAudio.shared.jouer(tampon: tampon)
    }

    private func interromprePourNavigationVoiceOver() {
        guard voiceOverActif,
              etape == .dictee,
              lectureAutomatiqueEnCours else {
            return
        }

        generationLecture += 1
        lecteur.arreter()
        transitionVersEnCours = false
        lectureAutomatiqueEnCours = false
        rendreChampDisponible()
    }

    private func traiterSaisieSilencieuse(_ texte: String) {
        guard etape == .dictee,
              champAccessibleAvecVoiceOver,
              !lectureAutomatiqueEnCours,
              !transitionVersEnCours,
              !reponseCourante.isEmpty,
              !texte.isEmpty else {
            return
        }

        let longueurMinimale = reponseCourante.count
        let longueurMaximale = reponseCourante
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "OE")
            .count

        let candidat = saisie + texte
        saisie = candidat

        guard candidat.count >= longueurMinimale else { return }

        let attenduNormalise = normaliserPourComparaison(reponseCourante)
        let candidatNormalise = normaliserPourComparaison(candidat)

        if candidatNormalise == attenduNormalise {
            validerVers(candidat)
            return
        }

        guard candidat.count >= longueurMaximale else { return }
        validerVers(candidat)
    }

    private func validerVers(_ texteSaisi: String? = nil) {
        guard etape == .dictee,
              !transitionVersEnCours else {
            return
        }

        let reponseBrute = texteSaisi ?? saisie

        guard !reponseBrute.isEmpty else {
            VoiceOverAnnouncer.annoncerTexte(
                "Saisissez le mot manquant."
            )
            return
        }

        champEnFocus = false
        saisie = ""

        generationLecture += 1
        lecteur.arreter()

        let attendu = normaliserPourComparaison(reponseCourante)
        let reponse = normaliserPourComparaison(reponseBrute)
        let erreursDuVers = attendu == reponse ? 0 : 1

        suspendreMesureSaisie()

        if erreursDuVers == 0 {
            nombreVersParfaits += 1
            textesCorrects.append(reponseCourante)
        } else {
            nombreErreurs += erreursDuVers
            detailsErreurs.append(
                ErreurVersDicteeAudio(
                    numeroVers: indexVers + 1,
                    reponseAttendue: reponseCourante,
                    reponseSaisie: reponseBrute,
                    nombreErreurs: erreursDuVers
                )
            )
        }

        indexVers += 1

        if indexVers >= ordreVers.count {
            terminerNiveau()
        } else {
            transitionVersEnCours = true
            lectureAutomatiqueEnCours = true
            champAccessibleAvecVoiceOver = false

            let generationDemandee = generationLecture

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard etape == .dictee,
                      transitionVersEnCours,
                      generationLecture == generationDemandee else {
                    return
                }
                presenterVersAutomatiquement()
            }
        }
    }

    private func terminerNiveau() {
        guard etape == .dictee else { return }

        generationLecture += 1
        lecteur.arreter()
        champEnFocus = false
        champAccessibleAvecVoiceOver = false
        transitionVersEnCours = false
        lectureAutomatiqueEnCours = false

        ProgressionManager.shared.enregistrerPartie(
            jeu: .dicteeAudio,
            niveau: configuration.numero,
            reussie: objectifAtteint,
            motsCorrects: textesCorrects.reduce(0) { $0 + ProgressionManager.nombreDeMots(dans: $1) },
            erreursDeFrappe: nombreErreurs,
            caracteresValides: textesCorrects.reduce(0) { $0 + $1.count },
            dureeSaisie: tempsSaisieCumule
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard etape == .dictee else { return }

            etatExerciceChange(false)
            etape = .resultat
            titreEnFocus = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard etape == .resultat else { return }
                titreEnFocus = true
            }

            if objectifAtteint && !niveauDejaValide {
                niveauDejaValide = true
                niveauReussi()
            }
        }
    }

    private func normaliser(_ texte: String) -> String {
        texte
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: " ", with: " ")
            .precomposedStringWithCanonicalMapping
    }

    private func suspendreMesureSaisie() {
        if let debutPeriodeSaisie {
            tempsSaisieCumule += Date().timeIntervalSince(debutPeriodeSaisie)
        }
        debutPeriodeSaisie = nil
    }

    private func normaliserPourComparaison(_ texte: String) -> String {
        normaliser(texte)
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "OE")
            .lowercased()
    }

    private func libelleAccessible(
        _ erreur: ErreurVersDicteeAudio
    ) -> String {
        return "Phrase \(erreur.numeroVers). Réponse attendue : \(erreur.reponseAttendue). Réponse saisie : \(erreur.reponseSaisie)."
    }
}

private struct CaptureSaisieSilencieuseDicteeAudio: NSViewRepresentable {

    let active: Bool
    let texteSaisi: (String) -> Void

    func makeNSView(context: Context) -> VueCaptureSaisieDicteeAudio {
        let vue = VueCaptureSaisieDicteeAudio()
        vue.texteSaisi = texteSaisi
        return vue
    }

    func updateNSView(
        _ vue: VueCaptureSaisieDicteeAudio,
        context: Context
    ) {
        vue.texteSaisi = texteSaisi

        DispatchQueue.main.async {
            guard let fenetre = vue.window else { return }

            if active {
                if fenetre.firstResponder !== vue {
                    fenetre.makeFirstResponder(vue)
                }
            } else if fenetre.firstResponder === vue {
                fenetre.makeFirstResponder(nil)
            }
        }
    }
}

private final class VueCaptureSaisieDicteeAudio: NSView {

    var texteSaisi: ((String) -> Void)?

    // Les touches ^ et ¨ sont des touches mortes sur un clavier AZERTY.
    // On mémorise le diacritique et on l'applique à la lettre suivante,
    // sans considérer la première frappe comme une erreur.
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
        if event.keyCode == 51
            || event.keyCode == 117
            || event.keyCode == 36
            || event.keyCode == 76 {
            diacritiqueEnAttente = nil
            return
        }

        if event.modifierFlags.contains(.command)
            || event.modifierFlags.contains(.control)
            || event.modifierFlags.contains(.option) {
            super.keyDown(with: event)
            return
        }

        let caracteres = event.characters ?? ""
        let caracteresSansModificateur =
            event.charactersIgnoringModifiers ?? ""

        // AppKit renvoie une chaîne vide lors de la première frappe
        // d'une touche morte. Sur AZERTY, ^ / ¨ utilise généralement
        // le keyCode 33.
        if caracteres.isEmpty {
            let estToucheAccent =
                event.keyCode == 33
                || caracteresSansModificateur == "^"
                || caracteresSansModificateur == "¨"

            if estToucheAccent {
                if event.modifierFlags.contains(.shift)
                    || caracteresSansModificateur == "¨" {
                    diacritiqueEnAttente = "\u{0308}" // tréma
                } else {
                    diacritiqueEnAttente = "\u{0302}" // circonflexe
                }

                return
            }

            super.keyDown(with: event)
            return
        }

        var texte = caracteres
            .precomposedStringWithCanonicalMapping

        if let diacritique = diacritiqueEnAttente {
            let contientDejaDiacritique =
                texte !=
                texte.folding(
                    options: .diacriticInsensitive,
                    locale: Locale(identifier: "fr_FR")
                )

            if !contientDejaDiacritique {
                texte =
                    (texte + diacritique)
                    .precomposedStringWithCanonicalMapping
            }

            diacritiqueEnAttente = nil
        }

        texteSaisi?(texte)
    }
}

private struct CaptureEchapDicteeAudio: NSViewRepresentable {

    let actif: Bool
    let action: () -> Void

    func makeCoordinator() -> Coordinateur {
        Coordinateur()
    }

    func makeNSView(context: Context) -> NSView {
        let vue = NSView(frame: .zero)
        context.coordinator.mettreAJour(actif: actif, action: action)
        context.coordinator.installerMoniteur()
        return vue
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.mettreAJour(actif: actif, action: action)
    }

    static func dismantleNSView(
        _ nsView: NSView,
        coordinator: Coordinateur
    ) {
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

                guard evenement.keyCode == 53, modificateurs.isEmpty else {
                    return evenement
                }

                DispatchQueue.main.async { [weak self] in
                    self?.action?()
                }
                return nil
            }
        }

        func retirerMoniteur() {
            if let moniteur {
                NSEvent.removeMonitor(moniteur)
            }
            moniteur = nil
        }
    }
}

private struct CaptureRaccourcisDicteeAudio: NSViewRepresentable {

    let actif: Bool
    let commande: () -> Void
    let option: () -> Void
    let commandeVoiceOver: () -> Void
    let valider: () -> Void
    let validationActive: Bool

    func makeCoordinator() -> Coordinateur {
        Coordinateur()
    }

    func makeNSView(context: Context) -> NSView {
        let vue = NSView(frame: .zero)
        context.coordinator.mettreAJour(
            actif: actif,
            commande: commande,
            option: option,
            commandeVoiceOver: commandeVoiceOver,
            valider: valider,
            validationActive: validationActive
        )
        context.coordinator.installerMoniteur()
        return vue
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.mettreAJour(
            actif: actif,
            commande: commande,
            option: option,
            commandeVoiceOver: commandeVoiceOver,
            valider: valider,
            validationActive: validationActive
        )
    }

    static func dismantleNSView(
        _ nsView: NSView,
        coordinator: Coordinateur
    ) {
        coordinator.retirerMoniteur()
    }

    final class Coordinateur {

        private enum Candidat {
            case commande(UInt16)
            case option(UInt16)
        }

        private let codesCommande: Set<UInt16> = [54, 55]
        private let codesOption: Set<UInt16> = [58, 61]
        private let dureeMaximaleAppui: TimeInterval = 0.45

        private var moniteur: Any?
        private var actif = false
        private var commande: (() -> Void)?
        private var option: (() -> Void)?
        private var commandeVoiceOver: (() -> Void)?
        private var valider: (() -> Void)?
        private var validationActive = false
        private var candidat: Candidat?
        private var debutCandidat: Date?
        private var combinaisonEnCours = false
        private var commandeVoiceOverSignalee = false

        func mettreAJour(
            actif: Bool,
            commande: @escaping () -> Void,
            option: @escaping () -> Void,
            commandeVoiceOver: @escaping () -> Void,
            valider: @escaping () -> Void,
            validationActive: Bool
        ) {
            self.actif = actif
            self.commande = commande
            self.option = option
            self.commandeVoiceOver = commandeVoiceOver
            self.valider = valider
            self.validationActive = validationActive

            if !actif {
                reinitialiserCandidat()
                commandeVoiceOverSignalee = false
            }
        }

        func installerMoniteur() {
            guard moniteur == nil else { return }

            moniteur = NSEvent.addLocalMonitorForEvents(
                matching: [.flagsChanged, .keyDown]
            ) { [weak self] evenement in
                guard let self else { return evenement }

                if self.traiter(evenement) {
                    return nil
                }
                return evenement
            }
        }

        func retirerMoniteur() {
            if let moniteur {
                NSEvent.removeMonitor(moniteur)
            }
            moniteur = nil
        }

        private func traiter(_ evenement: NSEvent) -> Bool {
            guard actif else { return false }

            if evenement.type == .keyDown {
                if evenement.keyCode == 36 || evenement.keyCode == 76 {
                    guard validationActive else { return false }
                    valider?()
                    return true
                }

                if candidat != nil {
                    combinaisonEnCours = true
                    candidat = nil
                    debutCandidat = nil
                }
                return false
            }

            let touchesSuivies: NSEvent.ModifierFlags = [
                .command,
                .option,
                .control,
                .shift
            ]

            let drapeaux = evenement.modifierFlags
                .intersection(.deviceIndependentFlagsMask)
                .intersection(touchesSuivies)

            if drapeaux.contains(.control)
                && drapeaux.contains(.option) {
                reinitialiserCandidat(combinaison: true)

                if !commandeVoiceOverSignalee {
                    commandeVoiceOverSignalee = true
                    DispatchQueue.main.async { [weak self] in
                        self?.commandeVoiceOver?()
                    }
                }
                return false
            }

            commandeVoiceOverSignalee = false

            if let candidat {
                let toucheRelachee: Bool
                switch candidat {
                case .commande(let code):
                    toucheRelachee =
                        evenement.keyCode == code
                        && !drapeaux.contains(.command)
                case .option(let code):
                    toucheRelachee =
                        evenement.keyCode == code
                        && !drapeaux.contains(.option)
                }

                if toucheRelachee {
                    let duree = debutCandidat.map {
                        Date().timeIntervalSince($0)
                    }
                    let actionValide =
                        !combinaisonEnCours
                        && drapeaux.isEmpty
                        && duree.map { $0 <= dureeMaximaleAppui } == true

                    reinitialiserCandidat()

                    if actionValide {
                        DispatchQueue.main.async { [weak self] in
                            switch candidat {
                            case .commande:
                                self?.commande?()
                            case .option:
                                self?.option?()
                            }
                        }
                    }
                    return false
                }

                let drapeauAttendu: NSEvent.ModifierFlags
                switch candidat {
                case .commande:
                    drapeauAttendu = .command
                case .option:
                    drapeauAttendu = .option
                }

                if drapeaux != [drapeauAttendu] {
                    reinitialiserCandidat(combinaison: true)
                }
                return false
            }

            guard !combinaisonEnCours else {
                if drapeaux.isEmpty {
                    combinaisonEnCours = false
                }
                return false
            }

            if codesCommande.contains(evenement.keyCode),
               drapeaux == [.command] {
                candidat = .commande(evenement.keyCode)
                debutCandidat = Date()
            } else if codesOption.contains(evenement.keyCode),
                      drapeaux == [.option] {
                candidat = .option(evenement.keyCode)
                debutCandidat = Date()
            }

            return false
        }

        private func reinitialiserCandidat(
            combinaison: Bool = false
        ) {
            candidat = nil
            debutCandidat = nil
            combinaisonEnCours = combinaison
        }

        deinit {
            retirerMoniteur()
        }
    }
}

@MainActor
private final class SonBipDicteeAudio {

    static let shared = SonBipDicteeAudio()

    private let moteur = AVAudioEngine()
    private let lecteur = AVAudioPlayerNode()
    private var moteurPrepare = false

    private init() {}

    func jouer(tampon: AVAudioPCMBuffer) {
        if !moteurPrepare {
            moteur.attach(lecteur)
            moteur.connect(
                lecteur,
                to: moteur.mainMixerNode,
                format: tampon.format
            )

            do {
                try moteur.start()
                moteurPrepare = true
            } catch {
                return
            }
        }

        lecteur.stop()
        lecteur.scheduleBuffer(tampon, at: nil, options: .interrupts)
        lecteur.play()
    }
}

@MainActor
private final class LecteurVocalDicteeAudio:
    NSObject,
    ObservableObject,
    AVSpeechSynthesizerDelegate {

    @Published
    private(set) var estEnTrainDeLire = false

    private let synthetiseur = AVSpeechSynthesizer()
    private var finLecture: (() -> Void)?
    private var generationLecture = 0
    private var identifiantPhraseCourante: ObjectIdentifier?

    override init() {
        super.init()
        synthetiseur.delegate = self
    }

    func lire(_ texte: String, completion: @escaping () -> Void) {
        arreter()

        generationLecture += 1
        let generationDemandee = generationLecture
        finLecture = completion
        estEnTrainDeLire = true

        let phrase = AVSpeechUtterance(string: texte)
        phrase.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        phrase.rate = AVSpeechUtteranceDefaultSpeechRate
        identifiantPhraseCourante = ObjectIdentifier(phrase)
        synthetiseur.speak(phrase)

        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            guard self.generationLecture == generationDemandee,
                  self.estEnTrainDeLire else {
                return
            }

            self.synthetiseur.stopSpeaking(at: .immediate)
            self.terminerLecture(
                identifiant: ObjectIdentifier(phrase)
            )
        }
    }

    func arreter() {
        generationLecture += 1
        finLecture = nil
        estEnTrainDeLire = false
        identifiantPhraseCourante = nil

        if synthetiseur.isSpeaking {
            synthetiseur.stopSpeaking(at: .immediate)
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        let identifiant = ObjectIdentifier(utterance)

        Task { @MainActor in
            terminerLecture(identifiant: identifiant)
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        let identifiant = ObjectIdentifier(utterance)

        Task { @MainActor in
            terminerLecture(identifiant: identifiant)
        }
    }

    private func terminerLecture(identifiant: ObjectIdentifier) {
        guard estEnTrainDeLire,
              identifiantPhraseCourante == identifiant else {
            return
        }

        estEnTrainDeLire = false
        identifiantPhraseCourante = nil
        let completion = finLecture
        finLecture = nil
        completion?()
    }
}


// MARK: - Point de repos VoiceOver silencieux propre à Dictée audio

private struct PointFocusVoiceOverSilencieuxDicteeAudio: NSViewRepresentable {
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
