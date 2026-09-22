//
//  DefiEclairView.swift
//  Apprenti Clavier
//

import SwiftUI
import AppKit
import AVFoundation
import Combine

struct DefiEclairView: View {

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
            if niveauEnCours == 1 {
                NiveauSaisieDefiEclair(
                    configuration: .alphabet,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        deverrouillerNiveau(2)
                    }
                )
            } else if niveauEnCours == 2 {
                NiveauSaisieDefiEclair(
                    configuration: .motsTroisLettres,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        deverrouillerNiveau(3)
                    }
                )
            } else if niveauEnCours == 3 {
                NiveauSaisieDefiEclair(
                    configuration: .motsQuatreLettres,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        deverrouillerNiveau(4)
                    }
                )
            } else if niveauEnCours == 4 {
                NiveauSaisieDefiEclair(
                    configuration: .motsCinqLettres,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        deverrouillerNiveau(5)
                    }
                )
            } else if niveauEnCours == 5 {
                NiveauSaisieDefiEclair(
                    configuration: .motsLongs,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        deverrouillerNiveau(6)
                    }
                )
            } else if niveauEnCours == 6 {
                NiveauSaisieDefiEclair(
                    configuration: .motsAvecMajuscule,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        deverrouillerNiveau(7)
                    }
                )
            } else if niveauEnCours == 7 {
                NiveauSaisieDefiEclair(
                    configuration: .motsAccentes,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        deverrouillerNiveau(8)
                    }
                )
            } else if niveauEnCours == 8 {
                NiveauSaisieDefiEclair(
                    configuration: .groupesDeuxMots,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        deverrouillerNiveau(9)
                    }
                )
            } else if niveauEnCours == 9 {
                NiveauSaisieDefiEclair(
                    configuration: .ponctuation,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {
                        deverrouillerNiveau(10)
                    }
                )
            } else if niveauEnCours == 10 {
                NiveauSaisieDefiEclair(
                    configuration: .grandMelange,
                    etatExerciceChange: { exerciceEnCours = $0 },
                    retourNiveaux: {
                        exerciceEnCours = false
                        niveauEnCours = nil
                        titreEnFocus = true
                    },
                    niveauReussi: {}
                )
            } else {
                accueil
            }
        }
        .background(
            CaptureEchapDefiEclair(actif: !afficherCommentJouer) {
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

                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.yellow)
                        .accessibilityHidden(true)

                    Text("Défi éclair")
                        .font(.largeTitle)
                        .bold()
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($titreEnFocus)
                }

                Text("Défi éclair met votre rapidité et votre précision à l’épreuve. Saisissez le plus vite possible les lettres, les mots et les signes proposés. Chaque niveau possède son propre objectif.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 760)

                Button("Comment jouer") {
                    afficherCommentJouer = true
                }

                VStack(spacing: 12) {
                    boutonNiveau(
                        numero: 1,
                        titre: "L’alphabet",
                        verrouille: false
                    ) {
                        messageInformation = ""
                        niveauEnCours = 1
                    }

                    boutonNiveau(numero: 2, titre: "Les mots de trois lettres", verrouille: niveauMaximumDeverrouille < 2) {
                        messageInformation = ""
                        niveauEnCours = 2
                    }
                    boutonNiveau(numero: 3, titre: "Les mots de quatre lettres", verrouille: niveauMaximumDeverrouille < 3) {
                        messageInformation = ""
                        niveauEnCours = 3
                    }
                    boutonNiveau(numero: 4, titre: "Les mots de cinq lettres", verrouille: niveauMaximumDeverrouille < 4) {
                        messageInformation = ""
                        niveauEnCours = 4
                    }
                    boutonNiveau(numero: 5, titre: "Les mots longs", verrouille: niveauMaximumDeverrouille < 5) {
                        messageInformation = ""
                        niveauEnCours = 5
                    }
                    boutonNiveau(numero: 6, titre: "Les mots avec une majuscule", verrouille: niveauMaximumDeverrouille < 6) {
                        messageInformation = ""
                        niveauEnCours = 6
                    }
                    boutonNiveau(numero: 7, titre: "Les mots accentués", verrouille: niveauMaximumDeverrouille < 7) {
                        messageInformation = ""
                        niveauEnCours = 7
                    }
                    boutonNiveau(numero: 8, titre: "Les groupes de deux mots", verrouille: niveauMaximumDeverrouille < 8) {
                        messageInformation = ""
                        niveauEnCours = 8
                    }
                    boutonNiveau(numero: 9, titre: "La ponctuation", verrouille: niveauMaximumDeverrouille < 9) {
                        messageInformation = ""
                        niveauEnCours = 9
                    }
                    boutonNiveau(numero: 10, titre: "Le grand mélange", verrouille: niveauMaximumDeverrouille < 10) {
                        messageInformation = ""
                        niveauEnCours = 10
                    }
                }
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)

                if !messageInformation.isEmpty {
                    Text(messageInformation)
                        .accessibilityHidden(true)
                }
            }
            .padding(36)
        }
        .onAppear {
            chargerProgressionDefiEclair()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                titreEnFocus = true
            }
        }
        .sheet(isPresented: $afficherCommentJouer) {
            CommentJouerDefiEclairView {
                afficherCommentJouer = false
            }
        }
    }

    private func boutonNiveau(
        numero: Int,
        titre: String,
        verrouille: Bool,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            if verrouille {
                _ = GestionnaireSonsInterface.shared.jouerCadenasVerrouille()
            } else {
                action?()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Niveau \(numero)")
                        .font(.headline)
                    Text(titre)
                        .font(.title3)
                }

                Spacer()

                Image(systemName: verrouille ? "lock.fill" : "chevron.right.circle.fill")
                    .foregroundStyle(verrouille ? .red : .accentColor)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            verrouille
            ? "Niveau \(numero), \(titre), verrouillé"
            : "Niveau \(numero), \(titre)"
        )
        .accessibilityHint(
            verrouille
            ? "Terminez d’abord le niveau précédent."
            : "Ouvre ce niveau."
        )
    }

    private func annoncerNiveauProchainement(_ numero: Int) {
        let message = "Le niveau \(numero) sera intégré prochainement."
        messageInformation = message
        VoiceOverAnnouncer.annoncerTexte(message)
    }

    private func chargerProgressionDefiEclair() {
        guard let utilisateur =
            ProgressionManager.shared.utilisateurActif else {
            niveauMaximumDeverrouille = 1
            return
        }

        let cle = "progressionDefiEclairParUtilisateurV1"
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

        let cle = "progressionDefiEclairParUtilisateurV1"
        let defaults = UserDefaults.standard
        var progressions =
            defaults.dictionary(forKey: cle) as? [String: Int]
            ?? [:]

        progressions[utilisateur] =
            max(progressions[utilisateur] ?? 1, numero)

        defaults.set(progressions, forKey: cle)
    }
}

private struct CommentJouerDefiEclairView: View {

    let fermer: () -> Void

    @AccessibilityFocusState
    private var titreEnFocus: Bool
    @State private var contenuAccessible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Comment jouer")
                .font(.largeTitle)
                .bold()
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titreEnFocus)

            Text("Dans ce jeu, saisissez les éléments proposés aussi rapidement et précisément que possible.")

            Text("Il n’est pas nécessaire d’appuyer sur Entrée pour valider. Dès que le nombre de caractères attendu est saisi, la réponse est enregistrée silencieusement et l’élément suivant apparaît. Les résultats sont annoncés uniquement à la fin du niveau.")

            Text("Avec VoiceOver activé, appuyez puis relâchez la touche Commande seule pour réécouter le caractère, le mot ou l’élément en cours. Cette répétition volontaire ne suspend pas le chronomètre. Sans VoiceOver, l’élément est affiché à l’écran ; la touche Commande ne déclenche pas de lecture vocale.")

            if NSWorkspace.shared.isVoiceOverEnabled {
                Text("Avec VoiceOver, chaque élément est lu automatiquement. La zone de saisie reste volontairement silencieuse et n’est pas annoncée comme un champ de texte. Dès que la voix du jeu a terminé d’énoncer la lettre, le mot ou l’élément demandé, saisissez-le directement au clavier : la zone de saisie est déjà active.")
            }

            Button("J’ai compris") {
                fermer()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(34)
        .frame(width: 650)
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

private struct ConfigurationNiveauDefiEclair {

    let numero: Int
    let titre: String
    let presentation: String
    let elementsDisponibles: [String]
    let nombreElements: Int
    let objectif: Int
    let duree: Int
    let prefixeAnnonce: String
    let inviteSaisie: String
    let afficherEnMajuscules: Bool
    let nomElements: String
    let uniteVitesse: String

    static let alphabet = ConfigurationNiveauDefiEclair(
        numero: 1,
        titre: "L’alphabet",
        presentation: "Tapez les 26 lettres de l’alphabet présentées dans un ordre aléatoire.",
        elementsDisponibles:
            Array("abcdefghijklmnopqrstuvwxyz").map(String.init),
        nombreElements: 26,
        objectif: 20,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez la lettre",
        afficherEnMajuscules: true,
        nomElements: "Lettres saisies",
        uniteVitesse: "lettres par minute"
    )

    static let motsTroisLettres = ConfigurationNiveauDefiEclair(
        numero: 2,
        titre: "Les mots de trois lettres",
        presentation: "Tapez 20 mots courants de trois lettres présentés dans un ordre aléatoire.",
        elementsDisponibles: [
            "arc", "bac", "bol", "bus", "but", "cap",
            "car", "coq", "cri", "dos", "fil", "gaz",
            "jus", "lac", "lot", "nid", "pic", "pie",
            "pli", "roc", "sac", "ski", "sud", "tas",
            "tir", "tri", "zip", "zoo"
        ],
        nombreElements: 20,
        objectif: 15,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez le mot",
        afficherEnMajuscules: false,
        nomElements: "Mots saisis",
        uniteVitesse: "mots par minute"
    )

    static let motsQuatreLettres = ConfigurationNiveauDefiEclair(
        numero: 3,
        titre: "Les mots de quatre lettres",
        presentation: "Tapez 20 mots courants de quatre lettres présentés dans un ordre aléatoire.",
        elementsDisponibles: [
            "abri", "chef", "bloc", "cave", "ciel", "cage",
            "judo", "dame", "drap", "dune", "film", "four",
            "gant", "gare", "grue", "jupe", "kiwi", "lama",
            "lion", "lune", "menu", "miel", "mode", "nage",
            "note", "ours", "page", "parc", "pile", "plan",
            "puma", "robe", "rose", "pion", "tuba", "vase",
            "yoga"
        ],
        nombreElements: 20,
        objectif: 15,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez le mot",
        afficherEnMajuscules: false,
        nomElements: "Mots saisis",
        uniteVitesse: "mots par minute"
    )

    static let motsCinqLettres = ConfigurationNiveauDefiEclair(
        numero: 4,
        titre: "Les mots de cinq lettres",
        presentation: "Tapez 20 mots courants de cinq lettres présentés dans un ordre aléatoire.",
        elementsDisponibles: [
            "arbre", "bague", "barbe", "bocal", "bijou", "botte",
            "boule", "cadre", "carte", "chien", "cidre", "corde",
            "coude", "crabe", "dinde", "doigt", "farce", "femme",
            "fleur", "forme", "fruit", "glace", "herbe", "image",
            "jambe", "lampe", "lapin", "livre", "melon", "monde",
            "neige", "nuage", "olive", "ombre", "plage", "plume",
            "poire", "pomme", "robot", "salon", "savon", "singe",
            "sucre", "tasse", "terre", "tigre", "vague", "ville",
            "vitre", "wagon"
        ],
        nombreElements: 20,
        objectif: 15,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez le mot",
        afficherEnMajuscules: false,
        nomElements: "Mots saisis",
        uniteVitesse: "mots par minute"
    )

    static let motsLongs = ConfigurationNiveauDefiEclair(
        numero: 5,
        titre: "Les mots longs",
        presentation: "Tapez 20 mots courants de six à neuf lettres présentés dans un ordre aléatoire.",
        elementsDisponibles: [
            "affiche", "armoire", "balcon", "basket", "batterie",
            "branche", "brique", "brioche", "caisse", "cartable",
            "cascade", "cerise", "cerisier", "chariot", "chemin",
            "cheval", "coffre", "colline", "couloir", "coussin",
            "costume", "cravate", "cuisine", "diamant", "facteur",
            "falaise", "fauteuil", "fermier", "ficelle", "flacon",
            "flamme", "flocon", "fraise", "grappe", "grenier",
            "grotte", "lavabo", "limace", "machine", "miroir",
            "montagne", "moustache", "navire", "noisette", "oiseau",
            "peluche", "pendule", "peinture", "pinceau", "placard",
            "poussin", "prairie", "racine", "rideau", "rivage",
            "rocher", "salade", "tablette", "toiture", "tornade",
            "tracteur", "tunnel", "village"
        ],
        nombreElements: 20,
        objectif: 15,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez le mot",
        afficherEnMajuscules: false,
        nomElements: "Mots saisis",
        uniteVitesse: "mots par minute"
    )

    static let motsAvecMajuscule = ConfigurationNiveauDefiEclair(
        numero: 6,
        titre: "Les mots avec une majuscule",
        presentation: "Tapez 20 mots présentés dans un ordre aléatoire. La première lettre de chaque mot doit être saisie en majuscule.",
        elementsDisponibles: [
            "Alice", "Arthur", "Bruno", "Camille", "Clara", "Damien",
            "Emma", "Hugo", "Jade", "Julie", "Julien", "Lucas",
            "Lucie", "Marie", "Martin", "Maxime", "Nina", "Paul",
            "Pierre", "Sophie", "Tanguy", "Thomas", "Valentin", "Victor",
            "Paris", "Nantes", "Toulon", "Dijon", "Lille", "Brest",
            "Nancy", "Colmar", "Cannes", "France", "Europe", "Canada",
            "Japon", "Italie", "Espagne", "Portugal", "Belgique", "Ukraine",
            "Irlande", "Croatie", "Finlande", "Pologne", "Tunisie", "Turquie",
            "Maroc", "Suisse"
        ],
        nombreElements: 20,
        objectif: 15,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez le mot",
        afficherEnMajuscules: false,
        nomElements: "Mots saisis",
        uniteVitesse: "mots par minute"
    )

    static let motsAccentes = ConfigurationNiveauDefiEclair(
        numero: 7,
        titre: "Les mots accentués",
        presentation: "Tapez 20 mots accentués présentés dans un ordre aléatoire. Tous les éléments sont en minuscules, y compris les prénoms.",
        elementsDisponibles: [
            "aurélien", "élodie", "éléphant", "guépard", "école",
            "élève", "étoile", "équipe", "épice", "écran",
            "église", "éponge", "écharpe", "écureuil", "fusée",
            "poupée", "cheminée", "téléphone", "télévision", "café",
            "canapé", "musée", "frère", "rivière", "lumière",
            "chèvre", "zèbre", "règle", "planète", "collège",
            "déjà", "voilà", "garçon", "leçon", "français",
            "façade", "glaçon", "reçu", "château", "gâteau",
            "fenêtre", "tête", "rêve", "même", "tempête",
            "hôpital", "drôle", "diplôme", "fantôme", "goût",
            "noël", "maïs", "naïf", "canoë", "héroïne",
            "mosaïque", "laïque", "astéroïde"
        ],
        nombreElements: 20,
        objectif: 15,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez le mot",
        afficherEnMajuscules: false,
        nomElements: "Mots saisis",
        uniteVitesse: "mots par minute"
    )

    static let groupesDeuxMots = ConfigurationNiveauDefiEclair(
        numero: 8,
        titre: "Les groupes de deux mots",
        presentation: "Tapez 20 groupes de deux mots présentés dans un ordre aléatoire. Un espace doit séparer les deux mots.",
        elementsDisponibles: [
            "chat noir", "chien blanc", "lion calme", "tigre rapide",
            "panda joueur", "lapin brun", "cheval rapide", "renard malin",
            "pomme rouge", "poire verte", "citron jaune", "raisin noir",
            "melon rond", "prune noire", "grand arbre", "petit bateau",
            "vieux livre", "jeune chat", "belle plage", "vaste monde",
            "long chemin", "large route", "porte rouge", "table ronde",
            "lampe verte", "robe noire", "veste blanche", "ballon jaune",
            "jardin calme", "maison blanche", "ciel bleu", "soleil chaud",
            "vent doux", "pluie fine", "nuit noire", "matin calme",
            "soir tranquille", "pain chaud", "soupe chaude", "jus frais",
            "chocolat noir", "sucre blanc", "fromage frais", "train rapide",
            "avion blanc", "camion rouge", "taxi jaune", "wagon bleu",
            "route droite", "pont solide", "parc ouvert", "film court",
            "musique douce", "histoire courte", "phrase simple", "mot secret",
            "jeu rapide", "livre ouvert", "stylo noir", "cahier blanc"
        ],
        nombreElements: 20,
        objectif: 15,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez le groupe de mots",
        afficherEnMajuscules: false,
        nomElements: "Groupes saisis",
        uniteVitesse: "groupes par minute"
    )

    static let ponctuation = ConfigurationNiveauDefiEclair(
        numero: 9,
        titre: "La ponctuation",
        presentation: "Tapez 20 mots ou courtes expressions comportant chacun un seul signe de ponctuation. Avec VoiceOver, chaque espace et le signe à saisir seront annoncés.",
        elementsDisponibles: [
            "bonjour.", "merci.", "demain.", "terminé.", "possible.",
            "silence.", "bravo !", "vite !", "attention !", "stop !",
            "parfait !", "gagné !", "pourquoi ?", "encore ?", "possible ?",
            "vraiment ?", "comment ?", "demain ?", "oui, merci",
            "non, merci", "chat, chien", "rouge, bleu", "pomme, poire",
            "sel, poivre", "un, deux", "jour, nuit", "pain, beurre",
            "pluie, vent", "animal : chat", "fruit : pomme",
            "objet : lampe", "couleur : rouge", "nombre : trois",
            "lieu : parc", "jeu : ballon", "choix : oui", "heure : midi",
            "forme : cercle", "jour ; nuit", "vite ; bien", "chat ; chien",
            "rouge ; bleu", "pomme ; poire", "pluie ; soleil",
            "matin ; soir", "gauche ; droite", "chaud ; froid",
            "petit ; grand", "l'arbre", "l'avion", "l'image", "l'orange",
            "d'accord", "aujourd'hui", "quelqu'un", "c'est vrai",
            "j'arrive", "cerf-volant", "peut-être", "grand-mère",
            "grand-père", "porte-clés", "après-midi", "rendez-vous",
            "bien-être", "week-end", "demi-tour"
        ],
        nombreElements: 20,
        objectif: 15,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez le texte avec sa ponctuation",
        afficherEnMajuscules: false,
        nomElements: "Éléments saisis",
        uniteVitesse: "éléments par minute"
    )

    private static let categoriesGrandMelange: [[String]] = [
        [
            "abricot", "boussole", "cabane", "carton", "dauphin",
            "domino", "girafe", "journal", "licorne", "valise",
            "navire", "peluche", "pirate", "robot", "tunnel"
        ],
        [
            "Alice", "Arthur", "Aurélien", "Canada", "Damien",
            "Élodie", "France", "Hugo", "Japon", "Julie",
            "Nantes", "Paris", "Sophie", "Tours", "Victor"
        ],
        [
            "éléphant", "guépard", "héroïne", "château", "fenêtre",
            "français", "téléphone", "maïs", "façade", "gâteau",
            "écureuil", "mosaïque", "collège", "rivière", "tempête"
        ],
        [
            "chat noir", "ciel bleu", "pomme rouge", "train rapide",
            "maison blanche", "livre ouvert", "soleil chaud",
            "jardin calme", "chien blanc", "table ronde", "vent doux",
            "pluie fine", "ballon jaune", "route droite", "film court"
        ],
        [
            "bonjour.", "bravo !", "pourquoi ?", "oui, merci",
            "animal : chat", "jour ; nuit", "l'arbre", "peut-être",
            "grand-mère", "rendez-vous", "merci.", "encore ?",
            "stop !", "sel, poivre", "objet : lampe"
        ]
    ]

    static let grandMelange = ConfigurationNiveauDefiEclair(
        numero: 10,
        titre: "Le grand mélange",
        presentation: "Tapez 20 éléments mélangeant toutes les difficultés des niveaux précédents. Chaque partie contient quatre mots simples, quatre mots avec une majuscule, quatre mots accentués, quatre groupes de deux mots et quatre éléments avec un seul signe de ponctuation. Avec VoiceOver, les espaces, les signes de ponctuation et les majuscules nécessaires seront annoncés. Sauf indication contraire, saisissez les lettres en minuscules.",
        elementsDisponibles: categoriesGrandMelange.flatMap { $0 },
        nombreElements: 20,
        objectif: 15,
        duree: 60,
        prefixeAnnonce: "",
        inviteSaisie: "Tapez l'élément demandé",
        afficherEnMajuscules: false,
        nomElements: "Éléments saisis",
        uniteVitesse: "éléments par minute"
    )

    var respecterLaCasse: Bool {
        numero == 6 || numero == 10
    }

    func texteAffiche(_ element: String) -> String {
        afficherEnMajuscules ? element.uppercased() : element
    }

    func texteAnnonce(_ element: String) -> String {
        if numero == 9 {
            return texteDicteAvecPonctuation(element)
        }

        if numero == 10 {
            let annonce = texteDicteAvecPonctuation(element)

            if let premiereLettre = element.first,
               premiereLettre.isUppercase {
                return "\(premiereLettre) majuscule. \(annonce)"
            }

            return annonce
        }

        guard !prefixeAnnonce.isEmpty else {
            return element
        }

        return "\(prefixeAnnonce) \(element)"
    }

    func texteErreurAccessible(_ texte: String) -> String {
        guard numero == 9 || numero == 10 else {
            return texte
        }

        return texteDicteAvecPonctuation(texte)
    }

    func elementsPourPartie() -> [String] {
        if numero == 10 {
            return Self.categoriesGrandMelange
                .flatMap { categorie in
                    Array(categorie.shuffled().prefix(4))
                }
                .shuffled()
        }

        return Array(
            elementsDisponibles
                .shuffled()
                .prefix(nombreElements)
        )
    }

    private func texteDicteAvecPonctuation(_ element: String) -> String {
        var morceaux: [String] = []
        var texteCourant = ""

        func ajouterTexteCourant() {
            guard !texteCourant.isEmpty else { return }
            morceaux.append(texteCourant)
            texteCourant = ""
        }

        for caractere in element {
            switch caractere {
            case " ":
                ajouterTexteCourant()
                morceaux.append("espace")
            case ".":
                ajouterTexteCourant()
                morceaux.append("point")
            case ",":
                ajouterTexteCourant()
                morceaux.append("virgule")
            case "!":
                ajouterTexteCourant()
                morceaux.append("point d'exclamation")
            case "?":
                ajouterTexteCourant()
                morceaux.append("point d'interrogation")
            case ":":
                ajouterTexteCourant()
                morceaux.append("deux-points")
            case ";":
                ajouterTexteCourant()
                morceaux.append("point-virgule")
            case "'":
                ajouterTexteCourant()
                morceaux.append("apostrophe")
            case "-":
                ajouterTexteCourant()
                morceaux.append("trait d'union")
            default:
                texteCourant.append(caractere)
            }
        }

        ajouterTexteCourant()
        return morceaux.joined(separator: ". ") + "."
    }
}

private struct ErreurDefiEclair: Identifiable {

    let id = UUID()
    let reponseAttendue: String
    let reponseSaisie: String
}

private struct NiveauSaisieDefiEclair: View {

    private enum Etape {
        case presentation
        case compteARebours
        case jeu
        case resultat
    }

    let configuration: ConfigurationNiveauDefiEclair
    let etatExerciceChange: (Bool) -> Void
    let retourNiveaux: () -> Void
    let niveauReussi: () -> Void

    @StateObject private var lecteur = LecteurVocalDefiEclair()

    @State private var etape: Etape = .presentation
    @State private var elements: [String] = []
    @State private var index = 0
    @State private var saisie = ""
    @State private var bonnesReponses = 0
    @State private var erreurs = 0
    @State private var detailsErreurs: [ErreurDefiEclair] = []
    @State private var secondesRestantes = 60
    @State private var compteARebours = 3
    @State private var chronometreActif = false
    @State private var generation = 0
    @State private var premierElement = true
    @State private var finEnCours = false
    @State private var debutPeriodeSaisie: Date?
    @State private var tempsSaisieCumule: TimeInterval = 0
    @State private var textesCorrects: [String] = []

    @FocusState private var champEnFocus: Bool
    @AccessibilityFocusState private var titreEnFocus: Bool

    var body: some View {
        VStack(spacing: 24) {
            switch etape {
            case .presentation:
                presentation
            case .compteARebours, .jeu:
                zoneJeuEtCompteARebours
            case .resultat:
                resultat
            }
        }
        .padding(40)
        .frame(minWidth: 760, minHeight: 560)
        .background(
            CaptureCommandeDefiEclair(
                actif: etape == .jeu
                    && chronometreActif
                    && NSWorkspace.shared.isVoiceOverEnabled,
                action: repeterElement
            )
            .frame(width: 0, height: 0)
        )
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { _ in
            guard etape == .jeu, chronometreActif else { return }
            if secondesRestantes > 1 {
                secondesRestantes -= 1
            } else {
                secondesRestantes = 0
                terminerNiveau()
            }
        }
        .onDisappear {
            etatExerciceChange(false)
            generation += 1
            lecteur.arreter()
        }

    }

    private var presentation: some View {
        VStack(spacing: 22) {
            Text("Niveau \(configuration.numero) — \(configuration.titre)")
                .font(.largeTitle)
                .bold()
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titreEnFocus)

            Text(configuration.presentation)
                .font(.title2)
                .multilineTextAlignment(.center)

            Text("Objectif : obtenir au moins \(configuration.objectif) bonnes réponses. Vous disposez de \(configuration.duree) secondes.")
                .font(.title3)
                .bold()

            Button("Commencer le niveau") {
                lancerCompteARebours()
            }
            .keyboardShortcut(.defaultAction)

            Button("Retour aux niveaux") {
                retourNiveaux()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                titreEnFocus = true
            }
        }
    }

    private var jeu: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Temps : \(secondesRestantes) secondes")
                Spacer()
                Text("Réponses : \(index) sur \(elements.count)")
            }
            .font(.headline)
            .accessibilityHidden(true)

            Text(configuration.texteAffiche(elementCourant))
                .font(
                    .system(
                        size: configuration.afficherEnMajuscules ? 150 : 74,
                        weight: .black,
                        design: .rounded
                    )
                )
                .minimumScaleFactor(0.5)
                .accessibilityHidden(true)

            if NSWorkspace.shared.isVoiceOverEnabled {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(nsColor: .textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.secondary.opacity(0.45))
                        )

                    Text(saisie.isEmpty ? configuration.inviteSaisie : saisie)
                        .font(.system(size: 32))
                        .foregroundStyle(
                            saisie.isEmpty ? Color.secondary : Color.primary
                        )

                    CaptureClavierSilencieuse(
                        active:
                            etape == .jeu
                            && chronometreActif
                            && !lecteur.estEnTrainDeLire,
                        caractereSaisi: { caractere in
                            traiterSaisie(caractere)
                        },
                        entreePressee: {
                            // La réécoute utilise Commande seule, pas Entrée.
                        }
                    )
                }
                .frame(width: 360, height: 48)
                .accessibilityHidden(true)
            } else {
                TextField(configuration.inviteSaisie, text: $saisie)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 32))
                    .frame(maxWidth: 360)
                    .focused($champEnFocus)
                    .disabled(lecteur.estEnTrainDeLire)
                    .onChange(of: saisie) { nouvelleValeur in
                        traiterSaisie(nouvelleValeur)
                }
            }
        }
        .accessibilityHidden(NSWorkspace.shared.isVoiceOverEnabled)
    }

    private var zoneJeuEtCompteARebours: some View {
        ZStack {
            jeu
                .opacity(etape == .jeu ? 1 : 0)

            // Cet élément reste présent après le décompte. Il devient
            // simplement invisible, ce qui évite à VoiceOver de chercher
            // un nouveau conteneur et d'annoncer « groupe ».
            Text("\(max(compteARebours, 1))")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .opacity(etape == .compteARebours ? 1 : 0)
                .accessibilityLabel("\(max(compteARebours, 1))")
        }
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

                Text("Bonnes réponses : \(bonnesReponses). Erreurs : \(erreurs).")
                    .font(.title3)

                Text("\(configuration.nomElements) : \(nombreReponses). Temps de saisie : \(tempsDeSaisie) secondes.")
                    .font(.title3)

                Text("Précision : \(precision) pour cent. Vitesse : \(vitesse) \(configuration.uniteVitesse).")
                    .font(.title3)

                if !detailsErreurs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Détail des erreurs")
                            .font(.headline)

                        ForEach(
                            Array(detailsErreurs.enumerated()),
                            id: \.element.id
                        ) { index, erreur in
                            Text(
                                "Erreur \(index + 1). Réponse attendue : \(erreur.reponseAttendue). Réponse saisie : \(erreur.reponseSaisie)."
                            )
                            .font(.title3)
                            .accessibilityLabel(
                                "Erreur \(index + 1). Réponse attendue : \(texteAccessiblePourErreur(erreur.reponseAttendue)). Réponse saisie : \(texteAccessiblePourErreur(erreur.reponseSaisie))."
                            )
                        }
                    }
                }

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

    private func texteAccessiblePourErreur(_ texte: String) -> String {
        switch texte {
        case "Y", "y":
            return "i grec"
        default:
            return texte
        }
    }

    private var elementCourant: String {
        guard elements.indices.contains(index) else { return "" }
        return elements[index]
    }

    private var messageResultat: String {
        if bonnesReponses >= configuration.objectif {
            if configuration.numero == 10 {
                return "Bravo, vous avez terminé tous les niveaux du Défi éclair !"
            }

            return "Bravo ! Objectif atteint. Le niveau \(configuration.numero + 1) est déverrouillé."
        }
        return "Objectif non atteint. Il fallait obtenir au moins \(configuration.objectif) bonnes réponses. Vous pouvez recommencer quand vous le souhaitez."
    }

    private var nombreReponses: Int {
        bonnesReponses + erreurs
    }

    private var tempsDeSaisie: Int {
        var temps = tempsSaisieCumule

        if let debutPeriodeSaisie {
            temps += Date().timeIntervalSince(debutPeriodeSaisie)
        }

        return max(1, Int(temps.rounded(.up)))
    }

    private var precision: Int {
        guard nombreReponses > 0 else { return 0 }
        return Int(
            (Double(bonnesReponses) / Double(nombreReponses) * 100)
                .rounded()
        )
    }

    private var vitesse: Int {
        guard nombreReponses > 0 else { return 0 }
        return Int(
            (Double(nombreReponses) / Double(tempsDeSaisie) * 60)
                .rounded()
        )
    }

    private func lancerCompteARebours() {
        etatExerciceChange(true)
        generation += 1
        lecteur.arreter()
        elements = configuration.elementsPourPartie()
        index = 0
        saisie = ""
        bonnesReponses = 0
        erreurs = 0
        detailsErreurs = []
        secondesRestantes = configuration.duree
        compteARebours = 3
        chronometreActif = false
        premierElement = true
        finEnCours = false
        debutPeriodeSaisie = nil
        tempsSaisieCumule = 0
        textesCorrects = []
        etape = .compteARebours

        let generationDemandee = generation
        faireCompteARebours(generationDemandee)
    }

    private func faireCompteARebours(_ generationDemandee: Int) {
        guard generation == generationDemandee else { return }

        if compteARebours > 0 {
            VoiceOverAnnouncer.annoncerTexte("\(compteARebours)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                compteARebours -= 1
                faireCompteARebours(generationDemandee)
            }
        } else {
            etape = .jeu
            presenterElementAutomatiquement()
        }
    }

    private func presenterElementAutomatiquement() {
        guard etape == .jeu, !elementCourant.isEmpty else { return }

        saisie = ""

        if NSWorkspace.shared.isVoiceOverEnabled {
            suspendreChronometre()
            champEnFocus = false

            let indexAttendu = index
            let delaiAvantLecture: TimeInterval =
                premierElement ? 1.4 : 0.55

            premierElement = false

            DispatchQueue.main.asyncAfter(
                deadline: .now() + delaiAvantLecture
            ) {
                guard etape == .jeu,
                      index == indexAttendu else {
                    return
                }

                lecteur.lire(configuration.texteAnnonce(elementCourant)) {
                    guard etape == .jeu else { return }
                    demarrerChronometre()
                    champEnFocus = true
                }
            }
        } else {
            demarrerChronometre()
            champEnFocus = true
        }
    }

    private func repeterElement() {
        guard NSWorkspace.shared.isVoiceOverEnabled,
              etape == .jeu, !elementCourant.isEmpty else { return }

        // La répétition volontaire ne suspend pas le chronomètre.
        champEnFocus = false
        lecteur.lire(configuration.texteAnnonce(elementCourant)) {
            guard etape == .jeu else { return }
            champEnFocus = true
        }
    }

    private func traiterSaisie(_ nouvelleValeur: String) {
        guard etape == .jeu,
              !lecteur.estEnTrainDeLire,
              !nouvelleValeur.isEmpty else {
            return
        }

        let texteCandidat: String

        if NSWorkspace.shared.isVoiceOverEnabled {
            texteCandidat = saisie + nouvelleValeur
            saisie = texteCandidat
        } else {
            texteCandidat = nouvelleValeur
        }

        let longueurAttendue = elementCourant.count

        guard texteCandidat.count >= longueurAttendue else {
            return
        }

        let reponse = String(
            texteCandidat.prefix(longueurAttendue)
        )

        let reponseCorrecte: Bool

        if configuration.respecterLaCasse {
            reponseCorrecte =
                reponse == configuration.texteAffiche(elementCourant)
        } else {
            reponseCorrecte =
                reponse.lowercased() == elementCourant.lowercased()
        }

        if reponseCorrecte {
            bonnesReponses += 1
            textesCorrects.append(configuration.texteAffiche(elementCourant))
        } else {
            erreurs += 1
            detailsErreurs.append(
                ErreurDefiEclair(
                    reponseAttendue:
                        configuration.texteAffiche(elementCourant),
                    reponseSaisie: String(
                        texteCandidat.prefix(longueurAttendue)
                    )
                )
            )
        }

        index += 1
        saisie = ""

        if index >= elements.count {
            terminerNiveau()
        } else {
            presenterElementAutomatiquement()
        }
    }

    private func terminerNiveau() {
        guard etape == .jeu, !finEnCours else { return }

        finEnCours = true
        suspendreChronometre()
        let reussi = bonnesReponses >= configuration.objectif
        ProgressionManager.shared.enregistrerPartie(
            jeu: .defiEclair,
            niveau: configuration.numero,
            reussie: reussi,
            motsCorrects: textesCorrects.reduce(0) { $0 + ProgressionManager.nombreDeMots(dans: $1) },
            erreursDeFrappe: erreurs,
            caracteresValides: textesCorrects.reduce(0) { $0 + $1.count },
            dureeSaisie: tempsSaisieCumule
        )
        lecteur.arreter()
        champEnFocus = false

        // Laisse VoiceOver terminer l'écho de la dernière frappe avant
        // l'apparition et la lecture de la fiche de résultat.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard finEnCours else { return }

            etatExerciceChange(false)

            etape = .resultat
            titreEnFocus = false

            // Même logique que les fiches finales de Dictée audio :
            // une fois la vue résultat affichée, VoiceOver revient sur le titre,
            // et le bloc combiné est lu comme un seul résultat.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard etape == .resultat else { return }
                titreEnFocus = true
            }

            if bonnesReponses >= configuration.objectif {
                niveauReussi()
            }

        }
    }

    private func demarrerChronometre() {
        if debutPeriodeSaisie == nil {
            debutPeriodeSaisie = Date()
        }
        chronometreActif = true
    }

    private func suspendreChronometre() {
        if let debutPeriodeSaisie {
            tempsSaisieCumule +=
                Date().timeIntervalSince(debutPeriodeSaisie)
        }

        debutPeriodeSaisie = nil
        chronometreActif = false
    }
}

private struct CaptureCommandeDefiEclair: NSViewRepresentable {

    let actif: Bool
    let action: () -> Void

    func makeNSView(context: Context) -> NSView {
        context.coordinator.mettreAJour(actif: actif, action: action)
        context.coordinator.installerMoniteur()
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.mettreAJour(actif: actif, action: action)
    }

    func makeCoordinator() -> Coordinateur {
        Coordinateur()
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinateur) {
        coordinator.retirerMoniteur()
    }

    final class Coordinateur {
        private var moniteur: Any?
        private var actif = false
        private var action: (() -> Void)?
        private var commandeCandidate = false
        private var combinaisonEnCours = false

        func mettreAJour(actif: Bool, action: @escaping () -> Void) {
            self.actif = actif
            self.action = action
            if !actif {
                commandeCandidate = false
                combinaisonEnCours = false
            }
        }

        func installerMoniteur() {
            guard moniteur == nil else { return }
            moniteur = NSEvent.addLocalMonitorForEvents(
                matching: [.flagsChanged, .keyDown]
            ) {
                [weak self] evenement in
                guard let self else { return evenement }

                guard actif, NSWorkspace.shared.isVoiceOverEnabled else {
                    commandeCandidate = false
                    combinaisonEnCours = false
                    return evenement
                }

                if evenement.type == .keyDown {
                    if commandeCandidate {
                        commandeCandidate = false
                        combinaisonEnCours = true
                    }
                    return evenement
                }

                let drapeaux = evenement.modifierFlags
                    .intersection(.deviceIndependentFlagsMask)
                    .intersection([.command, .control, .option, .shift])

                if drapeaux == [.command] {
                    if !combinaisonEnCours {
                        commandeCandidate = true
                    }
                } else if drapeaux.isEmpty {
                    let appuiCommandeSeule =
                        commandeCandidate && !combinaisonEnCours
                    commandeCandidate = false
                    combinaisonEnCours = false

                    if appuiCommandeSeule {
                        DispatchQueue.main.async { [weak self] in
                            self?.action?()
                        }
                    }
                } else {
                    commandeCandidate = false
                    combinaisonEnCours = true
                }

                return evenement
            }
        }

        func retirerMoniteur() {
            if let moniteur {
                NSEvent.removeMonitor(moniteur)
                self.moniteur = nil
            }
        }

        deinit {
            retirerMoniteur()
        }
    }
}

private struct CaptureClavierSilencieuse: NSViewRepresentable {

    let active: Bool
    let caractereSaisi: (String) -> Void
    let entreePressee: () -> Void

    func makeNSView(context: Context) -> VueCaptureClavier {
        let vue = VueCaptureClavier()
        vue.caractereSaisi = caractereSaisi
        vue.entreePressee = entreePressee
        return vue
    }

    func updateNSView(
        _ vue: VueCaptureClavier,
        context: Context
    ) {
        vue.caractereSaisi = caractereSaisi
        vue.entreePressee = entreePressee

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

private final class VueCaptureClavier: NSView {

    var caractereSaisi: ((String) -> Void)?
    var entreePressee: (() -> Void)?

    // Les touches ^ et ¨ sont des touches mortes sur un clavier AZERTY.
    // La première frappe ne doit pas être interprétée comme une erreur.
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
        if event.keyCode == 36 || event.keyCode == 76 {
            diacritiqueEnAttente = nil
            entreePressee?()
            return
        }

        // Le Défi éclair n'autorise pas la correction d'une réponse en
        // cours : Retour arrière et Supprimer sont donc ignorées.
        if event.keyCode == 51 || event.keyCode == 117 {
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

        guard let premier = caracteres.first else {
            super.keyDown(with: event)
            return
        }

        var texte = String(premier)
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

        caractereSaisi?(texte)
    }
}

private struct CaptureEchapDefiEclair: NSViewRepresentable {

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

@MainActor
private final class LecteurVocalDefiEclair: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    @Published private(set) var estEnTrainDeLire = false

    private let synthetiseur = AVSpeechSynthesizer()
    private var finLecture: (() -> Void)?
    private var generationLecture = 0

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
        synthetiseur.speak(phrase)

        // Filet de sécurité : une anomalie de synthèse vocale ne doit
        // jamais laisser le niveau bloqué.
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            guard self.generationLecture == generationDemandee,
                  self.estEnTrainDeLire else {
                return
            }

            self.synthetiseur.stopSpeaking(at: .immediate)
            self.terminerLecture()
        }
    }

    func arreter() {
        generationLecture += 1
        finLecture = nil
        estEnTrainDeLire = false

        if synthetiseur.isSpeaking {
            synthetiseur.stopSpeaking(at: .immediate)
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            terminerLecture()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            terminerLecture()
        }
    }

    private func terminerLecture() {
        guard estEnTrainDeLire else { return }

        estEnTrainDeLire = false
        let completion = finLecture
        finLecture = nil
        completion?()
    }
}
